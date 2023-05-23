# encoding: utf-8

require 'spec_helper'

module Adhearsion
  module Translator
    class Asterisk
      describe Call do
        let(:channel)         { 'SIP/foo' }
        let(:ami_client)      { double('AMI Client').as_null_object }
        let(:connection)      { double('connection').as_null_object }
        let(:translator)      { Asterisk.new ami_client, connection }
        let(:agi_env) do
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
            :agi_dnid         => 'unknown',
            :agi_rdnis        => 'unknown',
            :agi_context      => 'default',
            :agi_extension    => '1000',
            :agi_priority     => '1',
            :agi_enhanced     => '0.0',
            :agi_accountcode  => '',
            :agi_threadid     => '4366221312'
          }
        end

        let :sip_headers do
          {
            'X-agi_request'      => 'async',
            'X-agi_channel'      => 'SIP/1234-00000000',
            'X-agi_language'     => 'en',
            'X-agi_type'         => 'SIP',
            'X-agi_uniqueid'     => '1320835995.0',
            'X-agi_version'      => '1.8.4.1',
            'X-agi_callerid'     => '5678',
            'X-agi_calleridname' => 'Jane Smith',
            'X-agi_callingpres'  => '0',
            'X-agi_callingani2'  => '0',
            'X-agi_callington'   => '0',
            'X-agi_callingtns'   => '0',
            'X-agi_dnid'         => 'unknown',
            'X-agi_rdnis'        => 'unknown',
            'X-agi_context'      => 'default',
            'X-agi_extension'    => '1000',
            'X-agi_priority'     => '1',
            'X-agi_enhanced'     => '0.0',
            'X-agi_accountcode'  => '',
            'X-agi_threadid'     => '4366221312'
          }
        end

        subject { Call.new channel, translator, ami_client, connection, agi_env }

        describe '#id' do
          subject { super().id }
          it { is_expected.to be_a String }
        end

        describe '#channel' do
          subject { super().channel }
          it { is_expected.to eq(channel) }
        end

        describe '#translator' do
          subject { super().translator }
          it { is_expected.to be translator }
        end

        describe '#agi_env' do
          subject { super().agi_env }
          it { is_expected.to eq(agi_env) }
        end

        before { allow(translator).to receive :handle_pb_event }

        describe '#register_component' do
          it 'should make the component accessible by ID' do
            component_id = 'abc123'
            component    = double 'Translator::Asterisk::Component', :id => component_id
            subject.register_component component
            expect(subject.component_with_id(component_id)).to be component
          end
        end

        describe "getting channel vars" do
          it "should do a GetVar when we don't have a cached value" do
            response = RubyAMI::Response.new 'Value' => 'thevalue'
            expect(ami_client).to receive(:send_action).once.with('GetVar', 'Channel' => channel, 'Variable' => 'somevariable').and_return response
            expect(subject.channel_var('somevariable')).to eq('thevalue')
          end

          context "when the value comes back from GetVar as '(null)'" do
            it "should return nil" do
              response = RubyAMI::Response.new 'Value' => '(null)'
              expect(ami_client).to receive(:send_action).once.with('GetVar', 'Channel' => channel, 'Variable' => 'somevariable').and_return response
              expect(subject.channel_var('somevariable')).to be_nil
            end
          end
        end

        describe '#send_offer' do
          it 'sends an offer to the translator' do
            expected_offer = Adhearsion::Event::Offer.new :target_call_id  => subject.id,
                                                          :to       => '1000',
                                                          :from     => 'Jane Smith <SIP/5678>',
                                                          :headers  => sip_headers
            expect(translator).to receive(:handle_pb_event).with expected_offer
            subject.send_offer
          end

          it 'should make the call identify as inbound' do
            subject.send_offer
            expect(subject.direction).to eq(:inbound)
            expect(subject.inbound?).to be true
            expect(subject.outbound?).to be false
          end
        end

        describe '#send_progress' do
          context "with a call that is already answered" do
            it 'should not send the EXEC Progress command' do
              expect(subject).to receive(:'answered?').and_return true
              expect(subject).to receive(:execute_agi_command).with("EXEC Progress").never
              subject.send_progress
            end
          end

          context "with an unanswered call" do
            before do
              expect(subject).to receive(:'answered?').at_least(:once).and_return(false)
            end

            context "with a call that is outbound" do
              let(:dial_command) { Adhearsion::Rayo::Command::Dial.new }

              before do
                dial_command.request!
                subject.dial dial_command
              end

              it 'should not send the EXEC Progress command' do
                expect(subject).to receive(:execute_agi_command).with("EXEC Progress").never
                subject.send_progress
              end
            end

            context "with a call that is inbound" do
              before do
                subject.send_offer
              end

              it 'should send the EXEC Progress command to a call that is inbound and not answered' do
                expect(subject).to receive(:execute_agi_command).with("EXEC Progress").and_return code: 200, result: 0
                subject.send_progress
              end

              it 'should send the EXEC Progress command only once if called twice' do
                expect(subject).to receive(:execute_agi_command).with("EXEC Progress").once.and_return code: 200, result: 0
                subject.send_progress
                subject.send_progress
              end
            end
          end
        end

        describe '#dial' do
          let(:dial_command_options) { {} }

          let(:to) { 'SIP/1234' }

          let :dial_command do
            Adhearsion::Rayo::Command::Dial.new({:to => to, :from => 'sip:foo@bar.com'}.merge(dial_command_options))
          end

          before { dial_command.request! }

          it 'sends an Originate AMI action' do
            expect(ami_client).to receive(:send_action).once.with(
              'Originate',
              Hash(
                'Async'       => true,
                'Context'     => REDIRECT_CONTEXT,
                'Exten'       => REDIRECT_EXTENSION,
                'Priority'    => REDIRECT_PRIORITY,
                'Channel'     => 'SIP/1234',
                'Callerid'    => 'sip:foo@bar.com',
                'Variable'    => "adhearsion_call_id=#{subject.id}"
              )
            ).and_return RubyAMI::Response.new

            subject.dial dial_command
            sleep 0.1
          end

          context 'with a name and channel in the to field' do
            let(:to)  { 'Jane Smith <SIP/5678>' }

            it 'sends an Originate AMI action with only the channel' do
              expect(ami_client).to receive(:send_action).once.with(
                'Originate',
                Hash(
                  'Async'       => true,
                  'Context'     => REDIRECT_CONTEXT,
                  'Exten'       => REDIRECT_EXTENSION,
                  'Priority'    => REDIRECT_PRIORITY,
                  'Channel'     => 'SIP/5678',
                  'Callerid'    => 'sip:foo@bar.com',
                  'Variable'    => "adhearsion_call_id=#{subject.id}"
                )
              ).and_return RubyAMI::Response.new

              subject.dial dial_command
              sleep 0.1
            end
          end

          context 'with a timeout specified' do
            let :dial_command_options do
              { :timeout => 10000 }
            end

            it 'includes the timeout in the Originate AMI action' do
              expect(ami_client).to receive(:send_action).once.with(
                'Originate',
                Hash(
                  'Async'       => true,
                  'Context'     => REDIRECT_CONTEXT,
                  'Exten'       => REDIRECT_EXTENSION,
                  'Priority'    => REDIRECT_PRIORITY,
                  'Channel'     => 'SIP/1234',
                  'Callerid'    => 'sip:foo@bar.com',
                  'Variable'    => "adhearsion_call_id=#{subject.id}",
                  'Timeout'     => 10000
                )
              ).and_return RubyAMI::Response.new

              subject.dial dial_command
              sleep 0.1
            end
          end

          context 'with headers specified' do
            let :dial_command_options do
              { :headers => {'X-foo' => 'bar', 'X-doo' => 'dah'} }
            end

            it 'includes the headers in the Originate AMI action' do
              expect(ami_client).to receive(:send_action).once.with(
                'Originate',
                Hash(
                  'Async'       => true,
                  'Context'     => REDIRECT_CONTEXT,
                  'Exten'       => REDIRECT_EXTENSION,
                  'Priority'    => REDIRECT_PRIORITY,
                  'Channel'     => 'SIP/1234',
                  'Callerid'    => 'sip:foo@bar.com',
                  'Variable'    => "adhearsion_call_id=#{subject.id},SIPADDHEADER51=\"X-foo: bar\",SIPADDHEADER52=\"X-doo: dah\""
                )
              ).and_return RubyAMI::Response.new

              subject.dial dial_command
              sleep 0.1
            end
          end

          it 'sends the call ID as a response to the Dial' do
            subject.dial dial_command
            dial_command.response
            expect(dial_command.target_call_id).to eq(subject.id)
          end

          it 'should make the call identify as outbound' do
            subject.dial dial_command
            expect(subject.direction).to eq(:outbound)
            expect(subject.outbound?).to be true
            expect(subject.inbound?).to be false
          end

          it 'causes accepting the call to be a null operation' do
            subject.dial dial_command
            accept_command = Adhearsion::Rayo::Command::Accept.new
            accept_command.request!
            expect(subject).to receive(:execute_agi_command).never
            subject.execute_command accept_command
            expect(accept_command.response(0.5)).to be true
          end
        end

        describe '#process_ami_event' do
          context 'with a Hangup event' do
            let :ami_event do
              RubyAMI::Event.new 'Hangup',
                'Uniqueid'      => "1320842458.8",
                'Calleridnum'   => "5678",
                'Calleridname'  => "Jane Smith",
                'Cause'         => cause,
                'Cause-txt'     => cause_txt,
                'Channel'       => "SIP/1234-00000000"
            end

            let(:cause)     { '16' }
            let(:cause_txt) { 'Normal Clearing' }

            it "de-registers the call from the translator" do
              allow(translator).to receive :handle_pb_event
              expect(translator).to receive(:deregister_call).once.with(subject.id, subject.channel)
              subject.process_ami_event ami_event
            end

            it "should cause all components to send complete events before sending end event" do
              allow(subject).to receive :send_progress
              comp_command = Adhearsion::Rayo::Component::Input.new :grammar => {:value => RubySpeech::GRXML.draw(root: 'foo') { rule id: 'foo' }}, :mode => :dtmf
              comp_command.request!
              component = subject.execute_command comp_command
              expect(comp_command.response(0.1)).to be_a Adhearsion::Rayo::Ref
              expected_complete_event = Adhearsion::Event::Complete.new :target_call_id => subject.id, :component_id => component.id, source_uri: component.id
              expected_complete_event.reason = Adhearsion::Event::Complete::Hangup.new
              expected_end_event = Adhearsion::Event::End.new :reason => :hungup, platform_code: cause, :target_call_id  => subject.id

              expect(translator).to receive(:handle_pb_event).with(expected_complete_event).once.ordered
              expect(translator).to receive(:handle_pb_event).with(expected_end_event).once.ordered
              subject.process_ami_event ami_event
            end

            it "should not allow commands to be executed while components are shutting down" do
              call_id = subject.id

              allow(subject).to receive :send_progress
              comp_command = Adhearsion::Rayo::Component::Input.new :grammar => {:value => RubySpeech::GRXML.draw(root: 'foo') { rule id: 'foo' }}, :mode => :dtmf
              comp_command.request!
              component = subject.execute_command comp_command
              expect(comp_command.response(0.1)).to be_a Adhearsion::Rayo::Ref

              subject.process_ami_event ami_event

              comp_command = Adhearsion::Rayo::Component::Input.new :grammar => {:value => '<grammar root="foo"><rule id="foo"/></grammar>'}, :mode => :dtmf
              comp_command.request!
              subject.execute_command comp_command
              expect(comp_command.response(0.1)).to eq(Adhearsion::ProtocolError.new.setup(:item_not_found, "Could not find a call with ID #{call_id}", call_id))
            end

            context "when the AMI event has a timestamp" do
              let :ami_event do
                RubyAMI::Event.new 'Hangup',
                  'Uniqueid'      => "1320842458.8",
                  'Cause'         => cause,
                  'Cause-txt'     => cause_txt,
                  'Channel'       => "SIP/1234-00000000",
                  'Timestamp'     => '1393368380.572575'
              end

              it "should use the AMI timestamp for the Rayo event" do
                expected_end_event = Adhearsion::Event::End.new reason: :hungup,
                                                                platform_code: cause,
                                                                target_call_id: subject.id,
                                                                timestamp: DateTime.new(2014, 2, 25, 22, 46, 20)
                expect(translator).to receive(:handle_pb_event).with expected_end_event

                subject.process_ami_event ami_event
              end
            end

            context "after processing a hangup command" do
              let(:command) { Adhearsion::Rayo::Command::Hangup.new }

              before do
                command.request!
                subject.execute_command command
              end

              it 'should send an end (hangup_command) event to the translator' do
                expected_end_event = Adhearsion::Event::End.new :reason   => :hangup_command,
                                                                platform_code: cause,
                                                                :target_call_id  => subject.id
                expect(translator).to receive(:handle_pb_event).with expected_end_event

                subject.process_ami_event ami_event
              end
            end

            context "with an undefined cause" do
              let(:cause)     { '0' }
              let(:cause_txt) { 'Undefined' }

              it 'should send an end (hungup) event to the translator' do
                expected_end_event = Adhearsion::Event::End.new :reason   => :hungup,
                                                                platform_code: cause,
                                                                :target_call_id  => subject.id
                expect(translator).to receive(:handle_pb_event).with expected_end_event
                subject.process_ami_event ami_event
              end
            end

            context "with a normal clearing cause" do
              let(:cause)     { '16' }
              let(:cause_txt) { 'Normal Clearing' }

              it 'should send an end (hungup) event to the translator' do
                expected_end_event = Adhearsion::Event::End.new :reason   => :hungup,
                                                                platform_code: cause,
                                                                :target_call_id  => subject.id
                expect(translator).to receive(:handle_pb_event).with expected_end_event
                subject.process_ami_event ami_event
              end
            end

            context "with a user busy cause" do
              let(:cause)     { '17' }
              let(:cause_txt) { 'User Busy' }

              it 'should send an end (busy) event to the translator' do
                expected_end_event = Adhearsion::Event::End.new :reason   => :busy,
                                                                platform_code: cause,
                                                                :target_call_id  => subject.id
                expect(translator).to receive(:handle_pb_event).with expected_end_event
                subject.process_ami_event ami_event
              end
            end

            {
              18 => 'No user response',
              102 => 'Recovery on timer expire'
            }.each_pair do |cause, cause_txt|
              context "with a #{cause_txt} cause" do
                let(:cause)     { cause.to_s }
                let(:cause_txt) { cause_txt }

                it 'should send an end (timeout) event to the translator' do
                  expected_end_event = Adhearsion::Event::End.new :reason   => :timeout,
                                                                  platform_code: cause,
                                                                  :target_call_id  => subject.id
                  expect(translator).to receive(:handle_pb_event).with expected_end_event
                  subject.process_ami_event ami_event
                end
              end
            end

            {
              19 => 'No Answer',
              21 => 'Call Rejected',
              22 => 'Number Changed'
            }.each_pair do |cause, cause_txt|
              context "with a #{cause_txt} cause" do
                let(:cause)     { cause.to_s }
                let(:cause_txt) { cause_txt }

                it 'should send an end (reject) event to the translator' do
                  expected_end_event = Adhearsion::Event::End.new :reason   => :reject,
                                                                  platform_code: cause,
                                                                  :target_call_id  => subject.id
                  expect(translator).to receive(:handle_pb_event).with expected_end_event
                  subject.process_ami_event ami_event
                end
              end
            end

            {
              1   => 'AST_CAUSE_UNALLOCATED',
              2   => 'NO_ROUTE_TRANSIT_NET',
              3   => 'NO_ROUTE_DESTINATION',
              6   => 'CHANNEL_UNACCEPTABLE',
              7   => 'CALL_AWARDED_DELIVERED',
              27  => 'DESTINATION_OUT_OF_ORDER',
              28  => 'INVALID_NUMBER_FORMAT',
              29  => 'FACILITY_REJECTED',
              30  => 'RESPONSE_TO_STATUS_ENQUIRY',
              31  => 'NORMAL_UNSPECIFIED',
              34  => 'NORMAL_CIRCUIT_CONGESTION',
              38  => 'NETWORK_OUT_OF_ORDER',
              41  => 'NORMAL_TEMPORARY_FAILURE',
              42  => 'SWITCH_CONGESTION',
              43  => 'ACCESS_INFO_DISCARDED',
              44  => 'REQUESTED_CHAN_UNAVAIL',
              45  => 'PRE_EMPTED',
              50  => 'FACILITY_NOT_SUBSCRIBED',
              52  => 'OUTGOING_CALL_BARRED',
              54  => 'INCOMING_CALL_BARRED',
              57  => 'BEARERCAPABILITY_NOTAUTH',
              58  => 'BEARERCAPABILITY_NOTAVAIL',
              65  => 'BEARERCAPABILITY_NOTIMPL',
              66  => 'CHAN_NOT_IMPLEMENTED',
              69  => 'FACILITY_NOT_IMPLEMENTED',
              81  => 'INVALID_CALL_REFERENCE',
              88  => 'INCOMPATIBLE_DESTINATION',
              95  => 'INVALID_MSG_UNSPECIFIED',
              96  => 'MANDATORY_IE_MISSING',
              97  => 'MESSAGE_TYPE_NONEXIST',
              98  => 'WRONG_MESSAGE',
              99  => 'IE_NONEXIST',
              100 => 'INVALID_IE_CONTENTS',
              101 => 'WRONG_CALL_STATE',
              103 => 'MANDATORY_IE_LENGTH_ERROR',
              111 => 'PROTOCOL_ERROR',
              127 => 'INTERWORKING'
            }.each_pair do |cause, cause_txt|
              context "with a #{cause_txt} cause" do
                let(:cause)     { cause.to_s }
                let(:cause_txt) { cause_txt }

                it 'should send an end (error) event to the translator' do
                  expected_end_event = Adhearsion::Event::End.new :reason   => :error,
                                                                  platform_code: cause,
                                                                  :target_call_id  => subject.id
                  expect(translator).to receive(:handle_pb_event).with expected_end_event
                  subject.process_ami_event ami_event
                end
              end
            end
          end

          context 'with an event for a known AGI command component' do
            let(:mock_component_node) { Adhearsion::Rayo::Component::Asterisk::AGI::Command.new name: 'EXEC ANSWER', params: [] }
            let :component do
              Component::Asterisk::AGICommand.new mock_component_node, subject
            end
            before do
              subject.register_component component
            end

            context 'with Asterisk 11 AsyncAGI SubEvent' do
              let(:ami_event) do
                RubyAMI::Event.new "AsyncAGI",
                  "SubEvent"  => "End",
                  "Channel"   => "SIP/1234-00000000",
                  "CommandID" => component.id,
                  "Command"   => "EXEC ANSWER",
                  "Result"    => "200%20result=123%20(timeout)%0A"
              end

              it 'should send the event to the component' do
                expect(component).to receive(:handle_ami_event).once.with ami_event
                subject.process_ami_event ami_event
              end

              it 'should not send an answered event' do
                expect(translator).to receive(:handle_pb_event).with(kind_of(Adhearsion::Event::Answered)).never
                subject.process_ami_event ami_event
              end
            end

            context 'with Asterisk 13 AsyncAGIEnd and CommandId with a lowercase d' do
              let(:ami_event) do
                RubyAMI::Event.new "AsyncAGIEnd",
                  "Channel"   => "SIP/1234-00000000",
                  "CommandId" => component.id,
                  "Command"   => "EXEC ANSWER",
                  "Result"    => "200%20result=123%20(timeout)%0A"
              end

              it 'should send the event to the component' do
                expect(component).to receive(:handle_ami_event).once.with ami_event
                subject.process_ami_event ami_event
              end

              it 'should not send an answered event' do
                expect(translator).to receive(:handle_pb_event).with(kind_of(Adhearsion::Event::Answered)).never
                subject.process_ami_event ami_event
              end
            end
          end

          def should_send_answered_event
            expected_answered = Adhearsion::Event::Answered.new
            expected_answered.target_call_id = subject.id
            expect(translator).to receive(:handle_pb_event).with expected_answered
            subject.process_ami_event ami_event
          end

          def answered_should_be_true
            subject.process_ami_event ami_event
            expect(subject.answered?).to be_truthy
          end

          def should_only_send_one_answered_event
            expected_answered = Adhearsion::Event::Answered.new
            expected_answered.target_call_id = subject.id
            expect(translator).to receive(:handle_pb_event).with(expected_answered).once
            subject.process_ami_event ami_event
            subject.process_ami_event ami_event
          end

          def should_use_ami_timestamp_for_rayo_event
            expected_answered = Adhearsion::Event::Answered.new target_call_id: subject.id,
                                                           timestamp: DateTime.new(2014, 2, 25, 22, 46, 20)
            expect(translator).to receive(:handle_pb_event).with expected_answered

            subject.process_ami_event ami_event
          end

          context 'with an AsyncAGI Start event' do
            let(:ami_event) do
              RubyAMI::Event.new "AsyncAGI",
                "SubEvent"  => "Start",
                "Channel"   => "SIP/1234-00000000",
                "Env"       => "agi_request%3A%20async%0Aagi_channel%3A%20SIP%2Fuserb-00000006%0Aagi_language%3A%20en%0Aagi_type%3A%20SIP%0Aagi_uniqueid%3A%201390303636.6%0Aagi_version%3A%2011.7.0%0Aagi_callerid%3A%20userb%0Aagi_calleridname%3A%20User%20B%0Aagi_callingpres%3A%200%0Aagi_callingani2%3A%200%0Aagi_callington%3A%200%0Aagi_callingtns%3A%200%0Aagi_dnid%3A%20unknown%0Aagi_rdnis%3A%20unknown%0Aagi_context%3A%20adhearsion-redirect%0Aagi_extension%3A%201%0Aagi_priority%3A%201%0Aagi_enhanced%3A%200.0%0Aagi_accountcode%3A%20%0Aagi_threadid%3A%20139696536876800%0A%0A"
            end

            it 'should send an answered event' do
              should_send_answered_event
            end

            it '#answered? should be true' do
              answered_should_be_true
            end

            context "for a second time" do
              it 'should only send one answered event' do
                should_only_send_one_answered_event
              end
            end

            context "when the AMI event has a timestamp" do
              let :ami_event do
                RubyAMI::Event.new "AsyncAGI",
                  "SubEvent"  => "Start",
                  "Channel"   => "SIP/1234-00000000",
                  "Env"       => "agi_request%3A%20async%0Aagi_channel%3A%20SIP%2Fuserb-00000006%0Aagi_language%3A%20en%0Aagi_type%3A%20SIP%0Aagi_uniqueid%3A%201390303636.6%0Aagi_version%3A%2011.7.0%0Aagi_callerid%3A%20userb%0Aagi_calleridname%3A%20User%20B%0Aagi_callingpres%3A%200%0Aagi_callingani2%3A%200%0Aagi_callington%3A%200%0Aagi_callingtns%3A%200%0Aagi_dnid%3A%20unknown%0Aagi_rdnis%3A%20unknown%0Aagi_context%3A%20adhearsion-redirect%0Aagi_extension%3A%201%0Aagi_priority%3A%201%0Aagi_enhanced%3A%200.0%0Aagi_accountcode%3A%20%0Aagi_threadid%3A%20139696536876800%0A%0A",
                  'Timestamp' => '1393368380.572575'
              end

              it "should use the AMI timestamp for the Rayo event" do
                should_use_ami_timestamp_for_rayo_event
              end
            end
          end

          context 'with an Asterisk 13 AsyncAGIStart event' do
            let(:ami_event) do
              RubyAMI::Event.new "AsyncAGIStart",
                "Channel"   => "SIP/1234-00000000",
                "Env"       => "agi_request%3A%20async%0Aagi_channel%3A%20SIP%2Fuserb-00000006%0Aagi_language%3A%20en%0Aagi_type%3A%20SIP%0Aagi_uniqueid%3A%201390303636.6%0Aagi_version%3A%2011.7.0%0Aagi_callerid%3A%20userb%0Aagi_calleridname%3A%20User%20B%0Aagi_callingpres%3A%200%0Aagi_callingani2%3A%200%0Aagi_callington%3A%200%0Aagi_callingtns%3A%200%0Aagi_dnid%3A%20unknown%0Aagi_rdnis%3A%20unknown%0Aagi_context%3A%20adhearsion-redirect%0Aagi_extension%3A%201%0Aagi_priority%3A%201%0Aagi_enhanced%3A%200.0%0Aagi_accountcode%3A%20%0Aagi_threadid%3A%20139696536876800%0A%0A"
            end

            it 'should send an answered event' do
              should_send_answered_event
            end

            it '#answered? should be true' do
              answered_should_be_true
            end

            context "for a second time" do
              it 'should only send one answered event' do
                should_only_send_one_answered_event
              end
            end

            context "when the AMI event has a timestamp" do
              let :ami_event do
                RubyAMI::Event.new "AsyncAGIStart",
                  "Channel"   => "SIP/1234-00000000",
                  "Env"       => "agi_request%3A%20async%0Aagi_channel%3A%20SIP%2Fuserb-00000006%0Aagi_language%3A%20en%0Aagi_type%3A%20SIP%0Aagi_uniqueid%3A%201390303636.6%0Aagi_version%3A%2011.7.0%0Aagi_callerid%3A%20userb%0Aagi_calleridname%3A%20User%20B%0Aagi_callingpres%3A%200%0Aagi_callingani2%3A%200%0Aagi_callington%3A%200%0Aagi_callingtns%3A%200%0Aagi_dnid%3A%20unknown%0Aagi_rdnis%3A%20unknown%0Aagi_context%3A%20adhearsion-redirect%0Aagi_extension%3A%201%0Aagi_priority%3A%201%0Aagi_enhanced%3A%200.0%0Aagi_accountcode%3A%20%0Aagi_threadid%3A%20139696536876800%0A%0A",
                  'Timestamp' => '1393368380.572575'
              end

              it "should use the AMI timestamp for the Rayo event" do
                should_use_ami_timestamp_for_rayo_event
              end
            end
          end

          context 'with a Newstate event' do
            let :ami_event do
              RubyAMI::Event.new 'Newstate',
                'Privilege'         => 'call,all',
                'Channel'           => 'SIP/1234-00000000',
                'ChannelState'      => channel_state,
                'ChannelStateDesc'  => channel_state_desc,
                'CallerIDNum'       => '',
                'CallerIDName'      => '',
                'ConnectedLineNum'  => '',
                'ConnectedLineName' => '',
                'Uniqueid'          => '1326194671.0'
            end

            context 'ringing' do
              let(:channel_state)       { '5' }
              let(:channel_state_desc)  { 'Ringing' }

              it 'should send a ringing event' do
                expected_ringing = Adhearsion::Event::Ringing.new
                expected_ringing.target_call_id = subject.id
                expect(translator).to receive(:handle_pb_event).with expected_ringing
                subject.process_ami_event ami_event
              end

              it '#answered? should return false' do
                subject.process_ami_event ami_event
                expect(subject.answered?).to be_falsey
              end

              context "when the AMI event has a timestamp" do
                let :ami_event do
                  RubyAMI::Event.new 'Newstate',
                    'Channel'           => 'SIP/1234-00000000',
                    'ChannelState'      => channel_state,
                    'ChannelStateDesc'  => channel_state_desc,
                    'Uniqueid'          => '1326194671.0',
                    'Timestamp'         => '1393368380.572575'
                end

                it "should use the AMI timestamp for the Rayo event" do
                  expected_ringing = Adhearsion::Event::Ringing.new target_call_id: subject.id,
                                                                    timestamp: DateTime.new(2014, 2, 25, 22, 46, 20)
                  expect(translator).to receive(:handle_pb_event).with expected_ringing

                  subject.process_ami_event ami_event
                end
              end
            end
          end

          context 'with an OriginateResponse event' do
            let :ami_event do
              RubyAMI::Event.new 'OriginateResponse',
                'Privilege'     => 'call,all',
                'ActionID'      => '9d0c1aa4-5e3b-4cae-8aef-76a6119e2909',
                'Response'      => response,
                'Channel'       => 'SIP/15557654321',
                'Context'       => '',
                'Exten'         => '',
                'Reason'        => '0',
                'Uniqueid'      => uniqueid,
                'CallerIDNum'   => 'sip:5551234567',
                'CallerIDName'  => 'Bryan 100'
            end

            context 'sucessful' do
              let(:response)  { 'Success' }
              let(:uniqueid)  { '<null>' }

              it 'should not send an end event' do
                expect(translator).to receive(:handle_pb_event).once.with an_instance_of(Adhearsion::Event::Asterisk::AMI)
                subject.process_ami_event ami_event
              end
            end

            context 'failed after being connected' do
              let(:response)  { 'Failure' }
              let(:uniqueid)  { '1235' }

              it 'should not send an end event' do
                expect(translator).to receive(:handle_pb_event).once.with an_instance_of(Adhearsion::Event::Asterisk::AMI)
                subject.process_ami_event ami_event
              end
            end

            context 'failed without ever having connected' do
              let(:response)  { 'Failure' }
              let(:uniqueid)  { '<null>' }

              it 'should send an error end event' do
                expected_end_event = Adhearsion::Event::End.new :reason         => :error,
                                                                :target_call_id => subject.id
                expect(translator).to receive(:handle_pb_event).with expected_end_event
                subject.process_ami_event ami_event
              end

              context "when the AMI event has a timestamp" do
                let :ami_event do
                  RubyAMI::Event.new 'OriginateResponse',
                    'Privilege'     => 'call,all',
                    'ActionID'      => '9d0c1aa4-5e3b-4cae-8aef-76a6119e2909',
                    'Response'      => response,
                    'Channel'       => 'SIP/15557654321',
                    'Context'       => '',
                    'Exten'         => '',
                    'Reason'        => '0',
                    'Uniqueid'      => uniqueid,
                    'CallerIDNum'   => 'sip:5551234567',
                    'CallerIDName'  => 'Bryan 100',
                    'Timestamp'     => '1393368380.572575'
                end

                it "should use the AMI timestamp for the Rayo event" do
                  expected_end_event = Adhearsion::Event::End.new reason: :error,
                                                                  target_call_id: subject.id,
                                                                  timestamp: DateTime.new(2014, 2, 25, 22, 46, 20)
                  expect(translator).to receive(:handle_pb_event).with expected_end_event

                  subject.process_ami_event ami_event
                end
              end
            end
          end

          context 'with a handler registered for a matching event' do
            let :ami_event do
              RubyAMI::Event.new 'DTMF',
                'Digit'     => '4',
                'Start'     => 'Yes',
                'End'       => 'No',
                'Uniqueid'  => "1320842458.8",
                'Channel'   => "SIP/1234-00000000"
            end

            let(:response) { double 'Response' }

            it 'should execute the handler' do
              expect(response).to receive(:call).once.with ami_event
              subject.register_handler :ami, :name => 'DTMF' do |event|
                response.call event
              end
              subject.process_ami_event ami_event
            end
          end

          context 'with a BridgeEnter event' do
            let(:bridge_uniqueid) { "1234-5678" }
            let(:call_channel) { "SIP/foo" }
            let :ami_event do
              RubyAMI::Event.new 'BridgeEnter',
                'Privilege' => "call,all",
                'BridgeUniqueid'  => bridge_uniqueid,
                'Channel'  => call_channel
            end

            context 'when the event is received the first time' do
              it 'sets an entry in translator.bridges' do
                subject.process_ami_event ami_event
                expect(translator.bridges[bridge_uniqueid]).to eq call_channel
              end
            end

            context 'when the event is received a second time for the same BridgeUniqueid' do
              let(:other_channel) { 'SIP/5678-00000000' }
              let :other_call do
                Call.new other_channel, translator, ami_client, connection
              end
              let(:other_call_id) { other_call.id }

              let :command do
                Adhearsion::Rayo::Command::Join.new call_uri: other_call_id
              end

              let :second_ami_event do
                RubyAMI::Event.new 'BridgeEnter',
                'Privilege' => "call,all",
                'BridgeUniqueid'  => bridge_uniqueid,
                'Channel'  => other_channel
              end

              let :expected_joined do
                Adhearsion::Event::Joined.new target_call_id: subject.id,
                  call_uri: other_call_id
              end

              let :expected_joined_other do
                Adhearsion::Event::Joined.new target_call_id: other_call_id,
                  call_uri: subject.id
              end

              before do
                translator.register_call subject
                translator.register_call other_call
                command.request!
                expect(subject).to receive(:execute_agi_command).and_return code: 200
                subject.execute_command command
                translator.handle_ami_event ami_event
              end

              it 'sends the correct Joined events' do
                expect(translator).to receive(:handle_pb_event).with expected_joined
                expect(translator).to receive(:handle_pb_event).with expected_joined_other
                translator.handle_ami_event second_ami_event
                expect(command.response(0.5)).to eq(true)
              end

              context 'out of order' do
                let :ami_event do
                  RubyAMI::Event.new 'BridgeEnter',
                  'Privilege' => "call,all",
                  'BridgeUniqueid'  => bridge_uniqueid,
                  'Channel'  => other_channel
                end

                let :second_ami_event do
                  RubyAMI::Event.new 'BridgeEnter',
                  'Privilege' => "call,all",
                  'BridgeUniqueid'  => bridge_uniqueid,
                  'Channel'  => call_channel
                end

                it 'sends the correct Joined events' do
                  expect(translator).to receive(:handle_pb_event).with expected_joined
                  expect(translator).to receive(:handle_pb_event).with expected_joined_other
                  translator.handle_ami_event second_ami_event
                  expect(command.response(0.5)).to eq(true)
                end
              end
            end
          end

          context 'with a BridgeLeave event' do
            let(:bridge_uniqueid) { "1234-5678" }
            let(:call_channel) { "SIP/foo" }
            let :ami_event do
              RubyAMI::Event.new 'BridgeLeave',
                'Privilege' => "call,all",
                'BridgeUniqueid'  => bridge_uniqueid,
                'Channel'  => call_channel
            end

            context 'when the event is received the first time' do
              it 'sets an entry in translator.bridges' do
                subject.process_ami_event ami_event
                expect(translator.bridges[bridge_uniqueid + '_leave']).to eq call_channel
              end
            end

            context 'when the event is received a second time for the same BridgeUniqueid' do
              let(:other_channel) { 'SIP/5678-00000000' }
              let :other_call do
                Call.new other_channel, translator, ami_client, connection
              end
              let(:other_call_id) { other_call.id }

              let :second_ami_event do
                RubyAMI::Event.new 'BridgeLeave',
                'Privilege' => "call,all",
                'BridgeUniqueid'  => bridge_uniqueid,
                'Channel'  => other_channel
              end

              let :expected_unjoined do
                Adhearsion::Event::Unjoined.new target_call_id: subject.id,
                  call_uri: other_call_id
              end

              let :expected_unjoined_other do
                Adhearsion::Event::Unjoined.new target_call_id: other_call_id,
                  call_uri: subject.id
              end

              before do
                translator.register_call subject
                translator.register_call other_call
                translator.handle_ami_event ami_event
              end

              it 'sends the correct Unjoined events' do
                expect(translator).to receive(:handle_pb_event).with expected_unjoined
                expect(translator).to receive(:handle_pb_event).with expected_unjoined_other
                translator.handle_ami_event second_ami_event
              end

              context 'out of order' do
                let :ami_event do
                  RubyAMI::Event.new 'BridgeLeave',
                  'Privilege' => "call,all",
                  'BridgeUniqueid'  => bridge_uniqueid,
                  'Channel'  => other_channel
                end

                let :second_ami_event do
                  RubyAMI::Event.new 'BridgeLeave',
                  'Privilege' => "call,all",
                  'BridgeUniqueid'  => bridge_uniqueid,
                  'Channel'  => call_channel
                end

                it 'sends the correct Unjoined events' do
                  expect(translator).to receive(:handle_pb_event).with expected_unjoined
                  expect(translator).to receive(:handle_pb_event).with expected_unjoined_other
                  translator.handle_ami_event second_ami_event
                end
              end
            end
          end

          context 'with a BridgeExec event' do
            let :ami_event do
              RubyAMI::Event.new 'BridgeExec',
                'Privilege' => "call,all",
                'Response'  => "Success",
                'Channel1'  => "SIP/foo",
                'Channel2'  => other_channel
            end

            let(:other_channel) { 'SIP/5678-00000000' }

            context "when a join has been executed against another call" do
              let :other_call do
                Call.new other_channel, translator, ami_client, connection
              end

              let(:other_call_id) { other_call.id }
              let :command do
                Adhearsion::Rayo::Command::Join.new call_uri: other_call_id
              end

              before do
                translator.register_call other_call
                command.request!
                expect(subject).to receive(:execute_agi_command).and_return code: 200
                subject.execute_command command
              end

              it 'retrieves and sets success on the correct Join' do
                subject.process_ami_event ami_event
                expect(command.response(0.5)).to eq(true)
              end

              context "with the channel names reversed" do
                let :ami_event do
                  RubyAMI::Event.new 'BridgeExec',
                    'Privilege' => "call,all",
                    'Response'  => "Success",
                    'Channel1'  => other_channel,
                    'Channel2'  => "SIP/foo"
                end

                it 'retrieves and sets success on the correct Join' do
                  subject.process_ami_event ami_event
                  expect(command.response(0.5)).to eq(true)
                end
              end
            end

            context "with no matching join command" do
              it "should do nothing" do
                expect { subject.process_ami_event ami_event }.not_to raise_error
              end
            end
          end

          context 'with a Bridge event' do
            let(:other_channel) { 'SIP/5678-00000000' }
            let :other_call do
              Call.new other_channel, translator, ami_client, connection
            end
            let(:other_call_id) { other_call.id }

            let :ami_event do
              RubyAMI::Event.new 'Bridge',
                'Privilege'   => "call,all",
                'Bridgestate' => state,
                'Bridgetype'  => "core",
                'Channel1'    => channel,
                'Channel2'    => other_channel,
                'Uniqueid1'   => "1319717537.11",
                'Uniqueid2'   => "1319717537.10",
                'CallerID1'   => "1234",
                'CallerID2'   => "5678"
            end

            let :switched_ami_event do
              RubyAMI::Event.new 'Bridge',
                'Privilege'   => "call,all",
                'Bridgestate' => state,
                'Bridgetype'  => "core",
                'Channel1'    => other_channel,
                'Channel2'    => channel,
                'Uniqueid1'   => "1319717537.11",
                'Uniqueid2'   => "1319717537.10",
                'CallerID1'   => "1234",
                'CallerID2'   => "5678"
            end

            before do
              translator.register_call other_call
              expect(translator).to receive(:call_for_channel).with(other_channel).and_return(other_call)
            end

            context "of state 'Link'" do
              let(:state) { 'Link' }

              let :expected_joined do
                Adhearsion::Event::Joined.new target_call_id: subject.id,
                  call_uri: other_call_id
              end

              it 'sends the Joined event when the call is the first channel' do
                expect(translator).to receive(:handle_pb_event).with expected_joined
                subject.process_ami_event ami_event
              end

              it 'sends the Joined event when the call is the second channel' do
                expect(translator).to receive(:handle_pb_event).with expected_joined
                subject.process_ami_event switched_ami_event
              end

              context "when the AMI event has a timestamp" do
                let :ami_event do
                  RubyAMI::Event.new 'Bridge',
                    'Privilege'   => "call,all",
                    'Bridgestate' => state,
                    'Bridgetype'  => "core",
                    'Channel1'    => channel,
                    'Channel2'    => other_channel,
                    'Uniqueid1'   => "1319717537.11",
                    'Uniqueid2'   => "1319717537.10",
                    'CallerID1'   => "1234",
                    'CallerID2'   => "5678",
                    'Timestamp'   => '1393368380.572575'
                end

                let :switched_ami_event do
                  RubyAMI::Event.new 'Bridge',
                    'Privilege'   => "call,all",
                    'Bridgestate' => state,
                    'Bridgetype'  => "core",
                    'Channel1'    => other_channel,
                    'Channel2'    => channel,
                    'Uniqueid1'   => "1319717537.11",
                    'Uniqueid2'   => "1319717537.10",
                    'CallerID1'   => "1234",
                    'CallerID2'   => "5678",
                    'Timestamp'   => '1393368380.572575'
                end

                before { expected_joined.timestamp = DateTime.new(2014, 2, 25, 22, 46, 20) }

                context "when the call is the first channel" do
                  it "should use the AMI timestamp for the Rayo event" do
                    expect(translator).to receive(:handle_pb_event).with expected_joined

                    subject.process_ami_event ami_event
                  end
                end

                context "when the call is the second channel" do
                  it "should use the AMI timestamp for the Rayo event" do
                    expect(translator).to receive(:handle_pb_event).with expected_joined

                    subject.process_ami_event switched_ami_event
                  end
                end
              end
            end

            context "of state 'Unlink'" do
              let(:state) { 'Unlink' }

              let :expected_unjoined do
                Adhearsion::Event::Unjoined.new target_call_id: subject.id,
                  call_uri: other_call_id
              end

              it 'sends the Unjoined event when the call is the first channel' do
                expect(translator).to receive(:handle_pb_event).with expected_unjoined
                subject.process_ami_event ami_event
              end

              it 'sends the Unjoined event when the call is the second channel' do
                expect(translator).to receive(:handle_pb_event).with expected_unjoined
                subject.process_ami_event switched_ami_event
              end

              context "when the AMI event has a timestamp" do
                let :ami_event do
                  RubyAMI::Event.new 'Bridge',
                    'Privilege'   => "call,all",
                    'Bridgestate' => state,
                    'Bridgetype'  => "core",
                    'Channel1'    => channel,
                    'Channel2'    => other_channel,
                    'Uniqueid1'   => "1319717537.11",
                    'Uniqueid2'   => "1319717537.10",
                    'CallerID1'   => "1234",
                    'CallerID2'   => "5678",
                    'Timestamp'   => '1393368380.572575'
                end

                let :switched_ami_event do
                  RubyAMI::Event.new 'Bridge',
                    'Privilege'   => "call,all",
                    'Bridgestate' => state,
                    'Bridgetype'  => "core",
                    'Channel1'    => other_channel,
                    'Channel2'    => channel,
                    'Uniqueid1'   => "1319717537.11",
                    'Uniqueid2'   => "1319717537.10",
                    'CallerID1'   => "1234",
                    'CallerID2'   => "5678",
                    'Timestamp'   => '1393368380.572575'
                end

                before { expected_unjoined.timestamp = DateTime.new(2014, 2, 25, 22, 46, 20) }

                context "when the call is the first channel" do
                  it "should use the AMI timestamp for the Rayo event" do
                    expect(translator).to receive(:handle_pb_event).with expected_unjoined

                    subject.process_ami_event ami_event
                  end
                end

                context "when the call is the second channel" do
                  it "should use the AMI timestamp for the Rayo event" do
                    expect(translator).to receive(:handle_pb_event).with expected_unjoined

                    subject.process_ami_event switched_ami_event
                  end
                end
              end
            end
          end

          context 'with an Unlink event' do
            let(:other_channel) { 'SIP/5678-00000000' }
            let(:other_call_id) { 'def567' }
            let :other_call do
              Call.new other_channel, translator, ami_client, connection
            end

            let :ami_event do
              RubyAMI::Event.new 'Unlink',
                'Privilege' => "call,all",
                'Channel1'  => channel,
                'Channel2'  => other_channel,
                'Uniqueid1' => "1319717537.11",
                'Uniqueid2' => "1319717537.10",
                'CallerID1' => "1234",
                'CallerID2' => "5678"
            end

            let :switched_ami_event do
              RubyAMI::Event.new 'Unlink',
                'Privilege' => "call,all",
                'Channel1'  => other_channel,
                'Channel2'  => channel,
                'Uniqueid1' => "1319717537.11",
                'Uniqueid2' => "1319717537.10",
                'CallerID1' => "1234",
                'CallerID2' => "5678"
            end

            before do
              translator.register_call other_call
              expect(translator).to receive(:call_for_channel).with(other_channel).and_return(other_call)
              expect(other_call).to receive(:id).and_return other_call_id
            end

            let :expected_unjoined do
              Adhearsion::Event::Unjoined.new target_call_id: subject.id,
                call_uri: other_call_id
            end

            it 'sends the Unjoined event when the call is the first channel' do
              expect(translator).to receive(:handle_pb_event).with expected_unjoined
              subject.process_ami_event ami_event
            end

            it 'sends the Unjoined event when the call is the second channel' do
              expect(translator).to receive(:handle_pb_event).with expected_unjoined
              subject.process_ami_event switched_ami_event
            end

            context "when the AMI event has a timestamp" do
              let :ami_event do
                RubyAMI::Event.new 'Unlink',
                  'Privilege' => "call,all",
                  'Channel1'  => channel,
                  'Channel2'  => other_channel,
                  'Uniqueid1' => "1319717537.11",
                  'Uniqueid2' => "1319717537.10",
                  'CallerID1' => "1234",
                  'CallerID2' => "5678",
                  'Timestamp'   => '1393368380.572575'
              end

              let :switched_ami_event do
                RubyAMI::Event.new 'Unlink',
                  'Privilege' => "call,all",
                  'Channel1'  => other_channel,
                  'Channel2'  => channel,
                  'Uniqueid1' => "1319717537.11",
                  'Uniqueid2' => "1319717537.10",
                  'CallerID1' => "1234",
                  'CallerID2' => "5678",
                  'Timestamp'   => '1393368380.572575'
              end

              before { expected_unjoined.timestamp = DateTime.new(2014, 2, 25, 22, 46, 20) }

              context "when the call is the first channel" do
                it "should use the AMI timestamp for the Rayo event" do
                  expect(translator).to receive(:handle_pb_event).with expected_unjoined

                  subject.process_ami_event ami_event
                end
              end

              context "when the call is the second channel" do
                it "should use the AMI timestamp for the Rayo event" do
                  expect(translator).to receive(:handle_pb_event).with expected_unjoined

                  subject.process_ami_event switched_ami_event
                end
              end
            end
          end

          context 'with a VarSet event' do
            let :ami_event do
              RubyAMI::Event.new 'VarSet',
                "Privilege" => "dialplan,all",
                "Channel"   => "SIP/1234-00000000",
                "Variable"  => "foobar",
                "Value"     => 'abc123',
                "Uniqueid"  => "1326210224.0"
            end

            it 'makes the variable accessible on the call' do
              subject.process_ami_event ami_event
              expect(subject.channel_var('foobar')).to eq('abc123')
            end
          end

          let :ami_event do
            RubyAMI::Event.new 'Foo',
              'Uniqueid'      => "1320842458.8",
              'Calleridnum'   => "5678",
              'Calleridname'  => "Jane Smith",
              'Cause'         => "0",
              'Cause-txt'     => "Unknown",
              'Channel'       => channel
          end

          let :expected_pb_event do
            Adhearsion::Event::Asterisk::AMI.new name: 'Foo',
                                            headers: { 'Channel'      => channel,
                                                       'Uniqueid'     => "1320842458.8",
                                                       'Calleridnum'  => "5678",
                                                       'Calleridname' => "Jane Smith",
                                                       'Cause'        => "0",
                                                       'Cause-txt'    => "Unknown"},
                                            target_call_id: subject.id
          end

          it 'sends the AMI event to the connection as a PB event' do
            expect(translator).to receive(:handle_pb_event).with expected_pb_event
            subject.process_ami_event ami_event
          end

          context "when the event doesn't pass the filter" do
            before { Asterisk.event_filter = ->(event) { false } }
            after { Asterisk.event_filter = nil }

            it 'does not send the AMI event to the connection as a PB event' do
              expect(translator).to receive(:handle_pb_event).never
              subject.process_ami_event ami_event
            end
          end
        end

        describe '#send_message' do
          let(:body) { 'Hello world' }

          it "should invoke SendText" do
            expect(subject).to receive(:execute_agi_command).with('EXEC SendText', body).and_return code: 200
            subject.send_message body
          end

          context "when an AMI error is received" do
            it "is silently ignored" do
              expect(subject).to receive(:execute_agi_command).with('EXEC SendText', body).and_raise RubyAMI::Error.new.tap { |e| e.message = 'Call not found' }
              subject.send_message body
            end
          end
        end

        describe '#execute_command' do
          before do
            command.request!
          end

          context 'with an accept command' do
            let(:command) { Adhearsion::Rayo::Command::Accept.new }

            it "should send an EXEC RINGING AGI command and set the command's response" do
              expect(subject).to receive(:execute_agi_command).with('EXEC RINGING').and_return code: 200
              subject.execute_command command
              expect(command.response(0.5)).to be true
            end

            context "when the AMI commannd raises an error" do
              let(:message) { 'Some error' }
              let(:error)   { RubyAMI::Error.new.tap { |e| e.message = message } }

              before { expect(subject).to receive(:execute_agi_command).and_raise error }

              it "should return an error with the message" do
                subject.execute_command command
                expect(command.response(0.5)).to eq(Adhearsion::ProtocolError.new.setup('error', message, subject.id))
              end

              context "because the channel is gone" do
                let(:error) { ChannelGoneError }

                it "should return an :item_not_found event for the call" do
                  subject.execute_command command
                  expect(command.response(0.5)).to eq(Adhearsion::ProtocolError.new.setup(:item_not_found, "Could not find a call with ID #{subject.id}", subject.id))
                end
              end
            end
          end

          context 'with a redirect command' do
            let(:command) { Adhearsion::Rayo::Command::Redirect.new to: 'other@place.com' }

            let(:transferstatus) { 'SUCCESS' }
            let :status_event do
              RubyAMI::Event.new 'VarSet',
                "Privilege" => "dialplan,all",
                "Channel"   => "SIP/1234-00000000",
                "Variable"  => "TRANSFERSTATUS",
                "Value"     => transferstatus,
                "Uniqueid"  => "1326210224.0"
            end

            before do
              subject.process_ami_event status_event
            end

            it "should send an EXEC Transfer AGI command" do
              expect(subject).to receive(:execute_agi_command).with('EXEC Transfer', 'other@place.com').and_return code: 200
              subject.execute_command command
              expect(command.response(0.5)).to be true
            end

            context "when TRANSFERSTATUS is 'FAILURE'" do
              let(:transferstatus) { 'FAILURE' }

              it "should return an error" do
                expect(subject).to receive(:execute_agi_command).with('EXEC Transfer', 'other@place.com').and_return code: 200
                subject.execute_command command
                expect(command.response(0.5)).to eq(Adhearsion::ProtocolError.new.setup('error', 'TRANSFERSTATUS was FAILURE', subject.id))
              end
            end

            context "when TRANSFERSTATUS is 'UNSUPPORTED'" do
              let(:transferstatus) { 'UNSUPPORTED' }

              it "should return an error" do
                expect(subject).to receive(:execute_agi_command).with('EXEC Transfer', 'other@place.com').and_return code: 200
                subject.execute_command command
                expect(command.response(0.5)).to eq(Adhearsion::ProtocolError.new.setup('error', 'TRANSFERSTATUS was UNSUPPORTED', subject.id))
              end
            end

            context "when the AMI commannd raises an error" do
              let(:message) { 'Some error' }
              let(:error)   { RubyAMI::Error.new.tap { |e| e.message = message } }

              before { expect(subject).to receive(:execute_agi_command).and_raise error }

              it "should return an error with the message" do
                subject.execute_command command
                expect(command.response(0.5)).to eq(Adhearsion::ProtocolError.new.setup('error', message, subject.id))
              end

              context "because the channel is gone" do
                let(:error) { ChannelGoneError }

                it "should return an :item_not_found event for the call" do
                  subject.execute_command command
                  expect(command.response(0.5)).to eq(Adhearsion::ProtocolError.new.setup(:item_not_found, "Could not find a call with ID #{subject.id}", subject.id))
                end
              end
            end
          end

          context 'with a reject command' do
            let(:command) { Adhearsion::Rayo::Command::Reject.new }

            it "with a :busy reason should send an EXEC Busy AGI command and set the command's response" do
              command.reason = :busy
              expect(subject).to receive(:execute_agi_command).with('EXEC Busy').and_return code: 200
              subject.execute_command command
              expect(command.response(0.5)).to be true
            end

            it "with a :decline reason should send a Hangup AMI command (cause 21) and set the command's response" do
              command.reason = :decline
              expect(ami_client).to receive(:send_action).once.with('Hangup', Hash('Channel' => channel, 'Cause' => 21)).and_return RubyAMI::Response.new
              subject.execute_command command
              expect(command.response(0.5)).to be true
            end

            it "with an :error reason should send an EXEC Congestion AGI command and set the command's response" do
              command.reason = :error
              expect(subject).to receive(:execute_agi_command).with('EXEC Congestion').and_return code: 200
              subject.execute_command command
              expect(command.response(0.5)).to be true
            end

            context "when the AMI commannd raises an error" do
              let(:message) { 'Some error' }
              let(:error)   { RubyAMI::Error.new.tap { |e| e.message = message } }

              before { expect(subject).to receive(:execute_agi_command).and_raise error }

              it "should return an error with the message" do
                subject.execute_command command
                expect(command.response(0.5)).to eq(Adhearsion::ProtocolError.new.setup('error', message, subject.id))
              end

              context "because the channel is gone" do
                let(:error) { ChannelGoneError }

                it "should return an :item_not_found event for the call" do
                  subject.execute_command command
                  expect(command.response(0.5)).to eq(Adhearsion::ProtocolError.new.setup(:item_not_found, "Could not find a call with ID #{subject.id}", subject.id))
                end
              end
            end
          end

          context 'with an answer command' do
            let(:command) { Adhearsion::Rayo::Command::Answer.new }

            it "should send an ANSWER AGI command and set the command's response" do
              expect(subject).to receive(:execute_agi_command).with('ANSWER').and_return code: 200
              subject.execute_command command
              expect(command.response(0.5)).to be true
            end

            it "should be answered" do
              expect(subject).to receive(:execute_agi_command)
              subject.execute_command command
              expect(subject).to be_answered
            end

            context "when the AMI command raises an error" do
              let(:message) { 'Some error' }
              let(:error)   { RubyAMI::Error.new.tap { |e| e.message = message } }

              before { expect(subject).to receive(:execute_agi_command).and_raise error }

              it "should return an error with the message" do
                subject.execute_command command
                expect(command.response(0.5)).to eq(Adhearsion::ProtocolError.new.setup('error', message, subject.id))
              end

              it "should not be answered" do
                subject.execute_command command
                expect(subject).not_to be_answered
              end

              context "because the channel is gone" do
                let(:error) { ChannelGoneError }

                it "should return an :item_not_found event for the call" do
                  subject.execute_command command
                  expect(command.response(0.5)).to eq(Adhearsion::ProtocolError.new.setup(:item_not_found, "Could not find a call with ID #{subject.id}", subject.id))
                end
              end
            end
          end

          context 'with a hangup command' do
            let(:command) { Adhearsion::Rayo::Command::Hangup.new }

            it "should send a Hangup AMI command and set the command's response" do
              expect(ami_client).to receive(:send_action).once.with('Hangup', Hash('Channel' => channel, 'Cause' => 16)).and_return RubyAMI::Response.new
              subject.execute_command command
              expect(command.response(0.5)).to be true
            end

            context "when the AMI commannd raises an error" do
              let(:message) { 'Some error' }
              let(:error)   { RubyAMI::Error.new.tap { |e| e.message = message } }

              before { expect(ami_client).to receive(:send_action).and_raise error }

              it "should return an error with the message" do
                subject.execute_command command
                expect(command.response(0.5)).to eq(Adhearsion::ProtocolError.new.setup('error', message, subject.id))
              end

              context "which is 'No such channel'" do
                let(:message) { 'No such channel' }

                it "should return an :item_not_found event for the call" do
                  subject.execute_command command
                  expect(command.response(0.5)).to eq(Adhearsion::ProtocolError.new.setup(:item_not_found, "Could not find a call with ID #{subject.id}", subject.id))
                end
              end

              context "which is 'Channel SIP/nosuchchannel does not exist.'" do
                let(:message) { 'Channel SIP/nosuchchannel does not exist.' }

                it "should return an :item_not_found event for the call" do
                  subject.execute_command command
                  expect(command.response(0.5)).to eq(Adhearsion::ProtocolError.new.setup(:item_not_found, "Could not find a call with ID #{subject.id}", subject.id))
                end
              end

              context "which is 'Channel does not exist: SIP/nosuchchannel'" do
                let(:message) { 'Channel does not exist: SIP/nosuchchannel' }

                it "should return an :item_not_found event for the call" do
                  subject.execute_command command
                  expect(command.response(0.5)).to eq(Adhearsion::ProtocolError.new.setup(:item_not_found, "Could not find a call with ID #{subject.id}", subject.id))
                end
              end

              context "which is 'ExtraChannel does not exist: SIP/nosuchchannel'" do
                let(:message) { 'ExtraChannel does not exist: SIP/nosuchchannel' }

                it "should return an :item_not_found event for the call" do
                  subject.execute_command command
                  expect(command.response(0.5)).to eq(Adhearsion::ProtocolError.new.setup(:item_not_found, "Could not find a call with ID #{subject.id}", subject.id))
                end
              end

              context "which is 'Redirect failed, channel not up.'" do
                let(:message) { 'Redirect failed, channel not up.' }

                it "should return an :item_not_found event for the call" do
                  subject.execute_command command
                  expect(command.response(0.5)).to eq(Adhearsion::ProtocolError.new.setup(:item_not_found, "Could not find a call with ID #{subject.id}", subject.id))
                end
              end

              context "which is 'Redirect failed, channel not up.'" do
                let(:message) { 'Redirect failed, extra channel not up.' }

                it "should return an :item_not_found event for the call" do
                  subject.execute_command command
                  expect(command.response(0.5)).to eq(Adhearsion::ProtocolError.new.setup(:item_not_found, "Could not find a call with ID #{subject.id}", subject.id))
                end
              end
            end
          end

          context "with a join command" do
            let(:other_call_id)     { "abc123" }
            let(:other_channel)     { 'SIP/bar' }
            let(:other_translator)  { double('Translator::Asterisk').as_null_object }

            let :other_call do
              Call.new other_channel, other_translator, ami_client, connection
            end

            let :command do
              Adhearsion::Rayo::Command::Join.new call_uri: other_call_id
            end

            before { expect(translator).to receive(:call_with_id).with(other_call_id).and_return(other_call) }

            it "executes the proper dialplan Bridge application" do
              expect(subject).to receive(:execute_agi_command).with('EXEC Bridge', "#{other_channel},F(#{REDIRECT_CONTEXT},#{REDIRECT_EXTENSION},#{REDIRECT_PRIORITY})").and_return code: 200
              subject.execute_command command
            end

            context "when the other call doesn't exist" do
              let(:other_call) { nil }

              it "returns an error" do
                subject.execute_command command
                expect(command.response(0.5)).to eq(Adhearsion::ProtocolError.new.setup(:service_unavailable, "Could not find join party with address #{other_call_id}", subject.id))
              end
            end

            context "when the AMI command raises an error" do
              let(:message) { 'Some error' }
              let(:error)   { RubyAMI::Error.new.tap { |e| e.message = message } }

              before { expect(subject).to receive(:execute_agi_command).and_raise error }

              it "should return an error with the message" do
                subject.execute_command command
                expect(command.response(0.5)).to eq(Adhearsion::ProtocolError.new.setup('error', message, subject.id))
              end

              it "should not be answered" do
                subject.execute_command command
                expect(subject).not_to be_answered
              end

              context "because the channel is gone" do
                let(:error) { ChannelGoneError }

                it "should return an :item_not_found event for the call" do
                  subject.execute_command command
                  expect(command.response(0.5)).to eq(Adhearsion::ProtocolError.new.setup(:item_not_found, "Could not find a call with ID #{subject.id}", subject.id))
                end
              end
            end
          end

          context "with an unjoin command" do
            let(:other_call_id) { "abc123" }
            let(:other_channel) { 'SIP/bar' }

            let :other_call do
              Call.new other_channel, translator, ami_client, connection
            end

            let :command do
              Adhearsion::Rayo::Command::Unjoin.new call_uri: other_call_id
            end

            it "executes the unjoin through redirection" do
              expect(translator).to receive(:call_with_id).with(other_call_id).and_return(nil)

              expect(ami_client).to receive(:send_action).once.with(
                "Redirect",
                Hash(
                  'Channel'   => channel,
                  'Exten'     => Translator::Asterisk::REDIRECT_EXTENSION,
                  'Priority'  => Translator::Asterisk::REDIRECT_PRIORITY,
                  'Context'   => Translator::Asterisk::REDIRECT_CONTEXT
                )
              ).and_return RubyAMI::Response.new

              subject.execute_command command

              expect(command.response(1)).to be_truthy
            end

            it "executes the unjoin through redirection, on the subject call and the other call" do
              expect(translator).to receive(:call_with_id).with(other_call_id).and_return(other_call)

              expect(ami_client).to receive(:send_action).once.with(
                "Redirect",
                Hash(
                  'Channel'       => channel,
                  'Exten'         => Translator::Asterisk::REDIRECT_EXTENSION,
                  'Priority'      => Translator::Asterisk::REDIRECT_PRIORITY,
                  'Context'       => Translator::Asterisk::REDIRECT_CONTEXT,
                  'ExtraChannel'  => other_channel,
                  'ExtraExten'    => Translator::Asterisk::REDIRECT_EXTENSION,
                  'ExtraPriority' => Translator::Asterisk::REDIRECT_PRIORITY,
                  'ExtraContext'  => Translator::Asterisk::REDIRECT_CONTEXT
                )
              ).and_return RubyAMI::Response.new

              subject.execute_command command
            end

            context "when the AMI commannd raises an error" do
              let(:message) { 'Some error' }
              let(:error)   { RubyAMI::Error.new.tap { |e| e.message = message } }

              before do
                expect(translator).to receive(:call_with_id).with(other_call_id).and_return(nil)
                expect(ami_client).to receive(:send_action).and_raise error
              end

              it "should return an error with the message" do
                subject.execute_command command
                expect(command.response(0.5)).to eq(Adhearsion::ProtocolError.new.setup('error', message, subject.id))
              end

              context "which is 'No such channel'" do
                let(:message) { 'No such channel' }

                it "should return an :item_not_found event for the call" do
                  subject.execute_command command
                  expect(command.response(0.5)).to eq(Adhearsion::ProtocolError.new.setup(:item_not_found, "Could not find a call with ID #{subject.id}", subject.id))
                end
              end

              context "which is 'Channel SIP/nosuchchannel does not exist.'" do
                let(:message) { 'Channel SIP/nosuchchannel does not exist.' }

                it "should return an :item_not_found event for the call" do
                  subject.execute_command command
                  expect(command.response(0.5)).to eq(Adhearsion::ProtocolError.new.setup(:item_not_found, "Could not find a call with ID #{subject.id}", subject.id))
                end
              end
            end
          end

          context 'with an AGI command component' do
            let :command do
              Adhearsion::Rayo::Component::Asterisk::AGI::Command.new :name => 'Answer'
            end

            it 'should create an AGI command component actor and execute it asynchronously' do
              mock_action = Translator::Asterisk::Component::Asterisk::AGICommand.new(command, subject)
              expect(Component::Asterisk::AGICommand).to receive(:new).once.with(command, subject).and_return mock_action
              expect(mock_action).to receive(:execute).once
              subject.execute_command command
            end
          end

          context 'with an Output component' do
            let :command do
              Adhearsion::Rayo::Component::Output.new
            end

            it 'should create an Output component and execute it asynchronously' do
              mock_action = Translator::Asterisk::Component::Output.new(command, subject)
              expect(Component::Output).to receive(:new).once.with(command, subject).and_return mock_action
              expect(mock_action).to receive(:execute).once
              subject.execute_command command
            end
          end

          context 'with an Input component' do
            let :command do
              Adhearsion::Rayo::Component::Input.new
            end

            it 'should create an Input component and execute it asynchronously' do
              mock_action = Translator::Asterisk::Component::Input.new(command, subject)
              expect(Component::Input).to receive(:new).once.with(command, subject).and_return mock_action
              expect(mock_action).to receive(:execute).once
              subject.execute_command command
            end
          end

          context 'with a Prompt component' do
            def grxml_doc(mode = :dtmf)
              RubySpeech::GRXML.draw :mode => mode.to_s, :root => 'digits' do
                rule id: 'digits' do
                  one_of do
                    0.upto(1) { |d| item { d.to_s } }
                  end
                end
              end
            end

            let :command do
              Adhearsion::Rayo::Component::Prompt.new(
                {
                  render_document: {
                    content_type: 'text/uri-list',
                    value: ['http://example.com/hello.mp3']
                  },
                  renderer: renderer
                },
                {
                  grammar: {
                    value: grxml_doc,
                    content_type: 'application/srgs+xml'
                  },
                  recognizer: recognizer
                })
            end

            let(:mock_action) { Translator::Asterisk::Component::MRCPPrompt.new(command, subject) }

            before { mock_action}

            context "when the recognizer is unimrcp and the renderer is unimrcp" do
              let(:recognizer)  { :unimrcp }
              let(:renderer)    { :unimrcp }

              it 'should create an MRCPPrompt component and execute it asynchronously' do
                expect(Component::MRCPPrompt).to receive(:new).once.with(command, subject).and_return mock_action
                expect(mock_action).to receive(:execute).once
                subject.execute_command command
              end
            end

            context "when the recognizer is unimrcp and the renderer is asterisk" do
              let(:recognizer)  { :unimrcp }
              let(:renderer)    { :asterisk }

              it 'should create an MRCPPrompt component and execute it asynchronously' do
                expect(Component::MRCPNativePrompt).to receive(:new).once.with(command, subject).and_return mock_action
                expect(mock_action).to receive(:execute).once
                subject.execute_command command
              end
            end

            context "when the recognizer is unimrcp and the renderer is something we can't compose with unimrcp" do
              let(:recognizer)  { :unimrcp }
              let(:renderer)    { :swift }

              it 'should return an error' do
                subject.execute_command command
                expect(command.response(0.5)).to eq(Adhearsion::ProtocolError.new.setup(:invalid_command, "Invalid recognizer/renderer combination", subject.id))
              end
            end

            context "when the recognizer is something other than unimrcp" do
              let(:recognizer)  { :asterisk }
              let(:renderer)    { :unimrcp }

              it 'should create a ComposedPrompt component and execute it asynchronously' do
                expect(Component::ComposedPrompt).to receive(:new).once.with(command, subject).and_return mock_action
                expect(mock_action).to receive(:execute).once
                subject.execute_command command
              end
            end
          end

          context 'with a Record component' do
            let :command do
              Adhearsion::Rayo::Component::Record.new
            end

            it 'should create a Record component and execute it asynchronously' do
              mock_action = Translator::Asterisk::Component::Record.new(command, subject)
              expect(Component::Record).to receive(:new).once.with(command, subject).and_return mock_action
              expect(mock_action).to receive(:execute).once
              subject.execute_command command
            end
          end

          context 'with a component command' do
            let(:component_id) { 'foobar' }

            let :command do
              Adhearsion::Rayo::Component::Stop.new :component_id => component_id
            end

            let :mock_component do
              double 'Component', :id => component_id
            end

            context "for a known component ID" do
              before { subject.register_component mock_component }

              it 'should send the command to the component for execution' do
                expect(mock_component).to receive(:execute_command).once
                subject.execute_command command
              end
            end

            context "for a component which began executing but terminated" do
              let :component_command do
                Adhearsion::Rayo::Component::Asterisk::AGI::Command.new :name => 'Wait'
              end

              let(:comp_id) { component_command.response.component_id }

              let(:subsequent_command) { Adhearsion::Rayo::Component::Stop.new :component_id => comp_id }

              let :expected_event do
                Adhearsion::Event::Complete.new target_call_id: subject.id,
                  component_id: comp_id,
                  source_uri: comp_id,
                  reason: Adhearsion::Event::Complete::Error.new
              end

              before do
                component_command.request!
                subject.execute_command component_command
              end

              context "normally" do
                it 'sends an error in response to the command' do
                  component = subject.component_with_id comp_id

                  component.send_complete_event Adhearsion::Rayo::Component::Asterisk::AGI::Command::Complete.new

                  expect(subject.component_with_id(comp_id)).to be_nil

                  subsequent_command.request!
                  subject.execute_command subsequent_command
                  expect(subsequent_command.response).to eq(Adhearsion::ProtocolError.new.setup(:item_not_found, "Could not find a component with ID #{comp_id} for call #{subject.id}", subject.id, comp_id))
                end
              end

              context "by crashing" do
                context "when we dispatch the command to it" do
                  it 'sends an error in response to the command' do
                    component = subject.component_with_id comp_id

                    expect(component).to receive(:execute_command).and_raise(Celluloid::DeadActorError)

                    subsequent_command.request!
                    subject.execute_command subsequent_command
                    expect(subsequent_command.response).to eq(Adhearsion::ProtocolError.new.setup(:item_not_found, "Could not find a component with ID #{comp_id} for call #{subject.id}", subject.id, comp_id))
                  end
                end
              end
            end

            context "for an unknown component ID" do
              it 'sends an error in response to the command' do
                subject.execute_command command
                expect(command.response).to eq(Adhearsion::ProtocolError.new.setup(:item_not_found, "Could not find a component with ID #{component_id} for call #{subject.id}", subject.id, component_id))
              end
            end
          end

          context 'with a command we do not understand' do
            let :command do
              Adhearsion::Rayo::Command::Mute.new
            end

            it 'sends an error in response to the command' do
              subject.execute_command command
              expect(command.response).to eq(Adhearsion::ProtocolError.new.setup('command-not-acceptable', "Did not understand command for call #{subject.id}", subject.id))
            end
          end
        end#execute_command

        describe '#execute_agi_command' do
          before { stub_uuids Adhearsion.new_uuid }

          let :response do
            RubyAMI::Response.new 'ActionID' => "552a9d9f-46d7-45d8-a257-06fe95f48d99",
              'Message' => 'Added AGI original_command to queue'
          end

          context 'with an error' do
            let(:message) { 'Action failed' }

            let :error do
              RubyAMI::Error.new.tap { |e| e.message = message }
            end

            it 'should raise the error' do
              expect(ami_client).to receive(:send_action).once.and_raise error
              expect { subject.execute_agi_command 'EXEC ANSWER' }.to raise_error(RubyAMI::Error, 'Action failed')
            end

            context "which is 'No such channel'" do
              let(:message) { 'No such channel' }

              it 'should raise ChannelGoneError' do
                expect(ami_client).to receive(:send_action).once.and_raise error
                expect { subject.execute_agi_command 'EXEC ANSWER' }.to raise_error(ChannelGoneError, message)
              end
            end

            context "which is 'Channel SIP/nosuchchannel does not exist.'" do
              let(:message) { 'Channel SIP/nosuchchannel does not exist.' }

              it 'should raise ChannelGoneError' do
                expect(ami_client).to receive(:send_action).once.and_raise error
                expect { subject.execute_agi_command 'EXEC ANSWER' }.to raise_error(ChannelGoneError, message)
              end
            end
          end

          describe 'when receiving an AsyncAGI event' do
            context 'of type Exec' do
              let(:ami_event) do
                RubyAMI::Event.new 'AsyncAGI',
                  "SubEvent"   => "Exec",
                  "Channel"    => channel,
                  "CommandID"  => Adhearsion.new_uuid,
                  "Command"    => "EXEC ANSWER",
                  "Result"     => "200%20result=123%20(timeout)%0A"
              end

              it 'should send an appropriate AsyncAGI AMI action' do
                expect(ami_client).to receive(:send_action).once.with('AGI', 'Channel' => channel, 'Command' => 'EXEC ANSWER', 'CommandID' => Adhearsion.new_uuid).and_return(response)
                fut = Celluloid::Future.new { subject.execute_agi_command 'EXEC ANSWER' }
                sleep 0.25
                subject.process_ami_event ami_event
              end

              context 'with some parameters' do
                let(:params) { [1000, 'foo'] }

                it 'should send the appropriate action' do
                  expect(ami_client).to receive(:send_action).once.with('AGI', 'Channel' => channel, 'Command' => 'WAIT FOR DIGIT "1000" "foo"', 'CommandID' => Adhearsion.new_uuid).and_return(response)
                  fut = Celluloid::Future.new { subject.execute_agi_command 'WAIT FOR DIGIT', *params }
                  sleep 0.25
                  subject.process_ami_event ami_event
                end
              end

              it 'should return the result' do
                fut = Celluloid::Future.new { subject.execute_agi_command 'EXEC ANSWER' }
                sleep 0.25
                subject.process_ami_event ami_event
                expect(fut.value).to eq({code: 200, result: 123, data: 'timeout'})
              end
            end
          end

          describe 'when receiving an Asterisk 13 AsyncAGIExec event' do
            context 'without a subtype' do
              let(:ami_event) do
                RubyAMI::Event.new 'AsyncAGIExec',
                  "Channel"    => channel,
                  "CommandId"  => Adhearsion.new_uuid,
                  "Command"    => "EXEC ANSWER",
                  "Result"     => "200%20result=123%20(timeout)%0A"
              end

              it 'should send an appropriate AsyncAGI AMI action' do
                expect(ami_client).to receive(:send_action).once.with('AGI', 'Channel' => channel, 'Command' => 'EXEC ANSWER', 'CommandID' => Adhearsion.new_uuid).and_return(response)
                fut = Celluloid::Future.new { subject.execute_agi_command 'EXEC ANSWER' }
                sleep 0.25
                subject.process_ami_event ami_event
              end

              context 'with some parameters' do
                let(:params) { [1000, 'foo'] }

                it 'should send the appropriate action' do
                  expect(ami_client).to receive(:send_action).once.with('AGI', 'Channel' => channel, 'Command' => 'WAIT FOR DIGIT "1000" "foo"', 'CommandID' => Adhearsion.new_uuid).and_return(response)
                  fut = Celluloid::Future.new { subject.execute_agi_command 'WAIT FOR DIGIT', *params }
                  sleep 0.25
                  subject.process_ami_event ami_event
                end
              end

              it 'should return the result' do
                fut = Celluloid::Future.new { subject.execute_agi_command 'EXEC ANSWER' }
                sleep 0.25
                subject.process_ami_event ami_event
                expect(fut.value).to eq({code: 200, result: 123, data: 'timeout'})
              end
            end
          end
        end

        describe '#redirect_back' do
          let(:other_channel) { 'SIP/bar' }

          let :other_call do
            Call.new other_channel, translator, ami_client, connection
          end

          it "executes the proper AMI action with only the subject call" do
            expect(ami_client).to receive(:send_action).once.with(
              'Redirect',
              Hash(
                'Exten'     => Translator::Asterisk::REDIRECT_EXTENSION,
                'Priority'  => Translator::Asterisk::REDIRECT_PRIORITY,
                'Context'   => Translator::Asterisk::REDIRECT_CONTEXT,
                'Channel'   => channel
              )
            )
            subject.redirect_back
          end

          it "executes the proper AMI action with another call specified" do
            expect(ami_client).to receive(:send_action).once.with(
              'Redirect',
              Hash(
                'Channel'       => channel,
                'Exten'         => Translator::Asterisk::REDIRECT_EXTENSION,
                'Priority'      => Translator::Asterisk::REDIRECT_PRIORITY,
                'Context'       => Translator::Asterisk::REDIRECT_CONTEXT,
                'ExtraChannel'  => other_channel,
                'ExtraExten'    => Translator::Asterisk::REDIRECT_EXTENSION,
                'ExtraPriority' => Translator::Asterisk::REDIRECT_PRIORITY,
                'ExtraContext'  => Translator::Asterisk::REDIRECT_CONTEXT
              )
            )
            subject.redirect_back other_call
          end
        end
      end
    end
  end
end
