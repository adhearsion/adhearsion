# encoding: utf-8

require 'spec_helper'

module Adhearsion
  class CallController
    describe Dial do
      include CallControllerTestHelpers

      let(:to) { 'sip:foo@bar.com' }
      let(:other_call_id)   { new_uuid }
      let(:other_mock_call) { flexmock OutboundCall.new, :id => other_call_id }

      let(:second_to)               { 'sip:baz@bar.com' }
      let(:second_other_call_id)    { new_uuid }
      let(:second_other_mock_call)  { flexmock OutboundCall.new, :id => second_other_call_id }

      let(:mock_answered) { Punchblock::Event::Answered.new }

      let(:latch) { CountDownLatch.new 1 }

      def mock_end(reason = :hangup)
        flexmock Punchblock::Event::End.new, :reason => reason
      end

      describe "#dial" do
        before do
          other_mock_call
        end

        it "should dial the call to the correct endpoint and return a dial status object" do
          flexmock(OutboundCall).should_receive(:new).and_return other_mock_call
          flexmock(other_mock_call).should_receive(:dial).with(to, :from => 'foo').once
          dial_thread = Thread.new do
            subject.dial(to, :from => 'foo').should be_a Dial::DialStatus
          end
          sleep 0.1
          other_mock_call << mock_end
          dial_thread.join.should be_true
        end

        it "should default the caller ID to that of the original call" do
          flexmock call, :from => 'sip:foo@bar.com'
          flexmock(OutboundCall).should_receive(:new).and_return other_mock_call
          flexmock(other_mock_call).should_receive(:dial).with(to, :from => 'sip:foo@bar.com').once
          dial_thread = Thread.new do
            subject.dial to
          end
          sleep 0.1
          other_mock_call << mock_end
          dial_thread.join.should be_true
        end

        describe "without a block" do
          before do
            flexmock(other_mock_call).should_receive(:dial).once.with(to, options)
            flexmock(other_mock_call).should_receive(:hangup).once
            flexmock(OutboundCall).should_receive(:new).and_return other_mock_call
          end

          let(:options) { { :foo => :bar } }

          def dial_in_thread
            Thread.new do
              status = subject.dial to, options
              latch.countdown!
              status
            end
          end

          it "blocks the original controller until the new call ends" do
            dial_in_thread

            latch.wait(1).should be_false

            other_mock_call << mock_end

            latch.wait(1).should be_true
          end

          it "unblocks the original controller if the original call ends" do
            dial_in_thread

            latch.wait(1).should be_false

            call << mock_end

            latch.wait(1).should be_true
          end

          it "joins the new call to the existing one on answer" do
            flexmock(other_mock_call).should_receive(:join).once.with(call)

            dial_in_thread

            latch.wait(1).should be_false

            other_mock_call << mock_answered
            other_mock_call << mock_end

            latch.wait(1).should be_true
          end

          it "hangs up the new call when the dial unblocks" do
            flexmock(other_mock_call).should_receive(:join).once.with(call)

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
            end
          end

          context "when the call is answered and joined" do
            it "has an overall dial status of :answer" do
              flexmock(other_mock_call).should_receive(:join).once.with(call)

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

        describe "with multiple third parties specified" do
          let(:options) { {} }
          let(:other_options) { options }
          let(:second_other_options) { options }

          before do
            second_other_mock_call

            flexmock(OutboundCall).should_receive(:new).and_return other_mock_call, second_other_mock_call

            flexmock(other_mock_call).should_receive(:dial).once.with(to, other_options)
            flexmock(other_mock_call).should_receive(:hangup).once

            flexmock(second_other_mock_call).should_receive(:dial).once.with(second_to, second_other_options)
            flexmock(second_other_mock_call).should_receive(:join).never
            flexmock(second_other_mock_call).should_receive(:hangup).once
          end

          def dial_in_thread
            Thread.new do
              status = subject.dial [to, second_to], options
              latch.countdown!
              status
            end
          end

          it "dials all parties and joins the first one to answer, hanging up the rest" do
            flexmock(other_mock_call).should_receive(:join).once.with(call)
            flexmock(second_other_mock_call).should_receive(:hangup).once

            t = dial_in_thread

            latch.wait(1).should be_false

            other_mock_call << mock_answered
            other_mock_call << mock_end

            latch.wait(1).should be_false

            second_other_mock_call << mock_end

            latch.wait(2).should be_true

            t.join
            status = t.value
            status.should be_a Dial::DialStatus
            status.should have(2).calls
            status.calls.each { |c| c.should be_a OutboundCall }
          end

          it "unblocks when the joined call unjoins, allowing it to proceed further" do
            flexmock(other_mock_call).should_receive(:join).once.with(call)
            flexmock(second_other_mock_call).should_receive(:hangup).once

            t = dial_in_thread

            latch.wait(1).should be_false

            other_mock_call << mock_answered
            other_mock_call << Punchblock::Event::Unjoined.new(:call_id => call.id)

            latch.wait(1).should be_false

            second_other_mock_call << mock_end

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
              flexmock(other_mock_call).should_receive(:join).once.with(call)
              flexmock(second_other_mock_call).should_receive(:hangup).once

              t = dial_in_thread

              sleep 0.5

              other_mock_call << mock_answered
              other_mock_call << mock_end

              second_other_mock_call << mock_end(:error)

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
            flexmock(other_mock_call).should_receive(:dial).once
            flexmock(other_mock_call).should_receive(:hangup).once
            flexmock(OutboundCall).should_receive(:new).and_return other_mock_call

            time = Time.now

            t = Thread.new do
              status = subject.dial to, :timeout => timeout
              latch.countdown!
              status
            end

            latch.wait
            time = Time.now - time
            time.to_i.should be == timeout
            t.join
            status = t.value
            status.result.should be == :timeout
          end
        end
      end#describe #dial
    end
  end
end
