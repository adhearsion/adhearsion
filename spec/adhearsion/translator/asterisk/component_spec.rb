# encoding: utf-8

require 'spec_helper'

module Adhearsion
  module Translator
    class Asterisk
      describe Component do

      end

      module Component
        describe Component do
          let(:connection)  { Adhearsion::Rayo::Connection::Asterisk.new }
          let(:translator)  { connection.translator }
          let(:ami_client)  { connection.ami_client }
          let(:call)        { Translator::Asterisk::Call.new 'foo', translator, ami_client, connection }
          let(:command)     { Adhearsion::Rayo::Component::Input.new }

          subject { Component.new command, call }

          before { command.request! }

          describe "#send_event" do
            before { command.execute! }

            let :event do
              Adhearsion::Event::Complete.new
            end

            let :expected_event do
              Adhearsion::Event::Complete.new target_call_id: call.id,
                component_id: subject.id, source_uri: subject.id
            end

            it "should send the event to the connection" do
              expect(connection).to receive(:handle_event).once.with expected_event
              subject.send_event event
            end
          end

          describe "#send_complete_event" do
            before { command.execute! }

            let(:reason) { Adhearsion::Event::Complete::Stop.new }
            let :expected_event do
              Adhearsion::Event::Complete.new reason: reason
            end

            it "should send a complete event with the specified reason" do
              expect(subject).to receive(:send_event).once.with expected_event
              subject.send_complete_event reason
            end
          end

          describe "#call_ended" do
            it "should send a complete event with the call hangup reason" do
              expect(subject).to receive(:send_complete_event).once.with Adhearsion::Event::Complete::Hangup.new
              subject.call_ended
            end

            it "should deregister component from translator" do
              translator.register_component(subject)
              expect(translator.component_with_id(subject.id)).not_to be nil
              expect(translator).to receive(:handle_pb_event).once
              subject.call_ended
              expect(translator.component_with_id(subject.id)).to be nil
            end

          end

          describe '#execute_command' do
            before do
              component_command.request!
            end

            context 'with a command we do not understand' do
              let :component_command do
                Adhearsion::Rayo::Component::Stop.new :component_id => subject.id
              end

              it 'sends an error in response to the command' do
                subject.execute_command component_command
                expect(component_command.response).to eq(Adhearsion::ProtocolError.new.setup('command-not-acceptable', "Did not understand command for component #{subject.id}", call.id, subject.id))
              end
            end
          end
        end
      end
    end
  end
end
