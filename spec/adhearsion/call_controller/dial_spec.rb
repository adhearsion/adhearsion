require 'spec_helper'

module Adhearsion
  class CallController
    describe Dial do
      include CallControllerTestHelpers

      let(:to) { 'sip:foo@bar.com' }
      let(:other_call_id)   { rand }
      let(:other_mock_call) { flexmock OutboundCall.new, :id => other_call_id }

      let(:second_to)               { 'sip:baz@bar.com' }
      let(:second_other_call_id)    { rand }
      let(:second_other_mock_call)  { flexmock OutboundCall.new, :id => second_other_call_id }

      let(:mock_end)      { flexmock Punchblock::Event::End.new, :reason => :hangup }
      let(:mock_answered) { Punchblock::Event::Answered.new }

      let(:latch) { CountDownLatch.new 1 }

      describe "#dial" do
        it "should dial the call to the correct endpoint and return it" do
          other_mock_call
          flexmock(OutboundCall).should_receive(:new).and_return other_mock_call
          flexmock(other_mock_call).should_receive(:dial).with(to, :from => 'foo').once
          dial_thread = Thread.new do
            subject.dial(to, :from => 'foo').should be_a OutboundCall
          end
          sleep 0.1
          other_mock_call << mock_end
          dial_thread.join.should be_true
        end

        describe "without a block" do
          it "blocks the original controller until the new call ends" do
            other_mock_call

            flexmock(other_mock_call).should_receive(:dial).once
            flexmock(OutboundCall).should_receive(:new).and_return other_mock_call

            latch = CountDownLatch.new 1

            Thread.new do
              subject.dial to
              latch.countdown!
            end

            latch.wait(1).should be_false

            other_mock_call << mock_end

            latch.wait(1).should be_true
          end

          it "joins the new call to the existing one on answer" do
            other_mock_call

            flexmock(other_mock_call).should_receive(:dial).once
            flexmock(other_mock_call).should_receive(:join).once.with(call)
            flexmock(OutboundCall).should_receive(:new).and_return other_mock_call

            latch = CountDownLatch.new 1

            Thread.new do
              subject.dial to
              latch.countdown!
            end

            latch.wait(1).should be_false

            other_mock_call << mock_answered
            other_mock_call << mock_end

            latch.wait(1).should be_true
          end
        end

        describe "with multiple third parties specified" do
          it "dials all parties and joins the first one to answer, hanging up the rest" do
            other_mock_call
            second_other_mock_call

            flexmock(other_mock_call).should_receive(:dial).once
            flexmock(other_mock_call).should_receive(:join).once.with(call)
            flexmock(other_mock_call).should_receive(:hangup).never

            flexmock(second_other_mock_call).should_receive(:dial).once
            flexmock(second_other_mock_call).should_receive(:hangup).once

            flexmock(OutboundCall).should_receive(:new).and_return other_mock_call, second_other_mock_call
            latch = CountDownLatch.new 1

            t = Thread.new do
              calls = subject.dial [to, second_to]
              latch.countdown!
              calls
            end

            latch.wait(1).should be_false

            other_mock_call << mock_answered
            other_mock_call << mock_end

            latch.wait(2).should be_true

            t.join
            calls = t.value
            calls.should have(2).calls
            calls.each { |c| c.should be_a OutboundCall }
          end
        end

        describe "with a timeout specified" do
          let(:timeout) { 3 }

          it "should abort the dial after the specified timeout" do
            other_mock_call

            flexmock(other_mock_call).should_receive(:dial).once
            flexmock(OutboundCall).should_receive(:new).and_return other_mock_call

            latch = CountDownLatch.new 1

            value = nil
            time = Time.now

            Thread.new do
              value = subject.dial to, :timeout => timeout
              latch.countdown!
            end

            latch.wait
            time = Time.now - time
            time.to_i.should == timeout
            value.should == false
          end
        end

      	describe "with a block" do
          it "uses the block as the controller for the new call"

          it "joins the new call to the existing call once the block returns"

          it "does not try to join the calls if the new call is hungup when the block returns"
        end
      end#describe #dial
    end
  end
end
