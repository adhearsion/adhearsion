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

      let(:mock_answered) { Adhearsion::Event::Answered.new }

      let(:latch) { CountDownLatch.new 1 }

      let(:join_options) { options[:join_options] || {} }

      before do
        allow(other_mock_call.wrapped_object).to receive_messages id: other_call_id, write_command: true
        allow(second_other_mock_call.wrapped_object).to receive_messages id: second_other_call_id, write_command: true
      end

      def mock_end(reason = :hangup_command)
        Adhearsion::Event::End.new.tap { |event| allow(event).to receive_messages reason: reason }
      end

      describe "#dial" do
        it "should dial the call to the correct endpoint and return a dial status object" do
          expect(OutboundCall).to receive(:new).and_return other_mock_call
          expect(other_mock_call).to receive(:dial).with(to, :from => 'foo').once
          dial_thread = Thread.new do
            status = subject.dial(to, :from => 'foo')

            expect(status).to be_a Dial::DialStatus
            joined_status = status.joins[status.calls.first]
            expect(joined_status.duration).to eq(0.0)
            expect(joined_status.result).to eq(:no_answer)
          end
          sleep 0.1
          other_mock_call << mock_end
          expect(dial_thread.join).to be_truthy
        end

        it "should default the caller ID to that of the original call" do
          allow(call).to receive_messages :from => 'sip:foo@bar.com'
          expect(OutboundCall).to receive(:new).and_return other_mock_call
          expect(other_mock_call).to receive(:dial).with(to, :from => 'sip:foo@bar.com').once
          dial_thread = Thread.new do
            subject.dial to
          end
          sleep 0.1
          other_mock_call << mock_end
          expect(dial_thread.join).to be_truthy
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
            expect(other_mock_call).to receive(:dial).once.with(to, options)
            expect(OutboundCall).to receive(:new).and_return other_mock_call
          end

          it "blocks the original controller until the new call ends" do
            dial_in_thread

            expect(latch.wait(2)).to be_falsey

            other_mock_call << mock_end

            expect(latch.wait(2)).to be_truthy
          end

          it "unblocks the original controller if the original call ends" do
            expect(other_mock_call).to receive(:hangup).once
            dial_in_thread

            expect(latch.wait(2)).to be_falsey

            call << mock_end

            expect(latch.wait(2)).to be_truthy
          end

          it "joins the new call to the existing one on answer" do
            expect(call).to receive(:answer).once
            expect(other_mock_call).to receive(:join).once.with(call)

            dial_in_thread

            expect(latch.wait(2)).to be_falsey

            other_mock_call << mock_answered
            other_mock_call << mock_end

            expect(latch.wait(2)).to be_truthy
          end

          context "with a join target specified" do
            let(:options) { { join_target: { mixer_name: 'foobar' } } }

            it "joins the calls to the specified target on answer" do
              expect(call).to receive(:answer).once
              expect(call).to receive(:join).once.with(Hash(mixer_name: 'foobar'))
              expect(other_mock_call).to receive(:join).once.with(Hash(mixer_name: 'foobar'))

              dial_in_thread

              expect(latch.wait(2)).to be_falsey

              other_mock_call << mock_answered
              other_mock_call << mock_end

              expect(latch.wait(2)).to be_truthy
            end
          end

          context "with a pre-join callback specified" do
            let(:foo) { double }
            let(:options) { { pre_join: ->(call) { foo.bar call } } }

            it "executes the callback prior to joining" do
              expect(foo).to receive(:bar).once.with(other_mock_call).ordered
              expect(call).to receive(:answer).once.ordered
              expect(other_mock_call).to receive(:join).once.with(call).ordered

              dial_in_thread

              expect(latch.wait(2)).to be_falsey

              other_mock_call << mock_answered
              other_mock_call << mock_end

              expect(latch.wait(2)).to be_truthy
            end
          end

          context "with ringback specified" do
            let(:component) { Adhearsion::Rayo::Component::Output.new }
            let(:options) { { ringback: ['file://tt-monkeys'] } }

            before do
              component.request!
              component.execute!
            end

            it "plays the ringback asynchronously, terminating prior to joining" do
              expect(subject).to receive(:play!).once.with(['file://tt-monkeys'], repeat_times: 0).and_return(component)
              expect(component).to receive(:stop!).twice
              expect(call).to receive(:answer).once.ordered
              expect(other_mock_call).to receive(:join).once.with(call).ordered

              dial_in_thread

              expect(latch.wait(2)).to be_falsey

              other_mock_call << mock_answered
              other_mock_call << mock_end

              expect(latch.wait(2)).to be_truthy
            end

            context "as a callback" do
              let(:foo) { double }
              let(:options) { { ringback: -> { foo.bar; component } } }

              it "calls the callback to start, and uses the return value of the callback to stop the ringback" do
                expect(foo).to receive(:bar).once.ordered
                expect(component).to receive(:stop!).twice
                expect(call).to receive(:answer).once.ordered
                expect(other_mock_call).to receive(:join).once.with(call).ordered

                dial_in_thread

                expect(latch.wait(2)).to be_falsey

                other_mock_call << mock_answered
                other_mock_call << mock_end

                expect(latch.wait(2)).to be_truthy
              end
            end

            context "when the call is rejected" do
              it "terminates the ringback before returning" do
                expect(subject).to receive(:play!).once.with(['file://tt-monkeys'], repeat_times: 0).and_return(component)
                expect(component).to receive(:stop!).once

                t = dial_in_thread

                expect(latch.wait(2)).to be_falsey

                other_mock_call << mock_end(:reject)

                expect(latch.wait(2)).to be_truthy
              end
            end
          end

          it "hangs up the new call when the root call ends" do
            expect(other_mock_call).to receive(:hangup).once
            expect(call).to receive(:answer).once
            expect(other_mock_call).to receive(:join).once.with(call)

            dial_in_thread

            expect(latch.wait(2)).to be_falsey

            other_mock_call << mock_answered
            call << mock_end

            expect(latch.wait(2)).to be_truthy
          end

          context "when the call is rejected" do
            it "has an overall dial status of :no_answer" do
              t = dial_in_thread

              sleep 0.5

              other_mock_call << mock_end(:reject)

              expect(latch.wait(2)).to be_truthy

              t.join
              status = t.value
              expect(status.result).to eq(:no_answer)
            end
          end

          context "when the call ends with an error" do
            it "has an overall dial status of :error" do
              t = dial_in_thread

              sleep 0.5

              other_mock_call << mock_end(:error)

              expect(latch.wait(2)).to be_truthy

              t.join
              status = t.value
              expect(status.result).to eq(:error)

              joined_status = status.joins[status.calls.first]
              expect(joined_status.duration).to eq(0.0)
              expect(joined_status.result).to eq(:error)
            end
          end

          context "when the call is answered and joined" do
            it "has an overall dial status of :answer" do
              expect(call).to receive(:answer).once
              expect(other_mock_call).to receive(:join).once.with(call) do
                call << Adhearsion::Event::Joined.new(call_uri: other_mock_call.id)
                other_mock_call << Adhearsion::Event::Joined.new(call_uri: call.id)
              end

              t = dial_in_thread

              sleep 0.5

              other_mock_call << mock_answered
              other_mock_call << mock_end

              expect(latch.wait(2)).to be_truthy

              t.join
              status = t.value
              expect(status.result).to eq(:answer)

              joined_status = status.joins[status.calls.first]
              expect(joined_status.result).to eq(:joined)
            end

            it "records the duration of the join" do
              expect(call).to receive(:answer).once
              expect(other_mock_call).to receive(:join).once.with(call) do
                call << Adhearsion::Event::Joined.new(call_uri: other_mock_call.id)
                other_mock_call << Adhearsion::Event::Joined.new(call_uri: call.id)
              end
              allow(other_mock_call).to receive_messages hangup: true

              t = dial_in_thread

              sleep 0.5

              base_time = Time.local(2008, 9, 1, 12, 0, 0)
              Timecop.freeze base_time

              other_mock_call << mock_answered

              base_time = Time.local(2008, 9, 1, 12, 0, 37)
              Timecop.freeze base_time
              other_mock_call << Adhearsion::Event::Unjoined.new(call_uri: call.id)
              other_mock_call << mock_end

              expect(latch.wait(2)).to be_truthy

              t.join
              status = t.value
              expect(status.result).to eq(:answer)
              joined_status = status.joins[status.calls.first]
              expect(joined_status.duration).to eq(37.0)
            end

            context "when join options are specified" do
              let(:options) { { join_options: {media: :direct} } }

              it "joins the calls with those options" do
                expect(call).to receive(:answer).once
                expect(other_mock_call).to receive(:join).once.with(call, media: :direct) do
                  call << Adhearsion::Event::Joined.new(call_uri: other_mock_call.id)
                  other_mock_call << Adhearsion::Event::Joined.new(call_uri: call.id)
                end
                allow(other_mock_call).to receive_messages hangup: true

                t = dial_in_thread

                sleep 0.5

                other_mock_call << mock_answered

                other_mock_call << Adhearsion::Event::Unjoined.new(call_uri: call.id)
                other_mock_call << mock_end

                expect(latch.wait(2)).to be_truthy

                t.join
              end
            end
          end

          context "when a dial is split" do
            let(:join_target) { call }

            before do
              expect(call).to receive(:answer).once
              expect(other_mock_call).to receive(:join).once.with(join_target, **join_options) do
                call << Adhearsion::Event::Joined.new(call_uri: other_mock_call.id)
                other_mock_call << Adhearsion::Event::Joined.new(call_uri: call.id)
              end
              allow(other_mock_call).to receive(:unjoin) do
                call << Adhearsion::Event::Unjoined.new(call_uri: other_mock_call.id)
                other_mock_call << Adhearsion::Event::Unjoined.new(call_uri: call.id)
              end
            end

            it "should unjoin the calls" do
              expect(other_mock_call).to receive(:unjoin).once.ordered.with(call) do
                call << Adhearsion::Event::Unjoined.new(call_uri: other_mock_call.id)
                other_mock_call << Adhearsion::Event::Unjoined.new(call_uri: call.id)
              end

              dial = Dial::Dial.new(to, options, call)
              dial.run(subject)

              waiter_thread = Thread.new do
                dial.await_completion
                latch.countdown!
              end

              sleep 0.5

              other_mock_call << mock_answered

              dial.split
              other_mock_call << mock_end

              expect(latch.wait(2)).to be_truthy

              waiter_thread.join
              expect(dial.status.result).to eq(:answer)
            end

            it "should not unblock immediately" do
              dial = Dial::Dial.new to, options, call
              dial.run subject

              waiter_thread = Thread.new do
                dial.await_completion
                latch.countdown!
              end

              sleep 0.5

              other_mock_call << mock_answered

              dial.split

              expect(latch.wait(2)).to be_falsey

              other_mock_call << mock_end

              expect(latch.wait(2)).to be_truthy

              waiter_thread.join
              expect(dial.status.result).to eq(:answer)
            end

            it "should set end time" do
              dial = Dial::Dial.new to, options, call
              dial.run subject

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

              expect(latch.wait(2)).to be_truthy

              waiter_thread.join
              status = dial.status
              expect(status.result).to eq(:answer)
              joined_status = status.joins[status.calls.first]
              expect(joined_status.duration).to eq(37.0)
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
                dial.run subject

                waiter_thread = Thread.new do
                  dial.await_completion
                  latch.countdown!
                end

                sleep 0.5

                other_mock_call << mock_answered

                expect(self).to receive(:callback).once.with(call)
                expect(self).to receive(:callback).once.with(other_mock_call)

                dial.split main: main_split_controller, others: others_split_controller, main_callback: ->(call) { self.callback(call) }, others_callback: ->(call) { self.callback(call) }

                expect(latch.wait(2)).to be_falsey
                expect(split_latch.wait(2)).to be_truthy

                expect(call['hit_split_controller']).to eq(main_split_controller)
                expect(call['split_controller_metadata']['current_dial']).to be dial

                expect(other_mock_call['hit_split_controller']).to eq(others_split_controller)
                expect(other_mock_call['split_controller_metadata']['current_dial']).to be dial

                other_mock_call << mock_end

                expect(latch.wait(2)).to be_truthy

                waiter_thread.join
                expect(dial.status.result).to eq(:answer)
              end
            end

            context "when rejoining" do
              it "should rejoin the calls" do
                expect(other_mock_call).to receive(:unjoin).once.ordered.with(call) do
                  call << Adhearsion::Event::Unjoined.new(call_uri: other_mock_call.id)
                  other_mock_call << Adhearsion::Event::Unjoined.new(call_uri: call.id)
                end

                dial = Dial::Dial.new to, options, call
                dial.run subject

                waiter_thread = Thread.new do
                  dial.await_completion
                  latch.countdown!
                end

                sleep 0.5

                other_mock_call << mock_answered

                dial.split

                expect(other_mock_call).to receive(:join).once.ordered.with(call) do
                  call << Adhearsion::Event::Joined.new(call_uri: other_mock_call.id)
                  other_mock_call << Adhearsion::Event::Joined.new(call_uri: call.id)
                end
                dial.rejoin

                other_mock_call << mock_end

                expect(latch.wait(2)).to be_truthy

                waiter_thread.join
                expect(dial.status.result).to eq(:answer)
              end

              context "when join options were set originally" do
                let(:options) { { join_options: {media: :direct} } }

                it "should rejoin with the same parameters" do
                  allow(other_mock_call).to receive(:unjoin)

                  dial = Dial::Dial.new to, options, call
                  dial.run subject

                  other_mock_call << mock_answered

                  dial.split

                  expect(other_mock_call).to receive(:join).once.ordered.with(call, media: :direct) do
                    call << Adhearsion::Event::Joined.new(call_uri: other_mock_call.id)
                    other_mock_call << Adhearsion::Event::Joined.new(call_uri: call.id)
                  end
                  dial.rejoin
                end
              end

              context "when join options are passed to rejoin" do
                it "should rejoin with those parameters" do
                  allow(other_mock_call).to receive(:unjoin)

                  dial = Dial::Dial.new to, options, call
                  dial.run subject

                  other_mock_call << mock_answered

                  dial.split

                  expect(other_mock_call).to receive(:join).once.ordered.with(call, media: :direct) do
                    call << Adhearsion::Event::Joined.new(call_uri: other_mock_call.id)
                    other_mock_call << Adhearsion::Event::Joined.new(call_uri: call.id)
                  end
                  dial.rejoin nil, media: :direct
                end
              end

              context "when a join target was originally specified" do
                let(:join_target) { {mixer_name: 'foobar'} }
                let(:options) { { join_target: join_target } }

                it "joins the calls to the specified target on answer" do
                  expect(call).to receive(:join).once.with(join_target)
                  expect(other_mock_call).to receive(:unjoin).once.ordered.with(join_target)
                  expect(call).to receive(:unjoin).once.ordered.with(join_target) do
                    call << Adhearsion::Event::Unjoined.new(join_target)
                    other_mock_call << Adhearsion::Event::Unjoined.new(join_target)
                  end

                  dial = Dial::Dial.new to, options, call
                  dial.run subject

                  waiter_thread = Thread.new do
                    dial.await_completion
                    latch.countdown!
                  end

                  sleep 0.5

                  other_mock_call << mock_answered

                  dial.split

                  expect(call).to receive(:join).once.ordered.with(Hash(mixer_name: 'foobar'))
                  expect(other_mock_call).to receive(:join).once.ordered.with(Hash(mixer_name: 'foobar'))
                  dial.rejoin

                  other_mock_call << mock_end

                  expect(latch.wait(2)).to be_truthy

                  waiter_thread.join
                  expect(dial.status.result).to eq(:answer)
                end
              end

              context "to a specified mixer" do
                let(:mixer) { SecureRandom.uuid }

                it "should join all calls to the mixer" do
                  expect(other_mock_call).to receive(:unjoin).once.ordered.with(call) do
                    call << Adhearsion::Event::Unjoined.new(call_uri: other_mock_call.id)
                    other_mock_call << Adhearsion::Event::Unjoined.new(call_uri: call.id)
                  end

                  dial = Dial::Dial.new to, options, call
                  dial.run subject

                  waiter_thread = Thread.new do
                    dial.await_completion
                    latch.countdown!
                  end

                  sleep 0.5

                  other_mock_call << mock_answered

                  dial.split

                  expect(call).to receive(:join).once.ordered.with(Hash(mixer_name: mixer))
                  expect(other_mock_call).to receive(:join).once.ordered.with(Hash(mixer_name: mixer))
                  dial.rejoin(mixer_name: mixer)

                  other_mock_call << mock_end

                  expect(latch.wait(2)).to be_truthy

                  waiter_thread.join
                  expect(dial.status.result).to eq(:answer)
                end

                it "#split should then unjoin calls from the mixer" do
                  expect(other_mock_call).to receive(:unjoin).once.ordered.with(call) do
                    call << Adhearsion::Event::Unjoined.new(call_uri: other_mock_call.id)
                    other_mock_call << Adhearsion::Event::Unjoined.new(call_uri: call.id)
                  end

                  dial = Dial::Dial.new to, options, call
                  dial.run subject

                  waiter_thread = Thread.new do
                    dial.await_completion
                    latch.countdown!
                  end

                  sleep 0.5

                  other_mock_call << mock_answered

                  dial.split

                  expect(call).to receive(:join).once.ordered.with(Hash(mixer_name: mixer))
                  expect(other_mock_call).to receive(:join).once.ordered.with(Hash(mixer_name: mixer))
                  dial.rejoin(mixer_name: mixer)

                  expect(other_mock_call).to receive(:unjoin).once.ordered.with(Hash(mixer_name: mixer)) do
                    other_mock_call << Adhearsion::Event::Unjoined.new(mixer_name: mixer)
                  end
                  expect(call).to receive(:unjoin).once.ordered.with(Hash(mixer_name: mixer)) do
                    call << Adhearsion::Event::Unjoined.new(mixer_name: mixer)
                  end
                  dial.split

                  other_mock_call << mock_end

                  expect(latch.wait(2)).to be_truthy

                  waiter_thread.join
                  expect(dial.status.result).to eq(:answer)
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
                allow(second_root_call).to receive_messages write_command: true, id: second_root_call_id
                expect(OutboundCall).to receive(:new).and_return second_other_mock_call
                expect(second_other_mock_call).to receive(:join).once.with(second_root_call)
                expect(second_other_mock_call).to receive(:dial).once.with(second_to, options)
                expect(second_root_call).to receive(:answer).once

                allow(SecureRandom).to receive_messages uuid: mixer

                dial.run subject
                other_dial.run subject

                other_mock_call << mock_answered
                second_other_mock_call << mock_answered
              end

              it "should split calls, rejoin to a mixer, and rejoin other calls to mixer" do
                expect(other_mock_call).to receive(:unjoin).once.ordered.with(call) do
                  call << Adhearsion::Event::Unjoined.new(call_uri: other_mock_call.id)
                  other_mock_call << Adhearsion::Event::Unjoined.new(call_uri: call.id)
                end
                expect(second_other_mock_call).to receive(:unjoin).once.ordered.with(second_root_call) do
                  second_root_call << Adhearsion::Event::Unjoined.new(call_uri: second_other_mock_call.id)
                  second_other_mock_call << Adhearsion::Event::Unjoined.new(call_uri: second_root_call.id)
                end

                expect(call).to receive(:join).once.ordered.with(Hash(mixer_name: mixer))
                expect(other_mock_call).to receive(:join).once.ordered.with(Hash(mixer_name: mixer))

                expect(second_root_call).to receive(:join).once.ordered.with(Hash(mixer_name: mixer))
                expect(second_other_mock_call).to receive(:join).once.ordered.with(Hash(mixer_name: mixer))

                dial.merge(other_dial)

                waiter_thread = Thread.new do
                  dial.await_completion
                  latch.countdown!
                end

                sleep 0.5

                other_mock_call.async << mock_end
                second_root_call.async << mock_end
                second_other_mock_call.async << mock_end

                expect(latch.wait(2)).to be_truthy

                waiter_thread.join
                expect(dial.status.result).to eq(:answer)
              end

              context "when join options were specified originally" do
                let(:options) { { join_options: {media: :direct} } }

                it "should rejoin with default options" do
                  allow(other_mock_call).to receive(:unjoin)
                  allow(second_other_mock_call).to receive(:unjoin)

                  expect(call).to receive(:join).once.ordered.with(Hash(mixer_name: mixer))
                  expect(other_mock_call).to receive(:join).once.ordered.with(Hash(mixer_name: mixer))

                  expect(second_root_call).to receive(:join).once.ordered.with(Hash(mixer_name: mixer))
                  expect(second_other_mock_call).to receive(:join).once.ordered.with(Hash(mixer_name: mixer))

                  dial.merge other_dial
                end
              end

              it "should add the merged calls to the returned status" do
                [call, other_mock_call, second_root_call, second_other_mock_call].each { |c| allow(c).to receive_messages join: true, unjoin: true }
                dial.merge other_dial

                waiter_thread = Thread.new do
                  dial.await_completion
                  latch.countdown!
                end

                sleep 0.5

                other_mock_call.async << mock_end
                second_root_call.async << mock_end
                second_other_mock_call.async << mock_end

                expect(latch.wait(2)).to be_truthy

                waiter_thread.join
                expect(dial.status.result).to eq(:answer)
                expect(dial.status.calls).to include(second_root_call, second_other_mock_call)
              end

              it "should not unblock until all joined calls end" do
                [call, other_mock_call, second_root_call, second_other_mock_call].each { |c| allow(c).to receive_messages join: true, unjoin: true }

                dial.merge other_dial

                waiter_thread = Thread.new do
                  dial.await_completion
                  latch.countdown!
                end

                sleep 0.5

                other_mock_call << mock_end
                expect(latch.wait(2)).to be_falsey

                second_other_mock_call << mock_end
                expect(latch.wait(2)).to be_falsey

                second_root_call << mock_end
                expect(latch.wait(2)).to be_truthy

                waiter_thread.join
                expect(dial.status.result).to eq(:answer)
              end

              it "should cleanup merged calls when the root call ends" do
                [call, other_mock_call, second_root_call, second_other_mock_call].each do |c|
                  allow(c).to receive_messages join: true, unjoin: true
                end
                [other_mock_call, second_root_call, second_other_mock_call].each do |c|
                  expect(c).to receive(:hangup).once
                end

                dial.merge other_dial

                waiter_thread = Thread.new do
                  dial.await_completion
                  dial.cleanup_calls
                  latch.countdown!
                end

                sleep 0.5

                call << mock_end
                expect(latch.wait(2)).to be_truthy

                waiter_thread.join
                expect(dial.status.result).to eq(:answer)
              end

              it "should subsequently rejoin to a mixer" do
                [call, other_mock_call, second_root_call, second_other_mock_call].each { |c| allow(c).to receive_messages join: true, unjoin: true }

                dial.merge other_dial

                waiter_thread = Thread.new do
                  dial.await_completion
                  latch.countdown!
                end

                sleep 0.5

                other_mock_call << mock_end
                expect(latch.wait(2)).to be_falsey

                [call, second_root_call, second_other_mock_call].each do |call|
                  expect(call).to receive(:unjoin).once.with(Hash(mixer_name: mixer)) do
                    call << Adhearsion::Event::Unjoined.new(mixer_name: mixer)
                  end
                end

                dial.split

                [call, other_mock_call, second_root_call, second_other_mock_call].each do |call|
                  expect(call).to receive(:join).once.with(Hash(mixer_name: mixer)) do
                    call << Adhearsion::Event::Joined.new(mixer_name: mixer)
                  end
                end

                dial.rejoin
              end

              describe "if splitting fails" do
                it "should not add the merged calls to the returned status" do
                  [call, other_mock_call, second_root_call, second_other_mock_call].each { |c| allow(c).to receive_messages join: true, unjoin: true }
                  expect(other_dial).to receive(:split).and_raise StandardError
                  expect { dial.merge other_dial }.to raise_error(StandardError)

                  waiter_thread = Thread.new do
                    dial.await_completion
                    latch.countdown!
                  end

                  sleep 0.5

                  other_mock_call.async << mock_end
                  second_root_call.async << mock_end
                  second_other_mock_call.async << mock_end

                  expect(latch.wait(2)).to be_truthy

                  waiter_thread.join
                  expect(dial.status.result).to eq(:answer)
                  expect(dial.status.calls).not_to include(second_root_call, second_other_mock_call)
                end

                it "should unblock before all joined calls end" do
                  [call, other_mock_call, second_root_call, second_other_mock_call].each { |c| allow(c).to receive_messages join: true, unjoin: true }

                  expect(other_dial).to receive(:split).and_raise StandardError
                  expect { dial.merge other_dial }.to raise_error(StandardError)

                  waiter_thread = Thread.new do
                    dial.await_completion
                    latch.countdown!
                  end

                  sleep 0.5

                  other_mock_call << mock_end
                  expect(latch.wait(2)).to be_truthy

                  second_other_mock_call << mock_end
                  expect(latch.wait(2)).to be_truthy

                  second_root_call << mock_end
                  expect(latch.wait(2)).to be_truthy

                  waiter_thread.join
                  expect(dial.status.result).to eq(:answer)
                end

                it "should not cleanup merged calls when the root call ends" do
                  [call, other_mock_call, second_root_call, second_other_mock_call].each do |c|
                    allow(c).to receive_messages join: true, unjoin: true
                  end
                  expect(other_mock_call).to receive(:hangup).once
                  [second_root_call, second_other_mock_call].each do |c|
                    expect(c).to receive(:hangup).never
                  end

                  expect(other_dial).to receive(:split).and_raise StandardError
                  expect { dial.merge other_dial }.to raise_error(StandardError)

                  waiter_thread = Thread.new do
                    dial.await_completion
                    dial.cleanup_calls
                    latch.countdown!
                  end

                  sleep 0.5

                  call << mock_end
                  expect(latch.wait(2)).to be_truthy

                  waiter_thread.join
                  expect(dial.status.result).to eq(:answer)
                end
              end

              context "if a call hangs up" do
                it "should still allow splitting and rejoining" do
                  [call, other_mock_call, second_root_call, second_other_mock_call].each { |c| allow(c).to receive_messages join: true, unjoin: true }

                  dial.merge other_dial

                  waiter_thread = Thread.new do
                    dial.await_completion
                    latch.countdown!
                  end

                  sleep 0.5

                  [call, second_root_call, second_other_mock_call].each do |call|
                    expect(call).to receive(:unjoin).once.with(Hash(mixer_name: mixer)) do
                      call << Adhearsion::Event::Unjoined.new(mixer_name: mixer)
                    end
                  end

                  expect(other_mock_call).to receive(:unjoin).and_raise Adhearsion::Call::Hangup

                  dial.split

                  other_mock_call << mock_end
                  expect(latch.wait(2)).to be_falsey

                  [call, second_root_call, second_other_mock_call].each do |call|
                    expect(call).to receive(:join).once.with(Hash(mixer_name: mixer)) do
                      call << Adhearsion::Event::Joined.new(mixer_name: mixer)
                    end
                  end

                  expect(other_mock_call).to receive(:join).and_raise Adhearsion::Call::ExpiredError

                  dial.rejoin
                end
              end

              context "if the calls were not joined" do
                it "should still join to mixer" do
                  expect(other_mock_call).to receive(:unjoin).once.ordered.with(call).and_raise Adhearsion::ProtocolError.new.setup(:service_unavailable)
                  expect(second_other_mock_call).to receive(:unjoin).once.ordered.with(second_root_call).and_raise Adhearsion::ProtocolError.new.setup(:service_unavailable)

                  expect(call).to receive(:join).once.ordered.with(Hash(mixer_name: mixer))
                  expect(other_mock_call).to receive(:join).once.ordered.with(Hash(mixer_name: mixer))

                  expect(second_root_call).to receive(:join).once.ordered.with(Hash(mixer_name: mixer))
                  expect(second_other_mock_call).to receive(:join).once.ordered.with(Hash(mixer_name: mixer))

                  dial.merge other_dial

                  waiter_thread = Thread.new do
                    dial.await_completion
                    latch.countdown!
                  end

                  sleep 0.5

                  other_mock_call.async << mock_end
                  second_root_call.async << mock_end
                  second_other_mock_call.async << mock_end

                  expect(latch.wait(2)).to be_truthy

                  waiter_thread.join
                  expect(dial.status.result).to eq(:answer)
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
            expect(OutboundCall).to receive(:new).never
            expect { subject.dial to, options }.to raise_error(Call::Hangup)
          end
        end

        describe "with multiple third parties specified" do
          let(:options) { {} }
          let(:other_options) { options }
          let(:second_other_options) { options }

          before do
            expect(OutboundCall).to receive(:new).and_return other_mock_call, second_other_mock_call

            expect(other_mock_call).to receive(:dial).once.with(to, other_options)

            expect(second_other_mock_call).to receive(:dial).once.with(second_to, second_other_options)
            expect(second_other_mock_call).to receive(:join).never
          end

          def dial_in_thread
            Thread.new do
              status = subject.dial [to, second_to], options
              latch.countdown!
              status
            end
          end

          it "dials all parties and joins the first one to answer, hanging up the rest" do
            expect(call).to receive(:answer).once
            expect(other_mock_call).to receive(:join).once.with(call)
            expect(second_other_mock_call).to receive(:hangup).once do
              second_other_mock_call << mock_end
            end

            t = dial_in_thread

            expect(latch.wait(2)).to be_falsey

            other_mock_call << mock_answered
            other_mock_call << mock_end

            expect(latch.wait(2)).to be_truthy

            t.join
            status = t.value
            expect(status).to be_a Dial::DialStatus
            expect(status.calls.size).to eq(2)
            status.calls.each { |c| expect(c).to be_a OutboundCall }
          end

          it "unblocks when the joined call unjoins, allowing it to proceed further" do
            expect(call).to receive(:answer).once
            expect(other_mock_call).to receive(:join).once.with(call)
            expect(other_mock_call).to receive(:hangup).once
            expect(second_other_mock_call).to receive(:hangup).once do
              second_other_mock_call << mock_end
            end

            t = dial_in_thread

            expect(latch.wait(2)).to be_falsey

            other_mock_call << mock_answered
            other_mock_call << Adhearsion::Event::Unjoined.new(call_uri: call.id)

            expect(latch.wait(2)).to be_truthy

            t.join
            status = t.value
            expect(status).to be_a Dial::DialStatus
            expect(status.calls.size).to eq(2)
            status.calls.each { |c| expect(c).to be_a OutboundCall }
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

              expect(latch.wait(2)).to be_falsey
              other_mock_call << mock_end
              expect(latch.wait(2)).to be_falsey
              second_other_mock_call << mock_end
              expect(latch.wait(2)).to be_truthy
              t.join
            end
          end

          context "when all calls are rejected" do
            it "has an overall dial status of :no_answer" do
              t = dial_in_thread

              sleep 0.5

              other_mock_call << mock_end(:reject)
              second_other_mock_call << mock_end(:reject)

              expect(latch.wait(2)).to be_truthy

              t.join
              status = t.value
              expect(status.result).to eq(:no_answer)
            end
          end

          context "when a call is answered and joined, and the other ends with an error" do
            it "has an overall dial status of :answer" do
              expect(call).to receive(:answer).once
              expect(other_mock_call).to receive(:join).once.with(call)
              expect(second_other_mock_call).to receive(:hangup).once do
                second_other_mock_call << mock_end(:error)
              end

              t = dial_in_thread

              sleep 0.5

              other_mock_call << mock_answered
              other_mock_call << mock_end

              expect(latch.wait(2)).to be_truthy

              t.join
              status = t.value
              expect(status.result).to eq(:answer)
            end
          end
        end

        describe "with a timeout specified" do
          let(:timeout) { 3 }

          it "should abort the dial after the specified timeout" do
            expect(other_mock_call).to receive(:dial).once
            expect(other_mock_call).to receive(:hangup).once
            expect(OutboundCall).to receive(:new).and_return other_mock_call

            time = Time.now

            t = Thread.new do
              status = subject.dial to, :timeout => timeout
              latch.countdown!
              status
            end

            latch.wait
            time = Time.now - time
            expect(time.round).to eq(timeout)
            t.join
            status = t.value
            expect(status.result).to eq(:timeout)
          end

          describe "if someone answers before the timeout elapses" do
            it "should not abort until the far end hangs up" do
              expect(other_mock_call).to receive(:dial).once.with(to, hash_including(:timeout => timeout))
              expect(call).to receive(:answer).once
              expect(other_mock_call).to receive(:join).once.with(call)
              expect(OutboundCall).to receive(:new).and_return other_mock_call

              time = Time.now

              t = Thread.new do
                status = subject.dial to, :timeout => timeout
                latch.countdown!
                status
              end

              expect(latch.wait(2)).to be_falsey

              other_mock_call << mock_answered

              expect(latch.wait(2)).to be_falsey

              other_mock_call << mock_end

              expect(latch.wait(0.1)).to be_truthy
              time = Time.now - time
              expect(time.to_i).to be > timeout
              t.join
              status = t.value
              expect(status.result).to eq(:answer)
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
              expect(other_mock_call).to receive(:dial).once
              expect(OutboundCall).to receive(:new).and_return other_mock_call
            end

            it "should set the metadata on the controller" do
              expect(other_mock_call).to receive(:hangup).once do
                other_mock_call << mock_end
              end
              other_mock_call['confirm'] = false

              dial_in_thread

              expect(latch.wait(0.1)).to be_falsey

              other_mock_call << mock_answered

              expect(confirmation_latch.wait(2)).to be_truthy
              expect(latch.wait(2)).to be_truthy

              expect(other_mock_call[:foo]).to eq('bar')
            end
          end

          context "when an outbound call is answered" do
            before do
              expect(other_mock_call).to receive(:dial).once
              expect(OutboundCall).to receive(:new).and_return other_mock_call
            end

            it "should execute the specified confirmation controller" do
              expect(other_mock_call).to receive(:hangup).once do
                other_mock_call << mock_end
              end
              other_mock_call['confirm'] = false

              dial_in_thread

              expect(latch.wait(0.1)).to be_falsey

              other_mock_call << mock_answered

              expect(confirmation_latch.wait(2)).to be_truthy
              expect(latch.wait(2)).to be_truthy
            end

            it "should join the calls if the call is still active after execution of the call controller" do
              expect(other_mock_call).to receive(:hangup).once do
                other_mock_call << mock_end
              end
              other_mock_call['confirm'] = true
              expect(call).to receive(:answer).once
              expect(other_mock_call).to receive(:join).once.with(call) do
                call << Adhearsion::Event::Joined.new(call_uri: other_mock_call.id)
                other_mock_call << Adhearsion::Event::Joined.new(call_uri: call.id)
              end

              t = dial_in_thread

              expect(latch.wait(2)).to be_falsey

              base_time = Time.local(2008, 9, 1, 12, 0, 0)
              Timecop.freeze base_time

              other_mock_call << mock_answered

              base_time = Time.local(2008, 9, 1, 12, 0, 42)
              Timecop.freeze base_time
              other_mock_call << Adhearsion::Event::Unjoined.new(call_uri: call.id)

              expect(latch.wait(2)).to be_truthy

              t.join
              status = t.value
              expect(status.result).to eq(:answer)

              joined_status = status.joins[status.calls.first]
              expect(joined_status.duration).to eq(42.0)
              expect(joined_status.result).to eq(:joined)
            end

            it "should not join the calls if the call is not active after execution of the call controller" do
              expect(other_mock_call).to receive(:hangup).once do
                other_mock_call << mock_end
              end
              other_mock_call['confirm'] = false
              expect(call).to receive(:answer).never
              expect(other_mock_call).to receive(:join).never.with(call)

              t = dial_in_thread

              expect(latch.wait(2)).to be_falsey

              other_mock_call << mock_answered

              expect(latch.wait(2)).to be_truthy

              t.join
              status = t.value
              expect(status.result).to eq(:unconfirmed)

              joined_status = status.joins[status.calls.first]
              expect(joined_status.duration).to eq(0.0)
              expect(joined_status.result).to eq(:unconfirmed)
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
              expect(OutboundCall).to receive(:new).and_return other_mock_call, second_other_mock_call
            end

            def dial_in_thread
              Thread.new do
                status = subject.dial [to, second_to], options
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

                expect(call).to receive(:answer).once

                expect(other_mock_call).to receive(:dial).once.with(to, from: nil)
                expect(other_mock_call).to receive(:join).once.with(call) do
                  call << Adhearsion::Event::Joined.new(call_uri: other_mock_call.id)
                  other_mock_call << Adhearsion::Event::Joined.new(call_uri: call.id)
                end
                expect(other_mock_call).to receive(:hangup).once do
                  other_mock_call.async.deliver_message mock_end
                end

                expect(second_other_mock_call).to receive(:dial).once.with(second_to, from: nil)
                expect(second_other_mock_call).to receive(:join).never
                expect(second_other_mock_call).to receive(:hangup).once do
                  second_other_mock_call.async.deliver_message mock_end
                end

                t = dial_in_thread

                expect(latch.wait(2)).to be_falsey

                other_mock_call.async.deliver_message mock_answered
                second_other_mock_call.async.deliver_message mock_answered
                expect(confirmation_latch.wait(2)).to be_truthy

                sleep 2

                other_mock_call.async.deliver_message Adhearsion::Event::Unjoined.new(call_uri: call.id)

                expect(latch.wait(2)).to be_truthy

                expect(second_other_mock_call['apology_done']).to be_truthy
                expect(second_other_mock_call['apology_metadata']).to eq({'foo' => 'bar'})

                t.join
                status = t.value
                expect(status).to be_a Dial::DialStatus
                expect(status.calls.size).to eq(2)
                status.calls.each { |c| expect(c).to be_a OutboundCall }
                expect(status.result).to eq(:answer)
                expect(status.joins[other_mock_call].result).to eq(:joined)
                expect(status.joins[second_other_mock_call].result).to eq(:lost_confirmation)
              end
            end
          end
        end

        context 'when given a block with one argument' do
          before(:each) do
            expect(other_mock_call).to receive(:dial).with(to, options).once
            expect(OutboundCall).to receive(:new).and_return other_mock_call
          end
          let(:options) { { timeout: 1.0 } }
          let(:yield_latch) { CountDownLatch.new 1 }
          let(:thread_latch) { CountDownLatch.new 1 }

          it 'yields a block on the dial obj' do
            @dial_obj = Concurrent::AtomicReference.new
            my_dial_block = proc do |dial|
              @dial_obj.set dial
              yield_latch.countdown!
            end
            Thread.new do
              subject.dial to, options, &my_dial_block
              thread_latch.countdown!
            end
            expect(yield_latch.count.zero? || yield_latch.wait(1)).to be_truthy
            expect(@dial_obj.get).to be_instance_of Dial::Dial
            other_mock_call << mock_end
            expect(thread_latch.count.zero? || thread_latch.wait(2)).to be_truthy
          end
        end
      end

      describe Dial::Dial do
        subject { Dial::Dial.new to, {}, call }

        describe "#prep_calls" do
          it "yields all calls to the passed block" do
            expect(OutboundCall).to receive(:new).and_return other_mock_call

            gathered_calls = []
            subject.prep_calls { |call| gathered_calls << call }

            expect(gathered_calls).to include(other_mock_call)
          end
        end

        context "#skip_cleanup" do
          it "allows the new call to continue after the root call ends" do
            expect(OutboundCall).to receive(:new).and_return other_mock_call

            allow(call).to receive_messages answer: true
            allow(other_mock_call).to receive_messages dial: true, join: true
            expect(other_mock_call).to receive(:hangup).never

            subject.run double('controller')

            subject.skip_cleanup

            Thread.new do
              subject.await_completion
              subject.cleanup_calls
              latch.countdown!
            end

            other_mock_call << mock_answered
            call << mock_end

            expect(latch.wait(2)).to be_truthy
          end
        end

        describe "#cleanup_calls" do
          let(:dial) { Dial::Dial.new to, dial_options, call }

          before do
            allow(other_mock_call).to receive_messages dial: true
            expect(OutboundCall).to receive(:new).and_return other_mock_call
          end

          context "when a Cleanup Controller is specified" do
            let(:cleanup_controller) do
              Class.new(Adhearsion::CallController) do
                def run
                  logger.info "Cleaning up..."
                end
              end
            end
            let(:dial_options) { {cleanup: cleanup_controller} }

            it "invokes the Cleanup Controller on each active outbound call before terminating the call" do
              expect(cleanup_controller).to receive(:new).with(other_mock_call, anything)
              Thread.new do
                dial.run double(Adhearsion::CallController)
                dial.cleanup_calls
                latch.countdown!
              end
              expect(latch.wait(2)).to be_truthy
            end
          end
        end
      end
    end
  end
end
