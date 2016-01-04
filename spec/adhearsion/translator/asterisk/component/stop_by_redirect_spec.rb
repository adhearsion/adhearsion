# encoding: utf-8

require 'spec_helper'

module Adhearsion
  module Translator
    class Asterisk
      module Component
        describe StopByRedirect do

          class MockComponent < Component
            include StopByRedirect
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
            end
          end
        end
      end
    end
  end
end
