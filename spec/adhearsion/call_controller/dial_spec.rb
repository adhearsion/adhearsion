require 'spec_helper'

module Adhearsion
  class CallController
    describe Dial do
      include CallControllerTestHelpers

      let(:to) { 'sip:foo@bar.com' }

      let(:other_call_id) { rand }
      let(:other_mock_call) { flexmock OutboundCall.new, :id => other_call_id }

      let(:mock_end) { flexmock Punchblock::Event::End.new, :reason => :hangup }
      let(:mock_answered) { Punchblock::Event::Answered.new }

      #added for multiple dial testing
      let(:second_to) { 'sip:baz@bar.com' }
      let(:second_other_call_id) { rand }
      let(:second_other_mock_call) { flexmock OutboundCall.new, :id => second_other_call_id }

      def mock_dial
        flexmock(OutboundCall).new_instances.should_receive(:dial).and_return true
      end

      describe "#dial" do
        it "should create a new call and return it" do
          mock_dial
          Thread.new do
            subject.dial(to).should be_a OutboundCall
          end
          other_mock_call << mock_end
        end

        it "should dial the call to the correct endpoint" do
          other_mock_call
          flexmock(OutboundCall).should_receive(:new).and_return other_mock_call
          flexmock(other_mock_call).should_receive(:dial).with(to, :from => 'foo').once
          dial_thread = Thread.new do
            subject.dial to, :from => 'foo'
          end
          sleep 0.1
          other_mock_call << mock_end
          dial_thread.join.should be_true
        end

        describe "without a block" do
          it "blocks the original dialplan until the new call ends" do
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
            flexmock(other_mock_call).should_receive(:join).once.with(call_id)
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
            flexmock(other_mock_call).should_receive(:join).once.with(call_id)
            flexmock(other_mock_call).should_receive(:hangup!).never

            flexmock(second_other_mock_call).should_receive(:dial).once
            flexmock(second_other_mock_call).should_receive(:hangup!).once


            flexmock(OutboundCall).should_receive(:new).and_return other_mock_call, second_other_mock_call
            latch = CountDownLatch.new 1

            Thread.new do
              subject.dial [to, second_to]
              latch.countdown!
            end

            latch.wait(1).should be_false

            other_mock_call << mock_answered
            other_mock_call << mock_end

            latch.wait(1).should be_true
          end
        end

        describe "with a timeout specified" do
          it "should abort the dial after the specified timeout"
        end

        describe "with a from specified" do
          it "originates the call from the specified caller ID"
        end

      	describe "with a block" do
          it "uses the block as the dialplan for the new call"

          it "joins the new call to the existing call once the block returns"

          it "does not try to join the calls if the new call is hungup when the block returns"
        end
      end#describe #dial
    end
  end
end
