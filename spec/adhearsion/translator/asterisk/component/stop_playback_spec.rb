# encoding: utf-8

require 'spec_helper'

module Adhearsion
  module Translator
    class Asterisk
      module Component
        describe StopPlayback do

          class MockComponent < Component
            include StopPlayback
            def set_complete
              @complete = true
            end
          end

          let(:connection)  { double 'Connection' }
          let(:ami_client)  { double('AMI Client').as_null_object }
          let(:translator)  { Translator::Asterisk.new ami_client, connection }
          let(:mock_call)   { Call.new 'SIP/foo', translator, ami_client, connection }

          subject { MockComponent.new Hash.new, mock_call }

          describe "#execute_command" do
            context "with a command it does not understand" do
              let(:command) { Adhearsion::Rayo::Component::Output::Pause.new }

              before { command.request! }
              it "returns a Adhearsion::ProtocolError response" do
                subject.execute_command command
                expect(command.response(0.1)).to be_a Adhearsion::ProtocolError
              end
            end

            context "with a Stop command" do
              let(:command) { Adhearsion::Rayo::Component::Stop.new }

              before do
                command.request!
              end

              it "sets the command response to true" do
                expect(mock_call).to receive(:redirect_back)
                expect(mock_call).to receive(:register_handler).once.with(:ami, [{:name => 'AsyncAGI', [:[], 'SubEvent']=>'Start'}, {:name => 'AsyncAGIStart'}])

                subject.execute_command command
                expect(command.response(0.1)).to eq(true)
              end

              it "returns an error if the component is already complete" do
                subject.set_complete
                subject.execute_command command
                expect(command.response(0.1)).to be_a Adhearsion::ProtocolError
              end

              context "in AMI 2.0 or greater" do
                [ '2.0', '2.0.1', '3.0' ].each do |version|
                  before do
                    allow(ami_client).to receive(:version) { version }
                    allow(translator).to receive :handle_pb_event
                  end
                end

                it 'stops playback by executing a ControlPlayback action' do
                  expect(ami_client).to receive(:send_action).once.with('ControlPlayback',
                    'Control' => 'stop',
                    'Channel' => 'SIP/foo'
                  )
                  subject.execute_command command
                end
              end

              context "in AMI < 2.0" do
                before do
                  allow(ami_client).to receive(:version) { '1.4' }
                end

                it 'stops playback through redirection' do
                  expect(ami_client).to receive(:send_action).once.with('Redirect', hash_including('Channel' => 'SIP/foo'))
                  subject.execute_command command
                end
              end
            end
          end
        end
      end
    end
  end
end
