# encoding: utf-8

require 'spec_helper'

module Adhearsion
  class CallController
    describe Dial do
      include CallControllerTestHelpers

      let(:to) { 'sip:foo@bar.com' }
      let(:other_call_id)   { new_uuid }
      let(:other_mock_call) { OutboundCall.new }

      let(:second_to)               { 'sip:baz@bar.com' }
      let(:second_other_call_id)    { new_uuid }
      let(:second_other_mock_call)  { OutboundCall.new }

      let(:mock_answered) { Punchblock::Event::Answered.new }

      let(:latch) { CountDownLatch.new 1 }

      before do
        other_mock_call.wrapped_object.stub id: other_call_id, write_command: true
        second_other_mock_call.wrapped_object.stub id: second_other_call_id, write_command: true
      end

      def mock_end(reason = :hangup_command)
        Punchblock::Event::End.new.tap { |event| event.stub reason: reason }
      end

      describe "#dial" do
        it "should dial the call to the correct endpoint and return a dial status object" do
          OutboundCall.should_receive(:new).and_return other_mock_call
          other_mock_call.should_receive(:dial).with(to, :from => 'foo').once
          dial_thread = Thread.new do
            status = subject.dial(to, :from => 'foo')

            status.should be_a Dial::DialStatus
            joined_status = status.joins[status.calls.first]
            joined_status.duration.should == 0.0
            joined_status.result.should == :no_answer
          end
          sleep 0.1
          other_mock_call << mock_end
          dial_thread.join.should be_true
        end

        it "should default the caller ID to that of the original call" do
          call.stub :from => 'sip:foo@bar.com'
          OutboundCall.should_receive(:new).and_return other_mock_call
          other_mock_call.should_receive(:dial).with(to, :from => 'sip:foo@bar.com').once
          dial_thread = Thread.new do
            subject.dial to
          end
          sleep 0.1
          other_mock_call << mock_end
          dial_thread.join.should be_true
        end

        let(:options) { { :foo => :bar } }

        def dial_in_thread
          Thread.new do
            status = subject.dial to, options
            latch.countdown!
            status
          end
        end

        describe "without a block" do
          before do
            other_mock_call.should_receive(:dial).once.with(to, options)
            OutboundCall.should_receive(:new).and_return other_mock_call
          end

          it "blocks the original controller until the new call ends" do
            dial_in_thread

            latch.wait(1).should be_false

            other_mock_call << mock_end

            latch.wait(1).should be_true
          end

          it "unblocks the original controller if the original call ends" do
            other_mock_call.should_receive(:hangup).once
            dial_in_thread

            latch.wait(1).should be_false

            call << mock_end

            latch.wait(1).should be_true
          end

          it "joins the new call to the existing one on answer" do
            call.should_receive(:answer).once
            other_mock_call.should_receive(:join).once.with(call)

            dial_in_thread

            latch.wait(1).should be_false

            other_mock_call << mock_answered
            other_mock_call << mock_end

            latch.wait(1).should be_true
          end

          it "hangs up the new call when the root call ends" do
            call.should_receive(:answer).once
            other_mock_call.should_receive(:join).once.with(call)
            other_mock_call.should_receive(:hangup).once

            dial_in_thread

            latch.wait(1).should be_false

            other_mock_call << mock_answered
            call << mock_end

            latch.wait(1).should be_true
          end

          context "when the call is rejected" do
            it "has an overall dial status of :no_answer" do
              t = dial_in_thread

              sleep 0.5

              other_mock_call << mock_end(:reject)

              latch.wait(2).should be_true

              t.join
              status = t.value
              status.result.should be == :no_answer
            end
          end

          context "when the call ends with an error" do
            it "has an overall dial status of :error" do
              t = dial_in_thread

              sleep 0.5

              other_mock_call << mock_end(:error)

              latch.wait(2).should be_true

              t.join
              status = t.value
              status.result.should be == :error

              joined_status = status.joins[status.calls.first]
              joined_status.duration.should == 0.0
              joined_status.result.should == :error
            end
          end

          context "when the call is answered and joined" do
            it "has an overall dial status of :answer" do
              call.should_receive(:answer).once
              other_mock_call.should_receive(:join).once.with(call)

              t = dial_in_thread

              sleep 0.5

              other_mock_call << mock_answered
              other_mock_call << mock_end

              latch.wait(1).should be_true

              t.join
              status = t.value
              status.result.should be == :answer

              joined_status = status.joins[status.calls.first]
              joined_status.result.should == :joined
            end

            it "records the duration of the join" do
              call.should_receive(:answer).once
              other_mock_call.should_receive(:join).once.with(call)
              other_mock_call.stub hangup: true

              t = dial_in_thread

              sleep 0.5

              base_time = Time.local(2008, 9, 1, 12, 0, 0)
              Timecop.freeze base_time

              other_mock_call << mock_answered

              base_time = Time.local(2008, 9, 1, 12, 0, 37)
              Timecop.freeze base_time
              other_mock_call << Punchblock::Event::Unjoined.new(call_uri: call.id)
              other_mock_call << mock_end

              latch.wait(1).should be_true

              t.join
              status = t.value
              status.result.should be == :answer
              joined_status = status.joins[status.calls.first]
              joined_status.duration.should == 37.0
            end
          end

          context "when a dial is split" do
            before do
              call.should_receive(:answer).once
              other_mock_call.should_receive(:join).once.with(call)
              other_mock_call.stub(:unjoin).and_return do
                call << Punchblock::Event::Unjoined.new(call_uri: other_mock_call.id)
                other_mock_call << Punchblock::Event::Unjoined.new(call_uri: call.id)
              end
            end

            it "should unjoin the calls" do
              other_mock_call.should_receive(:unjoin).once.ordered.with(call).and_return do
                call << Punchblock::Event::Unjoined.new(call_uri: other_mock_call.id)
                other_mock_call << Punchblock::Event::Unjoined.new(call_uri: call.id)
              end

              dial = Dial::Dial.new to, options, call
              dial.run

              waiter_thread = Thread.new do
                dial.await_completion
                latch.countdown!
              end

              sleep 0.5

              other_mock_call << mock_answered

              dial.split
              other_mock_call << mock_end

              latch.wait(1).should be_true

              waiter_thread.join
              dial.status.result.should be == :answer
            end

            it "should not unblock immediately" do
              dial = Dial::Dial.new to, options, call
              dial.run

              waiter_thread = Thread.new do
                dial.await_completion
                latch.countdown!
              end

              sleep 0.5

              other_mock_call << mock_answered

              dial.split

              latch.wait(1).should be_false

              other_mock_call << mock_end

              latch.wait(1).should be_true

              waiter_thread.join
              dial.status.result.should be == :answer
            end

            it "should set end time" do
              dial = Dial::Dial.new to, options, call
              dial.run

              waiter_thread = Thread.new do
                dial.await_completion
                latch.countdown!
              end

              sleep 0.5

              base_time = Time.local(2008, 9, 1, 12, 0, 0)
              Timecop.freeze base_time

              other_mock_call << mock_answered

              base_time = Time.local(2008, 9, 1, 12, 0, 37)
              Timecop.freeze base_time
              dial.split

              base_time = Time.local(2008, 9, 1, 12, 0, 54)
              Timecop.freeze base_time
              other_mock_call << mock_end

              latch.wait(1).should be_true

              waiter_thread.join
              status = dial.status
              status.result.should be == :answer
              joined_status = status.joins[status.calls.first]
              joined_status.duration.should == 37.0
            end

            context "with new controllers specified" do
              let(:split_latch) { CountDownLatch.new 2 }

              let(:split_controller) do
                latch = split_latch
                Class.new(Adhearsion::CallController) do
                  @@split_latch = latch

                  def run
                    call['hit_split_controller'] = self.class
                    call['split_controller_metadata'] = metadata
                    @@split_latch.countdown!
                  end
                end
              end

              let(:main_split_controller) { Class.new(split_controller) }
              let(:others_split_controller) { Class.new(split_controller) }

              it "should execute the :main controller on the originating call and :others on the outbound calls" do
                dial = Dial::Dial.new to, options, call
                dial.run

                waiter_thread = Thread.new do
                  dial.await_completion
                  latch.countdown!
                end

                sleep 0.5

                other_mock_call << mock_answered

                should_receive(:callback).once.with(call)
                should_receive(:callback).once.with(other_mock_call)

                dial.split main: main_split_controller, others: others_split_controller, main_callback: ->(call) { self.callback(call) }, others_callback: ->(call) { self.callback(call) }

                latch.wait(1).should be_false
                split_latch.wait(1).should be_true

                call['hit_split_controller'].should == main_split_controller
                call['split_controller_metadata']['current_dial'].should be dial

                other_mock_call['hit_split_controller'].should == others_split_controller
                other_mock_call['split_controller_metadata']['current_dial'].should be dial

                other_mock_call << mock_end

                latch.wait(1).should be_true

                waiter_thread.join
                dial.status.result.should be == :answer
              end
            end

            context "when rejoining" do
              it "should rejoin the calls" do
                other_mock_call.should_receive(:unjoin).once.ordered.with(call).and_return do
                  call << Punchblock::Event::Unjoined.new(call_uri: other_mock_call.id)
                  other_mock_call << Punchblock::Event::Unjoined.new(call_uri: call.id)
                end

                dial = Dial::Dial.new to, options, call
                dial.run

                waiter_thread = Thread.new do
                  dial.await_completion
                  latch.countdown!
                end

                sleep 0.5

                other_mock_call << mock_answered

                dial.split

                other_mock_call.should_receive(:join).once.ordered.with(call)
                dial.rejoin

                other_mock_call << mock_end

                latch.wait(1).should be_true

                waiter_thread.join
                dial.status.result.should be == :answer
              end

              context "to a specified mixer" do
                let(:mixer) { SecureRandom.uuid }

                it "should join all calls to the mixer" do
                  other_mock_call.should_receive(:unjoin).once.ordered.with(call).and_return do
                    call << Punchblock::Event::Unjoined.new(call_uri: other_mock_call.id)
                    other_mock_call << Punchblock::Event::Unjoined.new(call_uri: call.id)
                  end

                  dial = Dial::Dial.new to, options, call
                  dial.run

                  waiter_thread = Thread.new do
                    dial.await_completion
                    latch.countdown!
                  end

                  sleep 0.5

                  other_mock_call << mock_answered

                  dial.split

                  call.should_receive(:join).once.ordered.with(mixer_name: mixer)
                  other_mock_call.should_receive(:join).once.ordered.with(mixer_name: mixer)
                  dial.rejoin mixer_name: mixer

                  other_mock_call << mock_end

                  latch.wait(1).should be_true

                  waiter_thread.join
                  dial.status.result.should be == :answer
                end

                it "#split should then unjoin calls from the mixer" do
                  other_mock_call.should_receive(:unjoin).once.ordered.with(call).and_return do
                    call << Punchblock::Event::Unjoined.new(call_uri: other_mock_call.id)
                    other_mock_call << Punchblock::Event::Unjoined.new(call_uri: call.id)
                  end

                  dial = Dial::Dial.new to, options, call
                  dial.run

                  waiter_thread = Thread.new do
                    dial.await_completion
                    latch.countdown!
                  end

                  sleep 0.5

                  other_mock_call << mock_answered

                  dial.split

                  call.should_receive(:join).once.ordered.with(mixer_name: mixer)
                  other_mock_call.should_receive(:join).once.ordered.with(mixer_name: mixer)
                  dial.rejoin mixer_name: mixer

                  other_mock_call.should_receive(:unjoin).once.ordered.with(mixer_name: mixer).and_return do
                    other_mock_call << Punchblock::Event::Unjoined.new(mixer_name: mixer)
                  end
                  call.should_receive(:unjoin).once.ordered.with(mixer_name: mixer).and_return do
                    call << Punchblock::Event::Unjoined.new(mixer_name: mixer)
                  end
                  dial.split

                  other_mock_call << mock_end

                  latch.wait(1).should be_true

                  waiter_thread.join
                  dial.status.result.should be == :answer
                end
              end
            end

            context "when another dial is merged in" do
              let(:second_root_call_id) { new_uuid }
              let(:second_root_call)    { Adhearsion::Call.new }
              let(:mixer)               { SecureRandom.uuid }

              let(:dial)        { Dial::Dial.new to, options, call }
              let(:other_dial)  { Dial::Dial.new second_to, options, second_root_call }

              before do
                second_root_call.stub write_command: true, id: second_root_call_id
                OutboundCall.should_receive(:new).and_return second_other_mock_call
                second_other_mock_call.should_receive(:join).once.with(second_root_call)
                second_other_mock_call.should_receive(:dial).once.with(second_to, options)
                second_root_call.should_receive(:answer).once

                SecureRandom.stub uuid: mixer

                dial.run
                other_dial.run

                other_mock_call << mock_answered
                second_other_mock_call << mock_answered
              end

              it "should split calls, rejoin to a mixer, and rejoin other calls to mixer" do
                other_mock_call.should_receive(:unjoin).once.ordered.with(call).and_return do
                  call << Punchblock::Event::Unjoined.new(call_uri: other_mock_call.id)
                  other_mock_call << Punchblock::Event::Unjoined.new(call_uri: call.id)
                end
                second_other_mock_call.should_receive(:unjoin).once.ordered.with(second_root_call).and_return do
                  second_root_call << Punchblock::Event::Unjoined.new(call_uri: second_other_mock_call.id)
                  second_other_mock_call << Punchblock::Event::Unjoined.new(call_uri: second_root_call.id)
                end

                call.should_receive(:join).once.ordered.with(mixer_name: mixer)
                other_mock_call.should_receive(:join).once.ordered.with(mixer_name: mixer)

                second_root_call.should_receive(:join).once.ordered.with(mixer_name: mixer)
                second_other_mock_call.should_receive(:join).once.ordered.with(mixer_name: mixer)

                dial.merge other_dial

                waiter_thread = Thread.new do
                  dial.await_completion
                  latch.countdown!
                end

                sleep 0.5

                other_mock_call.async << mock_end
                second_root_call.async << mock_end
                second_other_mock_call.async << mock_end

                latch.wait(1).should be_true

                waiter_thread.join
                dial.status.result.should be == :answer
              end

              it "should add the merged calls to the returned status" do
                [call, other_mock_call, second_root_call, second_other_mock_call].each { |c| c.stub join: true, unjoin: true }
                dial.merge other_dial

                waiter_thread = Thread.new do
                  dial.await_completion
                  latch.countdown!
                end

                sleep 0.5

                other_mock_call.async << mock_end
                second_root_call.async << mock_end
                second_other_mock_call.async << mock_end

                latch.wait(1).should be_true

                waiter_thread.join
                dial.status.result.should be == :answer
                dial.status.calls.should include(second_root_call, second_other_mock_call)
              end

              it "should not unblock until all joined calls end" do
                [call, other_mock_call, second_root_call, second_other_mock_call].each { |c| c.stub join: true, unjoin: true }

                dial.merge other_dial

                waiter_thread = Thread.new do
                  dial.await_completion
                  latch.countdown!
                end

                sleep 0.5

                other_mock_call << mock_end
                latch.wait(1).should be_false

                second_other_mock_call << mock_end
                latch.wait(1).should be_false

                second_root_call << mock_end
                latch.wait(1).should be_true

                waiter_thread.join
                dial.status.result.should be == :answer
              end

              it "should cleanup merged calls when the root call ends" do
                [call, other_mock_call, second_root_call, second_other_mock_call].each do |c|
                  c.stub join: true, unjoin: true
                end
                [other_mock_call, second_root_call, second_other_mock_call].each do |c|
                  c.should_receive(:hangup).once
                end

                dial.merge other_dial

                waiter_thread = Thread.new do
                  dial.await_completion
                  dial.cleanup_calls
                  latch.countdown!
                end

                sleep 0.5

                call << mock_end
                latch.wait(1).should be_true

                waiter_thread.join
                dial.status.result.should be == :answer
              end

              it "should subsequently rejoin to a mixer" do
                SecureRandom.stub uuid: 'foobar'
                [call, other_mock_call, second_root_call, second_other_mock_call].each { |c| c.stub join: true, unjoin: true }

                dial.merge other_dial

                waiter_thread = Thread.new do
                  dial.await_completion
                  latch.countdown!
                end

                sleep 0.5

                other_mock_call << mock_end
                latch.wait(1).should be_false

                [call, second_root_call, second_other_mock_call].each do |call|
                  call.should_receive(:unjoin).once.with(mixer_name: 'foobar').and_return do
                    call << Punchblock::Event::Unjoined.new(mixer_name: 'foobar')
                  end
                end

                dial.split

                [call, second_root_call, second_other_mock_call].each do |call|
                  call.should_receive(:join).once.with(mixer_name: 'foobar').and_return do
                    call << Punchblock::Event::Joined.new(mixer_name: 'foobar')
                  end
                end

                dial.rejoin
              end

              context "if a call hangs up" do
                before { SecureRandom.stub uuid: 'foobar' }

                it "should still allow splitting and rejoining" do
                  [call, other_mock_call, second_root_call, second_other_mock_call].each { |c| c.stub join: true, unjoin: true }

                  dial.merge other_dial

                  waiter_thread = Thread.new do
                    dial.await_completion
                    latch.countdown!
                  end

                  sleep 0.5

                  [call, second_root_call, second_other_mock_call].each do |call|
                    call.should_receive(:unjoin).once.with(mixer_name: 'foobar').and_return do
                      call << Punchblock::Event::Unjoined.new(mixer_name: 'foobar')
                    end
                  end

                  other_mock_call.should_receive(:unjoin).and_raise Adhearsion::Call::Hangup

                  dial.split

                  other_mock_call << mock_end
                  latch.wait(1).should be_false

                  [call, second_root_call, second_other_mock_call].each do |call|
                    call.should_receive(:join).once.with(mixer_name: 'foobar').and_return do
                      call << Punchblock::Event::Joined.new(mixer_name: 'foobar')
                    end
                  end

                  other_mock_call.should_receive(:join).and_raise Adhearsion::Call::ExpiredError

                  dial.rejoin
                end
              end

              context "if the calls were not joined" do
                it "should still join to mixer" do
                  other_mock_call.should_receive(:unjoin).once.ordered.with(call).and_raise Punchblock::ProtocolError.new.setup(:service_unavailable)
                  second_other_mock_call.should_receive(:unjoin).once.ordered.with(second_root_call).and_raise Punchblock::ProtocolError.new.setup(:service_unavailable)

                  call.should_receive(:join).once.ordered.with(mixer_name: mixer)
                  other_mock_call.should_receive(:join).once.ordered.with(mixer_name: mixer)

                  second_root_call.should_receive(:join).once.ordered.with(mixer_name: mixer)
                  second_other_mock_call.should_receive(:join).once.ordered.with(mixer_name: mixer)

                  dial.merge other_dial

                  waiter_thread = Thread.new do
                    dial.await_completion
                    latch.countdown!
                  end

                  sleep 0.5

                  other_mock_call.async << mock_end
                  second_root_call.async << mock_end
                  second_other_mock_call.async << mock_end

                  latch.wait(1).should be_true

                  waiter_thread.join
                  dial.status.result.should be == :answer
                end
              end
            end
          end
        end

        describe "when the caller has already hung up" do
          before do
            call << mock_end
          end

          it "should raise Call::Hangup" do
            expect { subject.dial to, options }.to raise_error(Call::Hangup)
          end

          it "should not make any outbound calls" do
            OutboundCall.should_receive(:new).never
            expect { subject.dial to, options }.to raise_error
          end
        end

        describe "with multiple third parties specified" do
          let(:options) { {} }
          let(:other_options) { options }
          let(:second_other_options) { options }

          before do
            OutboundCall.should_receive(:new).and_return other_mock_call, second_other_mock_call

            other_mock_call.should_receive(:dial).once.with(to, other_options)

            second_other_mock_call.should_receive(:dial).once.with(second_to, second_other_options)
            second_other_mock_call.should_receive(:join).never
          end

          def dial_in_thread
            Thread.new do
              status = subject.dial [to, second_to], options
              latch.countdown!
              status
            end
          end

          it "dials all parties and joins the first one to answer, hanging up the rest" do
            call.should_receive(:answer).once
            other_mock_call.should_receive(:join).once.with(call)
            second_other_mock_call.should_receive(:hangup).once.and_return do
              second_other_mock_call << mock_end
            end

            t = dial_in_thread

            latch.wait(1).should be_false

            other_mock_call << mock_answered
            other_mock_call << mock_end

            latch.wait(2).should be_true

            t.join
            status = t.value
            status.should be_a Dial::DialStatus
            status.should have(2).calls
            status.calls.each { |c| c.should be_a OutboundCall }
          end

          it "unblocks when the joined call unjoins, allowing it to proceed further" do
            call.should_receive(:answer).once
            other_mock_call.should_receive(:join).once.with(call)
            other_mock_call.should_receive(:hangup).once
            second_other_mock_call.should_receive(:hangup).once.and_return do
              second_other_mock_call << mock_end
            end

            t = dial_in_thread

            latch.wait(1).should be_false

            other_mock_call << mock_answered
            other_mock_call << Punchblock::Event::Unjoined.new(call_uri: call.id)

            latch.wait(2).should be_true

            t.join
            status = t.value
            status.should be_a Dial::DialStatus
            status.should have(2).calls
            status.calls.each { |c| c.should be_a OutboundCall }
          end

          describe "with options overrides" do
            let(:options) do
              {
                :from => 'foo',
                :timeout => 3000,
                :headers => {
                  :x_foo => 'bar'
                }
              }
            end

            let(:dial_other_options) do
              {
                :foo => 'bar',
                :headers => {
                  :x_foo => 'buzz'
                }
              }
            end

            let(:other_options) do
              {
                :from => 'foo',
                :timeout => 3000,
                :foo => 'bar',
                :headers => {
                  :x_foo => 'buzz'
                }

              }
            end

            let(:dial_second_other_options) do
              {
                :timeout => 5000,
                :headers => {
                  :x_bar => 'barbuzz'
                }
              }
            end

            let(:second_other_options) do
              {
                :from => 'foo',
                :timeout => 5000,
                :headers => {
                  :x_foo => 'bar',
                  :x_bar => 'barbuzz'
                }
              }
            end

            it "with multiple destinations as an hash, with overrides for each, and an options hash, it dials each call with specified options" do
              t = Thread.new do
                subject.dial({
                  to => dial_other_options,
                  second_to => dial_second_other_options
                }, options)
                latch.countdown!
              end

              latch.wait(1).should be_false
              other_mock_call << mock_end
              latch.wait(1).should be_false
              second_other_mock_call << mock_end
              latch.wait(2).should be_true
              t.join
            end
          end

          context "when all calls are rejected" do
            it "has an overall dial status of :no_answer" do
              t = dial_in_thread

              sleep 0.5

              other_mock_call << mock_end(:reject)
              second_other_mock_call << mock_end(:reject)

              latch.wait(2).should be_true

              t.join
              status = t.value
              status.result.should be == :no_answer
            end
          end

          context "when a call is answered and joined, and the other ends with an error" do
            it "has an overall dial status of :answer" do
              call.should_receive(:answer).once
              other_mock_call.should_receive(:join).once.with(call)
              second_other_mock_call.should_receive(:hangup).once.and_return do
                second_other_mock_call << mock_end(:error)
              end

              t = dial_in_thread

              sleep 0.5

              other_mock_call << mock_answered
              other_mock_call << mock_end

              latch.wait(1).should be_true

              t.join
              status = t.value
              status.result.should be == :answer
            end
          end
        end

        describe "with a timeout specified" do
          let(:timeout) { 3 }

          it "should abort the dial after the specified timeout" do
            other_mock_call.should_receive(:dial).once
            other_mock_call.should_receive(:hangup).once
            OutboundCall.should_receive(:new).and_return other_mock_call

            time = Time.now

            t = Thread.new do
              status = subject.dial to, :timeout => timeout
              latch.countdown!
              status
            end

            latch.wait
            time = Time.now - time
            time.round.should be == timeout
            t.join
            status = t.value
            status.result.should be == :timeout
          end

          describe "if someone answers before the timeout elapses" do
            it "should not abort until the far end hangs up" do
              other_mock_call.should_receive(:dial).once.with(to, hash_including(:timeout => timeout))
              call.should_receive(:answer).once
              other_mock_call.should_receive(:join).once.with(call)
              OutboundCall.should_receive(:new).and_return other_mock_call

              time = Time.now

              t = Thread.new do
                status = subject.dial to, :timeout => timeout
                latch.countdown!
                status
              end

              latch.wait(2).should be_false

              other_mock_call << mock_answered

              latch.wait(2).should be_false

              other_mock_call << mock_end

              latch.wait(0.1).should be_true
              time = Time.now - time
              time.to_i.should be > timeout
              t.join
              status = t.value
              status.result.should be == :answer
            end
          end
        end

        describe "with a confirmation controller" do
          let(:confirmation_controller) do
            latch = confirmation_latch
            Class.new(Adhearsion::CallController) do
              @@confirmation_latch = latch

              def run
                # Copy metadata onto call variables so we can assert it later. Ugly hack
                metadata.each_pair do |key, value|
                  call[key] = value
                end
                @@confirmation_latch.countdown!
                call['confirm'] || hangup
              end
            end
          end

          let(:confirmation_latch) { CountDownLatch.new 1 }

          let(:options) { {:confirm => confirmation_controller} }

          context "with confirmation controller metadata specified" do
            let(:options) { {:confirm => confirmation_controller, :confirm_metadata => {:foo => 'bar'}} }

            before do
              other_mock_call.should_receive(:dial).once
              OutboundCall.should_receive(:new).and_return other_mock_call
            end

            it "should set the metadata on the controller" do
              other_mock_call.should_receive(:hangup).once.and_return do
                other_mock_call << mock_end
              end
              other_mock_call['confirm'] = false

              dial_in_thread

              latch.wait(0.1).should be_false

              other_mock_call << mock_answered

              confirmation_latch.wait(1).should be_true
              latch.wait(2).should be_true

              other_mock_call[:foo].should == 'bar'
            end
          end

          context "when an outbound call is answered" do
            before do
              other_mock_call.should_receive(:dial).once
              OutboundCall.should_receive(:new).and_return other_mock_call
            end

            it "should execute the specified confirmation controller" do
              other_mock_call.should_receive(:hangup).once.and_return do
                other_mock_call << mock_end
              end
              other_mock_call['confirm'] = false

              dial_in_thread

              latch.wait(0.1).should be_false

              other_mock_call << mock_answered

              confirmation_latch.wait(1).should be_true
              latch.wait(2).should be_true
            end

            it "should join the calls if the call is still active after execution of the call controller" do
              other_mock_call.should_receive(:hangup).once
              other_mock_call['confirm'] = true
              call.should_receive(:answer).once
              other_mock_call.should_receive(:join).once.with(call)

              t = dial_in_thread

              latch.wait(1).should be_false

              base_time = Time.local(2008, 9, 1, 12, 0, 0)
              Timecop.freeze base_time

              other_mock_call << mock_answered

              base_time = Time.local(2008, 9, 1, 12, 0, 42)
              Timecop.freeze base_time
              other_mock_call << Punchblock::Event::Unjoined.new(call_uri: call.id)
              other_mock_call << mock_end

              latch.wait(1).should be_true

              t.join
              status = t.value
              status.result.should be == :answer

              joined_status = status.joins[status.calls.first]
              joined_status.duration.should == 42.0
              joined_status.result.should == :joined
            end

            it "should not join the calls if the call is not active after execution of the call controller" do
              other_mock_call.should_receive(:hangup).once.and_return do
                other_mock_call << mock_end
              end
              other_mock_call['confirm'] = false
              call.should_receive(:answer).never
              other_mock_call.should_receive(:join).never.with(call)

              t = dial_in_thread

              latch.wait(1).should be_false

              other_mock_call << mock_answered

              latch.wait(1).should be_true

              t.join
              status = t.value
              status.result.should be == :unconfirmed

              joined_status = status.joins[status.calls.first]
              joined_status.duration.should == 0.0
              joined_status.result.should == :unconfirmed
            end
          end

          context "when multiple calls are made" do
            before do
              OutboundCall.should_receive(:new).and_return other_mock_call, second_other_mock_call
            end

            def dial_in_thread
              Thread.new do
                status = subject.dial [to, second_to], options
                latch.countdown!
                status
              end
            end

            context "when one answers" do
              it "should only execute the confirmation controller on the first call to answer, immediately hanging up all others" do
                other_mock_call['confirm'] = true
                call.should_receive(:answer).once

                other_mock_call.should_receive(:dial).once.with(to, from: nil)
                other_mock_call.should_receive(:join).once.with(call)
                other_mock_call.should_receive(:hangup).once.and_return do
                  other_mock_call << mock_end
                end

                second_other_mock_call.should_receive(:dial).once.with(second_to, from: nil)
                second_other_mock_call.should_receive(:join).never
                second_other_mock_call.should_receive(:execute_controller).never
                second_other_mock_call.should_receive(:hangup).once.and_return do
                  second_other_mock_call << mock_end(:foo)
                end

                t = dial_in_thread

                latch.wait(1).should be_false

                other_mock_call << mock_answered
                confirmation_latch.wait(1).should be_true

                other_mock_call << Punchblock::Event::Unjoined.new(call_uri: call.id)

                latch.wait(2).should be_true

                t.join
                status = t.value
                status.should be_a Dial::DialStatus
                status.should have(2).calls
                status.calls.each { |c| c.should be_a OutboundCall }
                status.result.should be == :answer
              end
            end
          end
        end
      end

      describe "#dial_and_confirm" do
        it "should dial the call to the correct endpoint and return a dial status object" do
          OutboundCall.should_receive(:new).and_return other_mock_call
          other_mock_call.should_receive(:dial).with(to, :from => 'foo').once
          dial_thread = Thread.new do
            status = subject.dial_and_confirm(to, :from => 'foo')

            status.should be_a Dial::DialStatus
            joined_status = status.joins[status.calls.first]
            joined_status.duration.should == 0.0
            joined_status.result.should == :no_answer
          end
          sleep 0.1
          other_mock_call << mock_end
          dial_thread.join.should be_true
        end

        it "should default the caller ID to that of the original call" do
          call.stub :from => 'sip:foo@bar.com'
          OutboundCall.should_receive(:new).and_return other_mock_call
          other_mock_call.should_receive(:dial).with(to, :from => 'sip:foo@bar.com').once
          dial_thread = Thread.new do
            subject.dial_and_confirm to
          end
          sleep 0.1
          other_mock_call << mock_end
          dial_thread.join.should be_true
        end

        let(:options) { { :foo => :bar } }

        def dial_in_thread
          Thread.new do
            status = subject.dial_and_confirm to, options
            latch.countdown!
            status
          end
        end

        describe "without a block" do
          before do
            other_mock_call.should_receive(:dial).once.with(to, options)
            OutboundCall.should_receive(:new).and_return other_mock_call
          end

          it "blocks the original controller until the new call ends" do
            dial_in_thread

            latch.wait(1).should be_false

            other_mock_call << mock_end

            latch.wait(1).should be_true
          end

          it "unblocks the original controller if the original call ends" do
            other_mock_call.should_receive(:hangup).once
            dial_in_thread

            latch.wait(1).should be_false

            call << mock_end

            latch.wait(1).should be_true
          end

          it "joins the new call to the existing one on answer" do
            call.should_receive(:answer).once
            other_mock_call.should_receive(:join).once.with(call)

            dial_in_thread

            latch.wait(1).should be_false

            other_mock_call << mock_answered
            other_mock_call << mock_end

            latch.wait(1).should be_true
          end

          it "hangs up the new call when the root call ends" do
            other_mock_call.should_receive(:hangup).once
            call.should_receive(:answer).once
            other_mock_call.should_receive(:join).once.with(call)

            dial_in_thread

            latch.wait(1).should be_false

            other_mock_call << mock_answered
            call << mock_end

            latch.wait(1).should be_true
          end

          context "when the call is rejected" do
            it "has an overall dial status of :no_answer" do
              t = dial_in_thread

              sleep 0.5

              other_mock_call << mock_end(:reject)

              latch.wait(2).should be_true

              t.join
              status = t.value
              status.result.should be == :no_answer
            end
          end

          context "when the call ends with an error" do
            it "has an overall dial status of :error" do
              t = dial_in_thread

              sleep 0.5

              other_mock_call << mock_end(:error)

              latch.wait(2).should be_true

              t.join
              status = t.value
              status.result.should be == :error

              joined_status = status.joins[status.calls.first]
              joined_status.duration.should == 0.0
              joined_status.result.should == :error
            end
          end

          context "when the call is answered and joined" do
            it "has an overall dial status of :answer" do
              call.should_receive(:answer).once
              other_mock_call.should_receive(:join).once.with(call)

              t = dial_in_thread

              sleep 0.5

              other_mock_call << mock_answered
              other_mock_call << mock_end

              latch.wait(1).should be_true

              t.join
              status = t.value
              status.result.should be == :answer

              joined_status = status.joins[status.calls.first]
              joined_status.result.should == :joined
            end

            it "records the duration of the join" do
              call.should_receive(:answer).once
              other_mock_call.should_receive(:join).once.with(call)
              other_mock_call.stub hangup: true

              t = dial_in_thread

              sleep 0.5

              base_time = Time.local(2008, 9, 1, 12, 0, 0)
              Timecop.freeze base_time

              other_mock_call << mock_answered

              base_time = Time.local(2008, 9, 1, 12, 0, 37)
              Timecop.freeze base_time
              other_mock_call << Punchblock::Event::Unjoined.new(call_uri: call.id)
              other_mock_call << mock_end

              latch.wait(1).should be_true

              t.join
              status = t.value
              status.result.should be == :answer
              joined_status = status.joins[status.calls.first]
              joined_status.duration.should == 37.0
            end
          end

          context "when a dial is split" do
            before do
              call.should_receive(:answer).once
              other_mock_call.should_receive(:join).once.with(call)
              other_mock_call.stub(:unjoin).and_return do
                call << Punchblock::Event::Unjoined.new(call_uri: other_mock_call.id)
                other_mock_call << Punchblock::Event::Unjoined.new(call_uri: call.id)
              end
            end

            it "should unjoin the calls" do
              other_mock_call.should_receive(:unjoin).once.ordered.with(call).and_return do
                call << Punchblock::Event::Unjoined.new(call_uri: other_mock_call.id)
                other_mock_call << Punchblock::Event::Unjoined.new(call_uri: call.id)
              end

              dial = Dial::ParallelConfirmationDial.new to, options, call
              dial.run

              waiter_thread = Thread.new do
                dial.await_completion
                latch.countdown!
              end

              sleep 0.5

              other_mock_call << mock_answered

              dial.split
              other_mock_call << mock_end

              latch.wait(1).should be_true

              waiter_thread.join
              dial.status.result.should be == :answer
            end

            it "should not unblock immediately" do
              dial = Dial::ParallelConfirmationDial.new to, options, call
              dial.run

              waiter_thread = Thread.new do
                dial.await_completion
                latch.countdown!
              end

              sleep 0.5

              other_mock_call << mock_answered

              dial.split

              latch.wait(1).should be_false

              other_mock_call << mock_end

              latch.wait(1).should be_true

              waiter_thread.join
              dial.status.result.should be == :answer
            end

            it "should set end time" do
              dial = Dial::ParallelConfirmationDial.new to, options, call
              dial.run

              waiter_thread = Thread.new do
                dial.await_completion
                latch.countdown!
              end

              sleep 0.5

              base_time = Time.local(2008, 9, 1, 12, 0, 0)
              Timecop.freeze base_time

              other_mock_call << mock_answered

              base_time = Time.local(2008, 9, 1, 12, 0, 37)
              Timecop.freeze base_time
              dial.split

              base_time = Time.local(2008, 9, 1, 12, 0, 54)
              Timecop.freeze base_time
              other_mock_call << mock_end

              latch.wait(1).should be_true

              waiter_thread.join
              status = dial.status
              status.result.should be == :answer
              joined_status = status.joins[status.calls.first]
              joined_status.duration.should == 37.0
            end

            context "with new controllers specified" do
              let(:split_latch) { CountDownLatch.new 2 }

              let(:split_controller) do
                latch = split_latch
                Class.new(Adhearsion::CallController) do
                  @@split_latch = latch

                  def run
                    call['hit_split_controller'] = self.class
                    call['split_controller_metadata'] = metadata
                    @@split_latch.countdown!
                  end
                end
              end

              let(:main_split_controller) { Class.new(split_controller) }
              let(:others_split_controller) { Class.new(split_controller) }

              it "should execute the :main controller on the originating call and :others on the outbound calls" do
                dial = Dial::ParallelConfirmationDial.new to, options, call
                dial.run

                waiter_thread = Thread.new do
                  dial.await_completion
                  latch.countdown!
                end

                sleep 0.5

                other_mock_call << mock_answered

                should_receive(:callback).once.with(call)
                should_receive(:callback).once.with(other_mock_call)

                dial.split main: main_split_controller, others: others_split_controller, main_callback: ->(call) { self.callback(call) }, others_callback: ->(call) { self.callback(call) }

                latch.wait(1).should be_false
                split_latch.wait(1).should be_true

                call['hit_split_controller'].should == main_split_controller
                call['split_controller_metadata']['current_dial'].should be dial

                other_mock_call['hit_split_controller'].should == others_split_controller
                other_mock_call['split_controller_metadata']['current_dial'].should be dial

                other_mock_call << mock_end

                latch.wait(1).should be_true

                waiter_thread.join
                dial.status.result.should be == :answer
              end
            end

            context "when rejoining" do
              it "should rejoin the calls" do
                other_mock_call.should_receive(:unjoin).once.ordered.with(call).and_return do
                  call << Punchblock::Event::Unjoined.new(call_uri: other_mock_call.id)
                  other_mock_call << Punchblock::Event::Unjoined.new(call_uri: call.id)
                end

                dial = Dial::ParallelConfirmationDial.new to, options, call
                dial.run

                waiter_thread = Thread.new do
                  dial.await_completion
                  latch.countdown!
                end

                sleep 0.5

                other_mock_call << mock_answered

                dial.split

                other_mock_call.should_receive(:join).once.ordered.with(call)
                dial.rejoin

                other_mock_call << mock_end

                latch.wait(1).should be_true

                waiter_thread.join
                dial.status.result.should be == :answer
              end

              context "to a specified mixer" do
                let(:mixer) { SecureRandom.uuid }

                it "should join all calls to the mixer" do
                  other_mock_call.should_receive(:unjoin).once.ordered.with(call).and_return do
                    call << Punchblock::Event::Unjoined.new(call_uri: other_mock_call.id)
                    other_mock_call << Punchblock::Event::Unjoined.new(call_uri: call.id)
                  end

                  dial = Dial::ParallelConfirmationDial.new to, options, call
                  dial.run

                  waiter_thread = Thread.new do
                    dial.await_completion
                    latch.countdown!
                  end

                  sleep 0.5

                  other_mock_call << mock_answered

                  dial.split

                  call.should_receive(:join).once.ordered.with(mixer_name: mixer)
                  other_mock_call.should_receive(:join).once.ordered.with(mixer_name: mixer)
                  dial.rejoin mixer_name: mixer

                  other_mock_call << mock_end

                  latch.wait(1).should be_true

                  waiter_thread.join
                  dial.status.result.should be == :answer
                end

                it "#split should then unjoin calls from the mixer" do
                  other_mock_call.should_receive(:unjoin).once.ordered.with(call).and_return do
                    call << Punchblock::Event::Unjoined.new(call_uri: other_mock_call.id)
                    other_mock_call << Punchblock::Event::Unjoined.new(call_uri: call.id)
                  end

                  dial = Dial::ParallelConfirmationDial.new to, options, call
                  dial.run

                  waiter_thread = Thread.new do
                    dial.await_completion
                    latch.countdown!
                  end

                  sleep 0.5

                  other_mock_call << mock_answered

                  dial.split

                  call.should_receive(:join).once.ordered.with(mixer_name: mixer)
                  other_mock_call.should_receive(:join).once.ordered.with(mixer_name: mixer)
                  dial.rejoin mixer_name: mixer

                  other_mock_call.should_receive(:unjoin).once.ordered.with(mixer_name: mixer).and_return do
                    other_mock_call << Punchblock::Event::Unjoined.new(mixer_name: mixer)
                  end
                  call.should_receive(:unjoin).once.ordered.with(mixer_name: mixer).and_return do
                    call << Punchblock::Event::Unjoined.new(mixer_name: mixer)
                  end
                  dial.split

                  other_mock_call << mock_end

                  latch.wait(1).should be_true

                  waiter_thread.join
                  dial.status.result.should be == :answer
                end
              end
            end

            context "when another dial is merged in" do
              let(:second_root_call_id) { new_uuid }
              let(:second_root_call)    { Adhearsion::Call.new }
              let(:mixer)               { SecureRandom.uuid }

              let(:dial)        { Dial::ParallelConfirmationDial.new to, options, call }
              let(:other_dial)  { Dial::ParallelConfirmationDial.new second_to, options, second_root_call }

              before do
                second_root_call.stub write_command: true, id: second_root_call_id
                OutboundCall.should_receive(:new).and_return second_other_mock_call
                second_other_mock_call.should_receive(:join).once.with(second_root_call)
                second_other_mock_call.should_receive(:dial).once.with(second_to, options)
                second_root_call.should_receive(:answer).once

                SecureRandom.stub uuid: mixer

                dial.run
                other_dial.run

                other_mock_call << mock_answered
                second_other_mock_call << mock_answered
              end

              it "should split calls, rejoin to a mixer, and rejoin other calls to mixer" do
                other_mock_call.should_receive(:unjoin).once.ordered.with(call).and_return do
                  call << Punchblock::Event::Unjoined.new(call_uri: other_mock_call.id)
                  other_mock_call << Punchblock::Event::Unjoined.new(call_uri: call.id)
                end
                second_other_mock_call.should_receive(:unjoin).once.ordered.with(second_root_call).and_return do
                  second_root_call << Punchblock::Event::Unjoined.new(call_uri: second_other_mock_call.id)
                  second_other_mock_call << Punchblock::Event::Unjoined.new(call_uri: second_root_call.id)
                end

                call.should_receive(:join).once.ordered.with(mixer_name: mixer)
                other_mock_call.should_receive(:join).once.ordered.with(mixer_name: mixer)

                second_root_call.should_receive(:join).once.ordered.with(mixer_name: mixer)
                second_other_mock_call.should_receive(:join).once.ordered.with(mixer_name: mixer)

                dial.merge other_dial

                waiter_thread = Thread.new do
                  dial.await_completion
                  latch.countdown!
                end

                sleep 0.5

                other_mock_call.async << mock_end
                second_root_call.async << mock_end
                second_other_mock_call.async << mock_end

                latch.wait(1).should be_true

                waiter_thread.join
                dial.status.result.should be == :answer
              end

              it "should add the merged calls to the returned status" do
                [call, other_mock_call, second_root_call, second_other_mock_call].each { |c| c.stub join: true, unjoin: true }
                dial.merge other_dial

                waiter_thread = Thread.new do
                  dial.await_completion
                  latch.countdown!
                end

                sleep 0.5

                other_mock_call.async << mock_end
                second_root_call.async << mock_end
                second_other_mock_call.async << mock_end

                latch.wait(1).should be_true

                waiter_thread.join
                dial.status.result.should be == :answer
                dial.status.calls.should include(second_root_call, second_other_mock_call)
              end

              it "should not unblock until all joined calls end" do
                [call, other_mock_call, second_root_call, second_other_mock_call].each { |c| c.stub join: true, unjoin: true }

                dial.merge other_dial

                waiter_thread = Thread.new do
                  dial.await_completion
                  latch.countdown!
                end

                sleep 0.5

                other_mock_call << mock_end
                latch.wait(1).should be_false

                second_other_mock_call << mock_end
                latch.wait(1).should be_false

                second_root_call << mock_end
                latch.wait(1).should be_true

                waiter_thread.join
                dial.status.result.should be == :answer
              end

              it "should cleanup merged calls when the root call ends" do
                [call, other_mock_call, second_root_call, second_other_mock_call].each do |c|
                  c.stub join: true, unjoin: true
                end
                [other_mock_call, second_root_call, second_other_mock_call].each do |c|
                  c.should_receive(:hangup).once
                end

                dial.merge other_dial

                waiter_thread = Thread.new do
                  dial.await_completion
                  dial.cleanup_calls
                  latch.countdown!
                end

                sleep 0.5

                call << mock_end
                latch.wait(1).should be_true

                waiter_thread.join
                dial.status.result.should be == :answer
              end

              it "should subsequently rejoin to a mixer" do
                SecureRandom.stub uuid: 'foobar'
                [call, other_mock_call, second_root_call, second_other_mock_call].each { |c| c.stub join: true, unjoin: true }

                dial.merge other_dial

                waiter_thread = Thread.new do
                  dial.await_completion
                  latch.countdown!
                end

                sleep 0.5

                other_mock_call << mock_end
                latch.wait(1).should be_false

                [call, second_root_call, second_other_mock_call].each do |call|
                  call.should_receive(:unjoin).once.with(mixer_name: 'foobar').and_return do
                    call << Punchblock::Event::Unjoined.new(mixer_name: 'foobar')
                  end
                end

                dial.split

                [call, other_mock_call, second_root_call, second_other_mock_call].each do |call|
                  call.should_receive(:join).once.with(mixer_name: 'foobar').and_return do
                    call << Punchblock::Event::Joined.new(mixer_name: 'foobar')
                  end
                end

                dial.rejoin
              end

              context "if a call hangs up" do
                before { SecureRandom.stub uuid: 'foobar' }

                it "should still allow splitting and rejoining" do
                  [call, other_mock_call, second_root_call, second_other_mock_call].each { |c| c.stub join: true, unjoin: true }

                  dial.merge other_dial

                  waiter_thread = Thread.new do
                    dial.await_completion
                    latch.countdown!
                  end

                  sleep 0.5

                  [call, second_root_call, second_other_mock_call].each do |call|
                    call.should_receive(:unjoin).once.with(mixer_name: 'foobar').and_return do
                      call << Punchblock::Event::Unjoined.new(mixer_name: 'foobar')
                    end
                  end

                  other_mock_call.should_receive(:unjoin).and_raise Adhearsion::Call::Hangup

                  dial.split

                  other_mock_call << mock_end
                  latch.wait(1).should be_false

                  [call, second_root_call, second_other_mock_call].each do |call|
                    call.should_receive(:join).once.with(mixer_name: 'foobar').and_return do
                      call << Punchblock::Event::Joined.new(mixer_name: 'foobar')
                    end
                  end

                  other_mock_call.should_receive(:join).and_raise Adhearsion::Call::ExpiredError

                  dial.rejoin
                end
              end

              context "if the calls were not joined" do
                it "should still join to mixer" do
                  other_mock_call.should_receive(:unjoin).once.ordered.with(call).and_raise Punchblock::ProtocolError.new.setup(:service_unavailable)
                  second_other_mock_call.should_receive(:unjoin).once.ordered.with(second_root_call).and_raise Punchblock::ProtocolError.new.setup(:service_unavailable)

                  call.should_receive(:join).once.ordered.with(mixer_name: mixer)
                  other_mock_call.should_receive(:join).once.ordered.with(mixer_name: mixer)

                  second_root_call.should_receive(:join).once.ordered.with(mixer_name: mixer)
                  second_other_mock_call.should_receive(:join).once.ordered.with(mixer_name: mixer)

                  dial.merge other_dial

                  waiter_thread = Thread.new do
                    dial.await_completion
                    latch.countdown!
                  end

                  sleep 0.5

                  other_mock_call.async << mock_end
                  second_root_call.async << mock_end
                  second_other_mock_call.async << mock_end

                  latch.wait(1).should be_true

                  waiter_thread.join
                  dial.status.result.should be == :answer
                end
              end
            end
          end
        end

        describe "when the caller has already hung up" do
          before do
            call << mock_end
          end

          it "should raise Call::Hangup" do
            expect { subject.dial_and_confirm to, options }.to raise_error(Call::Hangup)
          end

          it "should not make any outbound calls" do
            OutboundCall.should_receive(:new).never
            expect { subject.dial_and_confirm to, options }.to raise_error
          end
        end

        describe "with multiple third parties specified" do
          let(:options) { {} }
          let(:other_options) { options }
          let(:second_other_options) { options }

          before do
            OutboundCall.should_receive(:new).and_return other_mock_call, second_other_mock_call

            other_mock_call.should_receive(:dial).once.with(to, other_options)

            second_other_mock_call.should_receive(:dial).once.with(second_to, second_other_options)
            second_other_mock_call.should_receive(:join).never
          end

          def dial_in_thread
            Thread.new do
              status = subject.dial_and_confirm [to, second_to], options
              latch.countdown!
              status
            end
          end

          it "dials all parties and joins the first one to answer, hanging up the rest" do
            call.should_receive(:answer).once
            other_mock_call.should_receive(:join).once.with(call)
            second_other_mock_call.should_receive(:hangup).once.and_return do
              second_other_mock_call << mock_end
            end

            t = dial_in_thread

            latch.wait(1).should be_false

            other_mock_call << mock_answered
            other_mock_call << mock_end

            latch.wait(2).should be_true

            t.join
            status = t.value
            status.should be_a Dial::DialStatus
            status.should have(2).calls
            status.calls.each { |c| c.should be_a OutboundCall }
          end

          it "unblocks when the joined call unjoins, allowing it to proceed further" do
            call.should_receive(:answer).once
            other_mock_call.should_receive(:join).once.with(call)
            other_mock_call.should_receive(:hangup).once
            second_other_mock_call.should_receive(:hangup).once.and_return do
              second_other_mock_call << mock_end
            end

            t = dial_in_thread

            latch.wait(1).should be_false

            other_mock_call << mock_answered
            other_mock_call << Punchblock::Event::Unjoined.new(call_uri: call.id)

            latch.wait(2).should be_true

            t.join
            status = t.value
            status.should be_a Dial::DialStatus
            status.should have(2).calls
            status.calls.each { |c| c.should be_a OutboundCall }
          end

          describe "with options overrides" do
            let(:options) do
              {
                :from => 'foo',
                :timeout => 3000,
                :headers => {
                  :x_foo => 'bar'
                }
              }
            end

            let(:dial_other_options) do
              {
                :foo => 'bar',
                :headers => {
                  :x_foo => 'buzz'
                }
              }
            end

            let(:other_options) do
              {
                :from => 'foo',
                :timeout => 3000,
                :foo => 'bar',
                :headers => {
                  :x_foo => 'buzz'
                }

              }
            end

            let(:dial_second_other_options) do
              {
                :timeout => 5000,
                :headers => {
                  :x_bar => 'barbuzz'
                }
              }
            end

            let(:second_other_options) do
              {
                :from => 'foo',
                :timeout => 5000,
                :headers => {
                  :x_foo => 'bar',
                  :x_bar => 'barbuzz'
                }
              }
            end

            it "with multiple destinations as an hash, with overrides for each, and an options hash, it dials each call with specified options" do
              t = Thread.new do
                subject.dial_and_confirm({
                  to => dial_other_options,
                  second_to => dial_second_other_options
                }, options)
                latch.countdown!
              end

              latch.wait(1).should be_false
              other_mock_call << mock_end
              latch.wait(1).should be_false
              second_other_mock_call << mock_end
              latch.wait(2).should be_true
              t.join
            end
          end

          context "when all calls are rejected" do
            it "has an overall dial status of :no_answer" do
              t = dial_in_thread

              sleep 0.5

              other_mock_call << mock_end(:reject)
              second_other_mock_call << mock_end(:reject)

              latch.wait(2).should be_true

              t.join
              status = t.value
              status.result.should be == :no_answer
            end
          end

          context "when a call is answered and joined, and the other ends with an error" do
            it "has an overall dial status of :answer" do
              call.should_receive(:answer).once
              other_mock_call.should_receive(:join).once.with(call)
              second_other_mock_call.should_receive(:hangup).once.and_return do
                second_other_mock_call << mock_end(:error)
              end

              t = dial_in_thread

              sleep 0.5

              other_mock_call << mock_answered
              other_mock_call << mock_end

              latch.wait(1).should be_true

              t.join
              status = t.value
              status.result.should be == :answer
            end
          end
        end

        describe "with a timeout specified" do
          let(:timeout) { 3 }

          it "should abort the dial after the specified timeout" do
            other_mock_call.should_receive(:dial).once
            other_mock_call.should_receive(:hangup).once
            OutboundCall.should_receive(:new).and_return other_mock_call

            time = Time.now

            t = Thread.new do
              status = subject.dial_and_confirm to, :timeout => timeout
              latch.countdown!
              status
            end

            latch.wait
            time = Time.now - time
            time.round.should be == timeout
            t.join
            status = t.value
            status.result.should be == :timeout
          end

          describe "if someone answers before the timeout elapses" do
            it "should not abort until the far end hangs up" do
              other_mock_call.should_receive(:dial).once.with(to, hash_including(:timeout => timeout))
              call.should_receive(:answer).once
              other_mock_call.should_receive(:join).once.with(call)
              OutboundCall.should_receive(:new).and_return other_mock_call

              time = Time.now

              t = Thread.new do
                status = subject.dial_and_confirm to, :timeout => timeout
                latch.countdown!
                status
              end

              latch.wait(2).should be_false

              other_mock_call << mock_answered

              latch.wait(2).should be_false

              other_mock_call << mock_end

              latch.wait(0.1).should be_true
              time = Time.now - time
              time.to_i.should be > timeout
              t.join
              status = t.value
              status.result.should be == :answer
            end
          end
        end

        describe "with a confirmation controller" do
          let(:confirmation_controller) do
            latch = confirmation_latch
            Class.new(Adhearsion::CallController) do
              @@confirmation_latch = latch

              def run
                # Copy metadata onto call variables so we can assert it later. Ugly hack
                metadata.each_pair do |key, value|
                  call[key] = value
                end
                @@confirmation_latch.countdown!
                if delay = call['confirmation_delay']
                  sleep delay
                end
                call['confirm'] || hangup
              end
            end
          end

          let(:confirmation_latch) { CountDownLatch.new 1 }

          let(:options) { {:confirm => confirmation_controller} }

          context "with confirmation controller metadata specified" do
            let(:options) { {:confirm => confirmation_controller, :confirm_metadata => {:foo => 'bar'}} }

            before do
              other_mock_call.should_receive(:dial).once
              OutboundCall.should_receive(:new).and_return other_mock_call
            end

            it "should set the metadata on the controller" do
              other_mock_call.should_receive(:hangup).once.and_return do
                other_mock_call << mock_end
              end
              other_mock_call['confirm'] = false

              dial_in_thread

              latch.wait(0.1).should be_false

              other_mock_call << mock_answered

              confirmation_latch.wait(1).should be_true
              latch.wait(2).should be_true

              other_mock_call[:foo].should == 'bar'
            end
          end

          context "when an outbound call is answered" do
            before do
              other_mock_call.should_receive(:dial).once
              OutboundCall.should_receive(:new).and_return other_mock_call
            end

            it "should execute the specified confirmation controller" do
              other_mock_call.should_receive(:hangup).once.and_return do
                other_mock_call << mock_end
              end
              other_mock_call['confirm'] = false

              dial_in_thread

              latch.wait(0.1).should be_false

              other_mock_call << mock_answered

              confirmation_latch.wait(1).should be_true
              latch.wait(2).should be_true
            end

            it "should join the calls if the call is still active after execution of the call controller" do
              other_mock_call.should_receive(:hangup).once.and_return do
                other_mock_call << mock_end
              end
              other_mock_call['confirm'] = true
              call.should_receive(:answer).once
              other_mock_call.should_receive(:join).once.with(call)

              t = dial_in_thread

              latch.wait(1).should be_false

              base_time = Time.local(2008, 9, 1, 12, 0, 0)
              Timecop.freeze base_time

              other_mock_call << mock_answered

              base_time = Time.local(2008, 9, 1, 12, 0, 42)
              Timecop.freeze base_time
              other_mock_call << Punchblock::Event::Unjoined.new(call_uri: call.id)

              latch.wait(1).should be_true

              t.join
              status = t.value
              status.result.should be == :answer

              joined_status = status.joins[status.calls.first]
              joined_status.duration.should == 42.0
              joined_status.result.should == :joined
            end

            it "should not join the calls if the call is not active after execution of the call controller" do
              other_mock_call.should_receive(:hangup).once.and_return do
                other_mock_call << mock_end
              end
              other_mock_call['confirm'] = false
              call.should_receive(:answer).never
              other_mock_call.should_receive(:join).never.with(call)

              t = dial_in_thread

              latch.wait(1).should be_false

              other_mock_call << mock_answered

              latch.wait(1).should be_true

              t.join
              status = t.value
              status.result.should be == :unconfirmed

              joined_status = status.joins[status.calls.first]
              joined_status.duration.should == 0.0
              joined_status.result.should == :unconfirmed
            end
          end

          context "when multiple calls are made" do
            let(:confirmation_latch) { CountDownLatch.new 2 }
            let(:apology_controller) do
              Class.new(Adhearsion::CallController) do
                def run
                  logger.info "Apologising..."
                  call['apology_metadata'] = metadata
                  call['apology_done'] = true
                end
              end
            end
            let(:options) { {confirm: confirmation_controller, confirm_metadata: {'foo' => 'bar'}, apology: apology_controller} }

            before do
              OutboundCall.should_receive(:new).and_return other_mock_call, second_other_mock_call
            end

            def dial_in_thread
              Thread.new do
                status = subject.dial_and_confirm [to, second_to], options
                latch.countdown!
                status
              end
            end

            context "when two answer" do
              it "should execute the confirmation controller on both, joining the first call to confirm" do
                other_mock_call['confirm'] = true
                other_mock_call['confirmation_delay'] = 1
                second_other_mock_call['confirm'] = true
                second_other_mock_call['confirmation_delay'] = 1.3

                call.should_receive(:answer).once

                other_mock_call.should_receive(:dial).once.with(to, from: nil)
                other_mock_call.should_receive(:join).once.with(call)
                other_mock_call.should_receive(:hangup).once.and_return do
                  other_mock_call.async.deliver_message mock_end
                end

                second_other_mock_call.should_receive(:dial).once.with(second_to, from: nil)
                second_other_mock_call.should_receive(:join).never
                second_other_mock_call.should_receive(:hangup).once.and_return do
                  second_other_mock_call.async.deliver_message mock_end
                end

                t = dial_in_thread

                latch.wait(1).should be_false

                other_mock_call.async.deliver_message mock_answered
                second_other_mock_call.async.deliver_message mock_answered
                confirmation_latch.wait(1).should be_true

                sleep 2

                other_mock_call.async.deliver_message Punchblock::Event::Unjoined.new(call_uri: call.id)

                latch.wait(2).should be_true

                second_other_mock_call['apology_done'].should be_true
                second_other_mock_call['apology_metadata'].should == {'foo' => 'bar'}

                t.join
                status = t.value
                status.should be_a Dial::DialStatus
                status.should have(2).calls
                status.calls.each { |c| c.should be_a OutboundCall }
                status.result.should be == :answer
                status.joins[other_mock_call].result.should == :joined
                status.joins[second_other_mock_call].result.should == :lost_confirmation
              end
            end
          end
        end
      end

      describe Dial::Dial do
        subject { Dial::Dial.new to, {}, call }

        describe "#prep_calls" do
          it "yields all calls to the passed block" do
            OutboundCall.should_receive(:new).and_return other_mock_call

            gathered_calls = []
            subject.prep_calls { |call| gathered_calls << call }

            expect(gathered_calls).to include(other_mock_call)
          end
        end

        context "#skip_cleanup" do
          it "allows the new call to continue after the root call ends" do
            OutboundCall.should_receive(:new).and_return other_mock_call

            call.stub answer: true
            other_mock_call.stub dial: true, join: true
            other_mock_call.should_receive(:hangup).never

            subject.run

            subject.skip_cleanup

            Thread.new do
              subject.await_completion
              subject.cleanup_calls
              latch.countdown!
            end

            other_mock_call << mock_answered
            call << mock_end

            latch.wait(1).should be_true
          end
        end
      end
    end
  end
end
