# encoding: utf-8

require 'spec_helper'

module Adhearsion
  module Translator
    class Asterisk
      module Component
        module Asterisk
          describe AGICommand do
            include HasMockCallbackConnection

            let(:channel)       { 'SIP/foo' }
            let(:ami_client)    { double('AMI Client').as_null_object }
            let(:translator)    { Translator::Asterisk.new ami_client, connection }
            let(:mock_call)     { Translator::Asterisk::Call.new channel, translator, ami_client, connection }
            let(:component_id)  { Adhearsion.new_uuid }

            before { stub_uuids component_id }

            let :original_command do
              Adhearsion::Rayo::Component::Asterisk::AGI::Command.new :name => 'EXEC ANSWER'
            end

            subject { AGICommand.new original_command, mock_call }

            let :response do
              RubyAMI::Response.new
            end

            context 'initial execution' do
              before { original_command.request! }

              it 'should send the appropriate action' do
                expect(ami_client).to receive(:send_action).once.with('AGI', 'Channel' => channel, 'Command' => 'EXEC ANSWER', 'CommandID' => component_id).and_return(response)
                subject.execute
              end

              context 'with some parameters' do
                let(:params) { [1000, 'foo'] }

                let :original_command do
                  Adhearsion::Rayo::Component::Asterisk::AGI::Command.new :name => 'WAIT FOR DIGIT', :params => params
                end

                it 'should send the appropriate action' do
                  expect(ami_client).to receive(:send_action).once.with('AGI', 'Channel' => channel, 'Command' => 'WAIT FOR DIGIT "1000" "foo"', 'CommandID' => component_id).and_return(response)
                  subject.execute
                end
              end
            end

            context 'when the AMI action completes' do
              before do
                original_command.request!
              end

              let :expected_response do
                Adhearsion::Rayo::Ref.new uri: component_id
              end

              let :response do
                RubyAMI::Response.new 'ActionID' => "552a9d9f-46d7-45d8-a257-06fe95f48d99",
                  'Message' => 'Added AGI original_command to queue'
              end

              it 'should send the component node a ref with the action ID' do
                expect(ami_client).to receive(:send_action).once.and_return response
                subject.execute
                expect(original_command.response(1)).to eq(expected_response)
              end

              context 'with an error' do
                let(:message) { 'Action failed' }
                let :response do
                  RubyAMI::Error.new.tap { |e| e.message = message }
                end

                before { expect(ami_client).to receive(:send_action).once.and_raise response }

                it 'should send the component node false' do
                  subject.execute
                  expect(original_command.response(1)).to be_falsey
                end

                context "which is 'No such channel'" do
                  let(:message) { 'No such channel' }

                  it "should return an :item_not_found error for the command" do
                    subject.execute
                    expect(original_command.response(0.5)).to eq(Adhearsion::ProtocolError.new.setup(:item_not_found, "Could not find a call with ID #{mock_call.id}", mock_call.id))
                  end
                end

                context "which is 'Channel SIP/nosuchchannel does not exist.'" do
                  let(:message) { 'Channel SIP/nosuchchannel does not exist.' }

                  it "should return an :item_not_found error for the command" do
                    subject.execute
                    expect(original_command.response(0.5)).to eq(Adhearsion::ProtocolError.new.setup(:item_not_found, "Could not find a call with ID #{mock_call.id}", mock_call.id))
                  end
                end
              end
            end

            describe 'when receiving an AsyncAGI event' do
              before do
                original_command.request!
                original_command.execute!
              end

              context 'of type start'

              context 'of type Exec' do
                let (:ami_event_result) { "200%20result=123%20(timeout)%0A" }
                let(:ami_event) do
                  RubyAMI::Event.new 'AsyncAGI',
                    "SubEvent"   => "Exec",
                    "Channel"    => channel,
                    "CommandId"  => component_id,
                    "Command"    => "EXEC ANSWER",
                    "Result"     => ami_event_result
                end

                let(:ami_event_ast13) do
                  RubyAMI::Event.new 'AsyncAGIExec',
                    "Channel"    => channel,
                    "CommandId"  => component_id,
                    "Command"    => "EXEC ANSWER",
                    "Result"     => ami_event_result
                  end

                let :expected_complete_reason do
                  Adhearsion::Rayo::Component::Asterisk::AGI::Command::Complete::Success.new :code    => 200,
                                                                                       :result  => 123,
                                                                                       :data    => 'timeout'
                end

                def should_send_complete_event
                  subject.handle_ami_event ami_event

                  complete_event = original_command.complete_event 0.5

                  expect(original_command).to be_complete

                  expect(complete_event.component_id).to eq(component_id.to_s)
                  expect(complete_event.reason).to eq(expected_complete_reason)
                end

                it 'should send a complete event' do
                  should_send_complete_event
                end

                context 'with an AsyncAGIExec event' do
                  let(:ami_event) { ami_event_ast13 }

                  it 'should send a complete event' do
                    should_send_complete_event
                  end
                end

                context 'when the result contains illegal characters in the AGI response' do
                  let (:ami_event_result) { '$' }
                  let :expected_complete_reason do
                    Adhearsion::Rayo::Component::Asterisk::AGI::Command::Complete::Success.new :code    => -1,
                                                                                         :result  => nil,
                                                                                         :data    => nil
                  end

                  def treat_as_failure
                    subject.handle_ami_event ami_event

                    complete_event = original_command.complete_event 0.5

                    expect(original_command).to be_complete

                    expect(complete_event.component_id).to eq(component_id.to_s)
                    expect(complete_event.reason).to eq(expected_complete_reason)
                  end

                  it 'treats it as a failure with code -1' do
                    treat_as_failure
                  end

                  context 'with an AsyncAGIExec event' do
                    let(:ami_event) { ami_event_ast13 }

                    it 'treats it as a failure with code -1' do
                      treat_as_failure
                    end
                  end
                end

                context "when the command was ASYNCAGI BREAK" do
                  let :original_command do
                    Adhearsion::Rayo::Component::Asterisk::AGI::Command.new :name => 'ASYNCAGI BREAK'
                  end

                  let(:chan_var) { nil }

                  before do
                    response = RubyAMI::Response.new 'Value' => chan_var
                    expect(ami_client).to receive(:send_action).once.with('GetVar', 'Channel' => channel, 'Variable' => 'ADHEARSION_END_ON_ASYNCAGI_BREAK').and_return response
                  end

                  it 'should not send an end (hangup) event to the translator' do
                    expect(translator).to receive(:handle_pb_event).once.with kind_of(Adhearsion::Event::Complete)
                    expect(translator).to receive(:handle_pb_event).never.with kind_of(Adhearsion::Event::End)
                    subject.handle_ami_event ami_event
                  end

                  context "when the ADHEARSION_END_ON_ASYNCAGI_BREAK channel var is set" do
                    let(:chan_var) { 'true' }

                    it 'should send an end (hungup) event to the translator' do
                      expected_end_event = Adhearsion::Event::End.new reason: :hungup,
                                                                      platform_code: 16,
                                                                      target_call_id: mock_call.id

                      expect(translator).to receive(:handle_pb_event).once.with kind_of(Adhearsion::Event::Complete)
                      expect(translator).to receive(:handle_pb_event).once.with expected_end_event
                      subject.handle_ami_event ami_event
                    end

                    context "when the AMI event has a timestamp" do
                      let :ami_event do
                        RubyAMI::Event.new 'AsyncAGI',
                          "SubEvent"   => "Exec",
                          "Channel"    => channel,
                          "CommandId"  => component_id,
                          "Command"    => "EXEC ANSWER",
                          "Result"     => "200%20result=123%20(timeout)%0A",
                          'Timestamp'  => '1393368380.572575'
                      end

                      it "should use the AMI timestamp for the Rayo event" do
                        expected_end_event = Adhearsion::Event::End.new reason: :hungup,
                                                                        platform_code: 16,
                                                                        target_call_id: mock_call.id,
                                                                        timestamp: DateTime.new(2014, 2, 25, 22, 46, 20)
                        expect(translator).to receive(:handle_pb_event).once.with kind_of(Adhearsion::Event::Complete)
                        expect(translator).to receive(:handle_pb_event).once.with expected_end_event

                        subject.handle_ami_event ami_event
                      end
                    end
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end
