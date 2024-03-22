# encoding: utf-8

require 'spec_helper'

module Adhearsion
  module Translator
    class Asterisk
      module Component
        module Asterisk
          describe AMIAction do
            include HasMockCallbackConnection

            let(:ami_client)      { double('AMI Client').as_null_object }
            let(:mock_translator) { Translator::Asterisk.new ami_client, connection }

            let :original_command do
              Adhearsion::Rayo::Component::Asterisk::AMI::Action.new :name => 'ExtensionStatus', :params => { :context => 'default', :exten => 'idonno' }
            end

            before do
              original_command.request!
            end

            subject { AMIAction.new original_command, mock_translator, ami_client }

            context 'initial execution' do
              let(:component_id) { Adhearsion.new_uuid }

              let :expected_response do
                Adhearsion::Rayo::Ref.new uri: component_id
              end

              before { stub_uuids component_id }

              it 'should send the appropriate RubyAMI::Action and send the component node a ref' do
                expect(ami_client).to receive(:send_action).once.with(
                  'ExtensionStatus',
                  Hash(
                    'Context' => 'default',
                    'Exten' => 'idonno'
                  )
                ).and_return(RubyAMI::Response.new)
                subject.execute
                expect(original_command.response(1)).to eq(expected_response)
              end
            end

            context 'when the AMI action completes' do
              let :response do
                RubyAMI::Response.new 'ActionID'  => '552a9d9f-46d7-45d8-a257-06fe95f48d99',
                                      'Message'   => 'Channel status will follow',
                                      'Exten'     => 'idonno',
                                      'Context'   => 'default',
                                      'Hint'      => '',
                                      'Status'    => '-1'
              end

              before { response.text_body = 'Some text body' }

              let :expected_complete_reason do
                Adhearsion::Rayo::Component::Asterisk::AMI::Action::Complete::Success.new message: 'Channel status will follow', text_body: 'Some text body', headers: {'Exten' => "idonno", 'Context' => "default", 'Hint' => "", 'Status' => "-1"}
              end

              context 'for a non-causal action' do
                it 'should send a complete event to the component node' do
                  expect(ami_client).to receive(:send_action).once.and_return response
                  expect(subject).to receive(:send_complete_event).once.with expected_complete_reason
                  subject.execute
                end
              end

              context 'for a causal action' do
                let :original_command do
                  Adhearsion::Rayo::Component::Asterisk::AMI::Action.new :name => 'CoreShowChannels'
                end

                let :expected_action do
                  RubyAMI::Action.new 'CoreShowChannels'
                end

                let :event do
                  RubyAMI::Event.new 'CoreShowChannel', 'ActionID' => "552a9d9f-46d7-45d8-a257-06fe95f48d99",
                    'Channel'          => 'SIP/127.0.0.1-00000013',
                    'UniqueID'         => '1287686437.19',
                    'Context'          => 'adhearsion',
                    'Extension'        => '23432',
                    'Priority'         => '2',
                    'ChannelState'     => '6',
                    'ChannelStateDesc' => 'Up'
                end

                let :terminating_event do
                  RubyAMI::Event.new 'CoreShowChannelsComplete', 'EventList' => 'Complete',
                    'ListItems' => '3',
                    'ActionID' => 'umtLtvSg-RN5n-GEay-Z786-YdiaSLNXkcYN'
                end

                let :event_node do
                  Adhearsion::Event::Asterisk::AMI.new name: 'CoreShowChannel', component_id: subject.id, source_uri: subject.id, headers: {
                    'Channel'          => 'SIP/127.0.0.1-00000013',
                    'UniqueID'         => '1287686437.19',
                    'Context'          => 'adhearsion',
                    'Extension'        => '23432',
                    'Priority'         => '2',
                    'ChannelState'     => '6',
                    'ChannelStateDesc' => 'Up'
                  }
                end

                let :expected_complete_reason do
                  Adhearsion::Rayo::Component::Asterisk::AMI::Action::Complete::Success.new message: 'Channel status will follow', text_body: 'Some text body', headers: {'Exten' => "idonno", 'Context' => "default", 'Hint' => "", 'Status' => "-1", 'EventList' => 'Complete', 'ListItems' => '3'}
                end

                before { expect(ami_client).to receive(:send_action).once.and_return response }

                it 'should send events to the component node' do
                  event_node
                  original_command.register_handler :internal, Adhearsion::Event::Asterisk::AMI do |event|
                    @event = event
                  end
                  response.events << event << terminating_event
                  subject.execute
                  expect(@event).to eq(event_node)
                end

                it 'should send a complete event to the component node' do
                  response.events << event << terminating_event

                  subject.execute

                  expect(original_command.complete_event(0.5).reason).to eq(expected_complete_reason)
                end
              end

              context 'with an error' do
                let :error do
                  RubyAMI::Error.new.tap { |e| e.message = 'Action failed' }
                end

                let :expected_complete_reason do
                  Adhearsion::Event::Complete::Error.new details: 'Action failed'
                end

                it 'should send a complete event to the component node' do
                  expect(ami_client).to receive(:send_action).once.and_raise error
                  expected_complete_reason
                  subject.execute
                  expect(original_command.complete_event(0.5).reason).to eq(expected_complete_reason)
                end
              end
            end
          end
        end
      end
    end
  end
end
