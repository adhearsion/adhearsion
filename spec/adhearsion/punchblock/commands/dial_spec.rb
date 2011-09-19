require 'spec_helper'

module Adhearsion
  module Punchblock
    module Commands
      describe Dial do
        include PunchblockCommandTestHelpers

        let(:to) { 'sip:foo@bar.com' }

        let(:mock_call) { OutboundCall.new }

        let(:mock_end) { flexmock Punchblock::Event::End.new, :reason => :hangup }

        def mock_dial
          flexmock(OutboundCall).new_instances.should_receive(:dial).and_return true
        end

        describe "#dial" do
          it "should create a new call and return it" do
            mock_dial
            Thread.new do
              mock_execution_environment.dial(to).should be_a OutboundCall
            end
            mock_call << mock_end
          end

          it "should dial the call to the correct endpoint" do
            mock_call
            flexmock(OutboundCall).should_receive(:new).and_return mock_call
            flexmock(mock_call).should_receive(:dial).with(to, :from => 'foo').once
            dial_thread = Thread.new do
              mock_execution_environment.dial to, :from => 'foo'
            end
            sleep 0.1
            mock_call << mock_end
            dial_thread.join.should be_true
          end

          describe "without a block" do
            it "blocks the original dialplan until the new call ends" do
              mock_call

              flexmock(mock_call).should_receive(:dial).once
              flexmock(OutboundCall).should_receive(:new).and_return mock_call

              latch = CountDownLatch.new 1

              Thread.new do
                mock_execution_environment.dial(to)
                latch.countdown!
              end

              latch.wait(1).should be_false

              mock_call << mock_end

              latch.wait(1).should be_true
            end

            it "joins the new call to the existing one on answer"
          end

          describe "with multiple third parties specified" do
            it "dials all parties and joins the first one to answer, hanging up the rest"
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
        end
      end
    end
  end
end
