# encoding: utf-8

require 'spec_helper'
require 'ostruct'

module Adhearsion
  module Translator
    describe Asterisk do
      let(:ami_client)    { double 'RubyAMI::Client' }
      let(:connection)    { Adhearsion::Rayo::Connection::Asterisk.new }

      let(:translator) { Asterisk.new ami_client, connection }

      subject { translator }

      describe '#ami_client' do
        subject { super().ami_client }
        it { is_expected.to be ami_client }
      end

      describe '#connection' do
        subject { super().connection }
        it { is_expected.to be connection }
      end

      before do
        connection.event_handler = ->(*) {}
      end

      after { translator.terminate if translator.alive? }

      describe '#execute_command' do
        describe 'with a call command' do
          let(:command) { Adhearsion::Rayo::Command::Answer.new }
          let(:call_id) { 'abc123' }

          it 'executes the call command' do
            expect(subject.wrapped_object).to receive(:execute_call_command).with(satisfy { |c|
              expect(c).to be command
              expect(c.target_call_id).to eq(call_id)
            })
            subject.execute_command command, :call_id => call_id
          end
        end

        describe 'with a global component command' do
          let(:command)       { Adhearsion::Rayo::Component::Stop.new }
          let(:component_id)  { '123abc' }

          it 'executes the component command' do
            expect(subject.wrapped_object).to receive(:execute_component_command).with(satisfy { |c|
              expect(c).to be command
              expect(c.component_id).to eq(component_id)
            })
            subject.execute_command command, :component_id => component_id
          end
        end

        describe 'with a global command' do
          let(:command) { Adhearsion::Rayo::Command::Dial.new }

          it 'executes the command directly' do
            expect(subject.wrapped_object).to receive(:execute_global_command).with command
            subject.execute_command command
          end
        end
      end

      describe '#send_message' do
        let(:call_id) { 'abc123' }
        let(:body) { 'hello world' }
        let(:call) { Translator::Asterisk::Call.new 'SIP/foo', subject, ami_client, connection }

        before do
          allow(call).to receive(:id).and_return call_id
          subject.register_call call
        end

        it 'sends the command to the call for execution' do
          expect(call).to receive(:send_message).once.with body
          subject.send_message call_id, 'example.com', body, subject: 'stuff'
        end

        context "when the call doesn't exist" do
          it "should not crash the translator" do
            subject.send_message 'oops', 'example.com', body, subject: 'stuff'
            expect(subject).to be_alive
          end
        end
      end

      describe '#register_call' do
        let(:call_id) { 'abc123' }
        let(:channel) { 'SIP/foo' }
        let(:call)    { Translator::Asterisk::Call.new channel, subject, ami_client, connection }

        before do
          allow(call).to receive(:id).and_return call_id
          subject.register_call call
        end

        it 'should make the call accessible by ID' do
          expect(subject.call_with_id(call_id)).to be call
        end

        it 'should make the call accessible by channel' do
          expect(subject.call_for_channel(channel)).to be call
        end
      end

      describe '#deregister_call' do
        let(:call_id) { 'abc123' }
        let(:channel) { 'SIP/foo' }
        let(:call)    { Translator::Asterisk::Call.new channel, subject, ami_client, connection }

        before do
          allow(call).to receive(:id).and_return call_id
          subject.register_call call
        end

        it 'should make the call inaccessible by ID' do
          expect(subject.call_with_id(call_id)).to be call
          subject.deregister_call call_id, channel
          expect(subject.call_with_id(call_id)).to be_nil
        end

        it 'should make the call inaccessible by channel' do
          expect(subject.call_for_channel(channel)).to be call
          subject.deregister_call call_id, channel
          expect(subject.call_for_channel(channel)).to be_nil
        end
      end

      describe '#register_component' do
        let(:component_id) { 'abc123' }
        let(:component)    { double 'Asterisk::Component::Asterisk::AMIAction', :id => component_id }

        it 'should make the component accessible by ID' do
          subject.register_component component
          expect(subject.component_with_id(component_id)).to be component
        end
      end

      describe '#execute_call_command' do
        let(:call_id) { 'abc123' }
        let(:command) { Adhearsion::Rayo::Command::Answer.new target_call_id: call_id }

        context "with a known call ID" do
          let(:call) { Translator::Asterisk::Call.new 'SIP/foo', subject, ami_client, connection }

          before do
            command.request!
            allow(call).to receive(:id).and_return call_id
            subject.register_call call
          end

          it 'sends the command to the call for execution' do
            expect(call).to receive(:execute_command).once.with command
            subject.execute_call_command command
          end

          context 'when it raises' do
            before do
              expect(call).to receive(:execute_command).and_raise StandardError
            end

            let(:other_command) { Adhearsion::Rayo::Command::Answer.new target_call_id: call_id }

            it 'sends an error in response to the command' do
              subject.execute_call_command command
              expect(command.response(1)).to eq(Adhearsion::ProtocolError.new.setup(:error, "Unknown error executing command on call #{call_id}", call_id))
            end

            it 'fails to find the call for later commands' do
              subject.execute_call_command command

              expect(subject.call_with_id(call_id)).to be_nil

              other_command.request!
              subject.execute_call_command other_command
              expect(other_command.response).to eq(Adhearsion::ProtocolError.new.setup(:item_not_found, "Could not find a call with ID #{call_id}", call_id))
            end

            it 'triggers an exception event' do
              latch = CountDownLatch.new 1
              ex = lo = nil
              Events.exception do |e, l|
                ex, lo = e, l
                latch.countdown!
              end

              subject.execute_call_command command

              expect(latch.wait(1)).to be true
              expect(ex).to be_a StandardError
              expect(lo).to be subject.logger
            end
          end
        end

        let :end_error_event do
          Adhearsion::Event::End.new reason: :error, target_call_id: call_id
        end

        context "with an unknown call ID" do
          it 'sends an error in response to the command' do
            command.request!
            subject.execute_call_command command
            expect(command.response).to eq(Adhearsion::ProtocolError.new.setup(:item_not_found, "Could not find a call with ID #{call_id}", call_id, nil))
          end
        end
      end

      describe '#execute_component_command' do
        let(:call)            { Translator::Asterisk::Call.new 'SIP/foo', subject, ami_client, connection }
        let(:component_node)  { Adhearsion::Rayo::Component::Output.new }
        let(:component)       { Translator::Asterisk::Component::Output.new(component_node, call) }

        let(:command) { Adhearsion::Rayo::Component::Stop.new component_id: component.id }

        before do
          command.request!
        end

        context 'with a known component ID' do
          before do
            subject.register_component component
          end

          it 'sends the command to the component for execution' do
            expect(component).to receive(:execute_command).once.with command
            subject.execute_component_command command
          end
        end

        context "with an unknown component ID" do
          it 'sends an error in response to the command' do
            subject.execute_component_command command
            expect(command.response).to eq(Adhearsion::ProtocolError.new.setup(:item_not_found, "Could not find a component with ID #{component.id}", nil, component.id))
          end
        end
      end

      describe '#execute_global_command' do
        context 'with a Dial' do
          let :command do
            Adhearsion::Rayo::Command::Dial.new :to => 'SIP/1234', :from => 'abc123'
          end

          before do
            command.request!
            allow(ami_client).to receive(:send_action).and_return RubyAMI::Response.new
          end

          it 'should be able to look up the call by channel ID' do
            subject.execute_global_command command
            call = subject.call_for_channel('SIP/1234')
            expect(call).to be_a Asterisk::Call
          end

          it 'should instruct the call to send a dial' do
            mock_call = double('Asterisk::Call').as_null_object
            expect(Asterisk::Call).to receive(:new).once.and_return mock_call
            expect(mock_call).to receive(:dial).once.with command
            subject.execute_global_command command
          end

          context 'when requesting a specific URI' do
            let(:requested_uri) { connection.new_call_uri }

            before do
              command.uri = requested_uri
            end

            it "should assign the requested URI to the call" do
              subject.execute_global_command command
              expect(subject.call_with_id(requested_uri).id).to eq(requested_uri)
            end

            context 'and the requested URI already represents a known call' do
              before do
                earlier_command = Adhearsion::Rayo::Command::Dial.new to: 'SIP/1234', uri: requested_uri
                earlier_command.request!

                subject.execute_global_command earlier_command

                @first_call = subject.call_with_id(requested_uri)

                subject.execute_global_command command
              end

              it "should set the command response to a conflict error" do
                expect(command.response(0.1)).to eq(Adhearsion::ProtocolError.new.setup(:conflict, 'Call ID already in use'))
              end

              it "should not replace the original call in the registry" do
                expect(subject.call_with_id(requested_uri)).to be @first_call
              end
            end
          end
        end

        context 'with an AMI action' do
          let :command do
            Adhearsion::Rayo::Component::Asterisk::AMI::Action.new :name => 'Status', :params => { :channel => 'foo' }
          end

          let(:mock_action) { double('Asterisk::Component::Asterisk::AMIAction').as_null_object }

          it 'should create a component actor and execute it asynchronously' do
            expect(Asterisk::Component::Asterisk::AMIAction).to receive(:new).once.with(command, subject, ami_client).and_return mock_action
            expect(mock_action).to receive(:execute).once
            subject.execute_global_command command
          end

          it 'registers the component' do
            expect(Asterisk::Component::Asterisk::AMIAction).to receive(:new).once.with(command, subject, ami_client).and_return mock_action
            expect(subject.wrapped_object).to receive(:register_component).with mock_action
            subject.execute_global_command command
          end
        end

        context "with a command we don't understand" do
          let :command do
            Adhearsion::Rayo::Command::Answer.new
          end

          it 'sends an error in response to the command' do
            subject.execute_command command
            expect(command.response).to eq(Adhearsion::ProtocolError.new.setup('command-not-acceptable', "Did not understand command"))
          end
        end
      end

      describe '#handle_pb_event' do
        it 'should forward the event to the connection' do
          event = double 'Adhearsion::Event'
          expect(subject.connection).to receive(:handle_event).once.with event
          subject.handle_pb_event event
        end
      end

      describe '#handle_ami_event' do
        let :ami_event do
          RubyAMI::Event.new 'Newchannel',
            'Channel'  => "SIP/101-3f3f",
            'State'    => "Ring",
            'Callerid' => "101",
            'Uniqueid' => "1094154427.10"
        end

        let :expected_pb_event do
          Adhearsion::Event::Asterisk::AMI.new name: 'Newchannel',
                                          headers: { 'Channel'  => "SIP/101-3f3f",
                                                     'State'    => "Ring",
                                                     'Callerid' => "101",
                                                     'Uniqueid' => "1094154427.10"}
        end

        it 'should create a. AMI event object and pass it to the connection' do
          expect(subject.connection).to receive(:handle_event).once.with expected_pb_event
          subject.handle_ami_event ami_event
        end

        context "when the event doesn't pass the filter" do
          before { described_class.event_filter = ->(event) { false } }
          after { described_class.event_filter = nil }

          it 'does not send the AMI event to the connection as a PB event' do
            expect(subject.connection).to receive(:handle_event).never
            subject.handle_ami_event ami_event
          end
        end

        context 'with something that is not a RubyAMI::Event' do
          it 'does not send anything to the connection' do
            expect(subject.connection).to receive(:handle_event).never
            subject.handle_ami_event :foo
          end
        end

        describe 'with a FullyBooted event' do
          let(:ami_event) { RubyAMI::Event.new 'FullyBooted' }

          it 'sends a connected event to the event handler' do
            expect(subject.connection).to receive(:handle_event).once.with Adhearsion::Rayo::Connection::Connected.new
            expect(subject.wrapped_object).to receive(:run_at_fully_booted).once
            subject.handle_ami_event ami_event
          end
        end

        describe 'with an AsyncAGI Start event' do
          let :ami_event do
            RubyAMI::Event.new 'AsyncAGI',
              'SubEvent' => "Start",
              'Channel'  => "SIP/1234-00000000",
              'Env'      => "agi_request%3A%20async%0Aagi_channel%3A%20SIP%2F1234-00000000%0Aagi_language%3A%20en%0Aagi_type%3A%20SIP%0Aagi_uniqueid%3A%201320835995.0%0Aagi_version%3A%201.8.4.1%0Aagi_callerid%3A%205678%0Aagi_calleridname%3A%20Jane%20Smith%0Aagi_callingpres%3A%200%0Aagi_callingani2%3A%200%0Aagi_callington%3A%200%0Aagi_callingtns%3A%200%0Aagi_dnid%3A%201000%0Aagi_rdnis%3A%20unknown%0Aagi_context%3A%20default%0Aagi_extension%3A%201000%0Aagi_priority%3A%201%0Aagi_enhanced%3A%200.0%0Aagi_accountcode%3A%20%0Aagi_threadid%3A%204366221312%0A%0A"
          end

          let :expected_agi_env do
            {
              :agi_request      => 'async',
              :agi_channel      => 'SIP/1234-00000000',
              :agi_language     => 'en',
              :agi_type         => 'SIP',
              :agi_uniqueid     => '1320835995.0',
              :agi_version      => '1.8.4.1',
              :agi_callerid     => '5678',
              :agi_calleridname => 'Jane Smith',
              :agi_callingpres  => '0',
              :agi_callingani2  => '0',
              :agi_callington   => '0',
              :agi_callingtns   => '0',
              :agi_dnid         => '1000',
              :agi_rdnis        => 'unknown',
              :agi_context      => 'default',
              :agi_extension    => '1000',
              :agi_priority     => '1',
              :agi_enhanced     => '0.0',
              :agi_accountcode  => '',
              :agi_threadid     => '4366221312'
            }
          end

          before { allow(subject.wrapped_object).to receive :handle_pb_event }

          it 'should be able to look up the call by channel ID' do
            subject.handle_ami_event ami_event
            call = subject.call_for_channel('SIP/1234-00000000')
            expect(call).to be_a Asterisk::Call
            expect(call.agi_env).to be_a Hash
            expect(call.agi_env).to eq(expected_agi_env)
          end

          it 'should instruct the call to send an offer' do
            mock_call = double('Asterisk::Call').as_null_object
            expect(Asterisk::Call).to receive(:new).once.and_return mock_call
            expect(mock_call).to receive(:send_offer).once
            subject.handle_ami_event ami_event
          end

          context 'with an Asterisk 13 AsyncAGIStart event' do
            let :ami_event do
              RubyAMI::Event.new 'AsyncAGIStart',
              'Channel'  => "SIP/1234-00000000",
              'Env'      => "agi_request%3A%20async%0Aagi_channel%3A%20SIP%2F1234-00000000%0Aagi_language%3A%20en%0Aagi_type%3A%20SIP%0Aagi_uniqueid%3A%201320835995.0%0Aagi_version%3A%201.8.4.1%0Aagi_callerid%3A%205678%0Aagi_calleridname%3A%20Jane%20Smith%0Aagi_callingpres%3A%200%0Aagi_callingani2%3A%200%0Aagi_callington%3A%200%0Aagi_callingtns%3A%200%0Aagi_dnid%3A%201000%0Aagi_rdnis%3A%20unknown%0Aagi_context%3A%20default%0Aagi_extension%3A%201000%0Aagi_priority%3A%201%0Aagi_enhanced%3A%200.0%0Aagi_accountcode%3A%20%0Aagi_threadid%3A%204366221312%0A%0A"
            end

            it 'should be able to look up the call by channel ID' do
              subject.handle_ami_event ami_event
              call = subject.call_for_channel('SIP/1234-00000000')
              expect(call).to be_a Asterisk::Call
              expect(call.agi_env).to be_a Hash
              expect(call.agi_env).to eq(expected_agi_env)
            end

            it 'should instruct the call to send an offer' do
              mock_call = double('Asterisk::Call').as_null_object
              expect(Asterisk::Call).to receive(:new).once.and_return mock_call
              expect(mock_call).to receive(:send_offer).once
              subject.handle_ami_event ami_event
            end
          end

          context 'if a call already exists for a matching channel' do
            let(:call) { Asterisk::Call.new "SIP/1234-00000000", subject, ami_client, connection }

            before do
              subject.register_call call
            end

            it "should not create a new call" do
              expect(Asterisk::Call).to receive(:new).never
              subject.handle_ami_event ami_event
            end
          end

          context "for a 'h' extension" do
            let :ami_event do
              RubyAMI::Event.new 'AsyncAGI',
                'SubEvent' => "Start",
                'Channel'  => "SIP/1234-00000000",
                'Env'      => "agi_extension%3A%20h%0A%0A"
            end

            it "should not create a new call" do
              expect(Asterisk::Call).to receive(:new).never
              subject.handle_ami_event ami_event
            end

            it 'should not be able to look up the call by channel ID' do
              subject.handle_ami_event ami_event
              expect(subject.call_for_channel('SIP/1234-00000000')).to be nil
            end
          end

          context "for a 'Kill' type" do
            let :ami_event do
              RubyAMI::Event.new 'AsyncAGI',
                'SubEvent' => "Start",
                'Channel'  => "SIP/1234-00000000",
                'Env'      => "agi_type%3A%20Kill%0A%0A"
            end

            it "should not create a new call" do
              expect(Asterisk::Call).to receive(:new).never
              subject.handle_ami_event ami_event
            end

            it 'should not be able to look up the call by channel ID' do
              subject.handle_ami_event ami_event
              expect(subject.call_for_channel('SIP/1234-00000000')).to be nil
            end
          end
        end

        describe 'with a VarSet event including a adhearsion_call_id' do
          let :ami_event do
            RubyAMI::Event.new 'VarSet',
              "Privilege" => "dialplan,all",
              "Channel"   => "SIP/1234-00000000",
              "Variable"  => "adhearsion_call_id",
              "Value"     => call_id,
              "Uniqueid"  => "1326210224.0"
          end

          before do
            ami_client.as_null_object
            allow(subject.wrapped_object).to receive :handle_pb_event
          end

          context "matching a call that was created by a Dial command" do
            let(:dial_command) { Adhearsion::Rayo::Command::Dial.new :to => 'SIP/1234', :from => 'abc123' }

            before do
              dial_command.request!
              subject.execute_global_command dial_command
              call
            end

            let(:call)    { subject.call_for_channel 'SIP/1234' }
            let(:call_id) { call.id }

            it "should set the correct channel on the call" do
              subject.handle_ami_event ami_event
              expect(call.channel).to eq('SIP/1234-00000000')
            end

            it "should make it possible to look up the call by the full channel name" do
              subject.handle_ami_event ami_event
              expect(subject.call_for_channel("SIP/1234-00000000")).to be call
            end

            it "should make looking up the channel by the requested channel name impossible" do
              subject.handle_ami_event ami_event
              expect(subject.call_for_channel('SIP/1234')).to be_nil
            end
          end

          context "for a call that doesn't exist" do
            let(:call_id) { 'foobarbaz' }

            it "should not raise" do
              expect { subject.handle_ami_event ami_event }.not_to raise_error
            end
          end
        end

        describe 'with an AMI event for a known channel' do
          let :ami_event do
            RubyAMI::Event.new 'Hangup',
              'Uniqueid'      => "1320842458.8",
              'Calleridnum'   => "5678",
              'Calleridname'  => "Jane Smith",
              'Cause'         => "0",
              'Cause-txt'     => "Unknown",
              'Channel'       => "SIP/1234-00000000"
          end

          let(:call) do
            Asterisk::Call.new "SIP/1234-00000000", subject, ami_client, connection, "agi_request%3A%20async%0Aagi_channel%3A%20SIP%2F1234-00000000%0Aagi_language%3A%20en%0Aagi_type%3A%20SIP%0Aagi_uniqueid%3A%201320835995.0%0Aagi_version%3A%201.8.4.1%0Aagi_callerid%3A%205678%0Aagi_calleridname%3A%20Jane%20Smith%0Aagi_callingpres%3A%200%0Aagi_callingani2%3A%200%0Aagi_callington%3A%200%0Aagi_callingtns%3A%200%0Aagi_dnid%3A%201000%0Aagi_rdnis%3A%20unknown%0Aagi_context%3A%20default%0Aagi_extension%3A%201000%0Aagi_priority%3A%201%0Aagi_enhanced%3A%200.0%0Aagi_accountcode%3A%20%0Aagi_threadid%3A%204366221312%0A%0A"
          end

          before do
            subject.register_call call
          end

          it 'sends the AMI event to the call and to the connection as a PB event' do
            expect(call).to receive(:process_ami_event).once.with ami_event
            subject.handle_ami_event ami_event
          end

          context 'with a Channel1 and Channel2 specified on the event' do
            let :ami_event do
              RubyAMI::Event.new 'BridgeAction',
                'Privilege' => "call,all",
                'Response'  => "Success",
                'Channel1'  => "SIP/1234-00000000",
                'Channel2'  => "SIP/5678-00000000"
            end

            context 'with calls for those channels' do
              let(:call2) do
                Asterisk::Call.new "SIP/5678-00000000", subject, ami_client, connection, "agi_request%3A%20async%0Aagi_channel%3A%20SIP%2F1234-00000000%0Aagi_language%3A%20en%0Aagi_type%3A%20SIP%0Aagi_uniqueid%3A%201320835995.0%0Aagi_version%3A%201.8.4.1%0Aagi_callerid%3A%205678%0Aagi_calleridname%3A%20Jane%20Smith%0Aagi_callingpres%3A%200%0Aagi_callingani2%3A%200%0Aagi_callington%3A%200%0Aagi_callingtns%3A%200%0Aagi_dnid%3A%201000%0Aagi_rdnis%3A%20unknown%0Aagi_context%3A%20default%0Aagi_extension%3A%201000%0Aagi_priority%3A%201%0Aagi_enhanced%3A%200.0%0Aagi_accountcode%3A%20%0Aagi_threadid%3A%204366221312%0A%0A"
              end

              before { subject.register_call call2 }

              it 'should send the event to both calls and to the connection once as a PB event' do
                expect(call).to receive(:process_ami_event).once.with ami_event
                expect(call2).to receive(:process_ami_event).once.with ami_event
                subject.handle_ami_event ami_event
              end
            end
          end
        end

        describe 'with an event for a channel with Bridge and special statuses appended' do
          let :ami_event do
            RubyAMI::Event.new 'AGIExec',
              'SubEvent'  => "End",
              'Channel'   => "Bridge/SIP/1234-00000000<ZOMBIE>"
          end

          let :ami_event2 do
            RubyAMI::Event.new 'Hangup',
              'Uniqueid'      => "1320842458.8",
              'Calleridnum'   => "5678",
              'Calleridname'  => "Jane Smith",
              'Cause'         => "0",
              'Cause-txt'     => "Unknown",
              'Channel'       => "Bridge/SIP/1234-00000000<ZOMBIE>"
          end

          let(:call) do
            Asterisk::Call.new "SIP/1234-00000000", subject, ami_client, connection, "agi_request%3A%20async%0Aagi_channel%3A%20SIP%2F1234-00000000%0Aagi_language%3A%20en%0Aagi_type%3A%20SIP%0Aagi_uniqueid%3A%201320835995.0%0Aagi_version%3A%201.8.4.1%0Aagi_callerid%3A%205678%0Aagi_calleridname%3A%20Jane%20Smith%0Aagi_callingpres%3A%200%0Aagi_callingani2%3A%200%0Aagi_callington%3A%200%0Aagi_callingtns%3A%200%0Aagi_dnid%3A%201000%0Aagi_rdnis%3A%20unknown%0Aagi_context%3A%20default%0Aagi_extension%3A%201000%0Aagi_priority%3A%201%0Aagi_enhanced%3A%200.0%0Aagi_accountcode%3A%20%0Aagi_threadid%3A%204366221312%0A%0A"
          end

          before do
            subject.register_call call
          end

          it 'sends the AMI event to the call and to the connection as a PB event if it is an allowed event' do
            expect(call).to receive(:process_ami_event).once.with ami_event
            subject.handle_ami_event ami_event
          end

          it 'does not send the AMI event to a bridged channel if it is not allowed' do
            expect(call).to receive(:process_ami_event).never.with ami_event2
            subject.handle_ami_event ami_event2
          end

        end
      end

      describe '#run_at_fully_booted' do
        let(:broken_path) { "/this/is/not/a/valid/path" }

        let(:passed_show) do
          OpenStruct.new text_body: "[ Context 'adhearsion-redirect' created by 'pbx_config' ]\n '1' => 1. AGI(agi:async)[pbx_config]\n\n-= 1 extension (1 priority) in 1 context. =-"
        end

        let(:failed_show) do
          OpenStruct.new text_body: "There is no existence of 'adhearsion-redirect' context\nCommand 'dialplan show adhearsion-redirect' failed."
        end

        it 'should send the redirect extension Command to the AMI client' do
          expect(ami_client).to receive(:send_action).once.with(
            'Command',
            Hash('Command' => "dialplan add extension #{Asterisk::REDIRECT_EXTENSION},#{Asterisk::REDIRECT_PRIORITY},AGI,agi:async into #{Asterisk::REDIRECT_CONTEXT}")
          )
          expect(ami_client).to receive(:send_action).once.with('Command', Hash('Command' => "dialplan show #{Asterisk::REDIRECT_CONTEXT}")).and_return(passed_show)
          subject.run_at_fully_booted
        end

        it 'should check the context for existence and do nothing if it is there' do
          expect(ami_client).to receive(:send_action).once.with('Command', Hash('Command' => "dialplan add extension #{Asterisk::REDIRECT_EXTENSION},#{Asterisk::REDIRECT_PRIORITY},AGI,agi:async into #{Asterisk::REDIRECT_CONTEXT}"))
          expect(ami_client).to receive(:send_action).once.with('Command', Hash('Command' => "dialplan show #{Asterisk::REDIRECT_CONTEXT}")).and_return(passed_show)
          subject.run_at_fully_booted
        end

        it 'should check the context for existence and log an error if it is not there' do
          expect(ami_client).to receive(:send_action).once.with('Command', Hash('Command' => "dialplan add extension #{Asterisk::REDIRECT_EXTENSION},#{Asterisk::REDIRECT_PRIORITY},AGI,agi:async into #{Asterisk::REDIRECT_CONTEXT}"))
          expect(ami_client).to receive(:send_action).once.with('Command', Hash('Command' => "dialplan show #{Asterisk::REDIRECT_CONTEXT}")).and_return(failed_show)
          expect(translator.logger).to receive(:error).once.with("Adhearsion failed to add the #{Asterisk::REDIRECT_EXTENSION} extension to the #{Asterisk::REDIRECT_CONTEXT} context. Please add a [#{Asterisk::REDIRECT_CONTEXT}] entry to your dialplan.")
          subject.run_at_fully_booted
        end

        it 'should check the recording directory for existence' do
          stub_const('Adhearsion::Translator::Asterisk::Component::Record::RECORDING_BASE_PATH', broken_path)
          expect(ami_client).to receive(:send_action).once.with('Command', Hash('Command' => "dialplan add extension #{Asterisk::REDIRECT_EXTENSION},#{Asterisk::REDIRECT_PRIORITY},AGI,agi:async into #{Asterisk::REDIRECT_CONTEXT}"))
          expect(ami_client).to receive(:send_action).once.with('Command', Hash('Command' => "dialplan show #{Asterisk::REDIRECT_CONTEXT}")).and_return(passed_show)
          expect(translator.logger).to receive(:warn).once.with("Recordings directory #{broken_path} does not exist. Recording might not work. This warning can be ignored if Adhearsion is running on a separate machine than Asterisk. See http://adhearsion.com/docs/call-controllers#recording")
          subject.run_at_fully_booted
        end
      end

      describe '#check_recording_directory' do
        let(:broken_path) { "/this/is/not/a/valid/path" }
        it 'logs a warning if the recording directory does not exist' do
          stub_const('Adhearsion::Translator::Asterisk::Component::Record::RECORDING_BASE_PATH', broken_path)
          expect(translator.logger).to receive(:warn).once.with("Recordings directory #{broken_path} does not exist. Recording might not work. This warning can be ignored if Adhearsion is running on a separate machine than Asterisk. See http://adhearsion.com/docs/call-controllers#recording")
          subject.check_recording_directory
        end
      end
    end
  end
end
