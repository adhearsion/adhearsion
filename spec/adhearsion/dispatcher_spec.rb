require 'spec_helper'

module Adhearsion
  describe Dispatcher do
    before do
      Adhearsion::Events.reinitialize_queue!
    end

    let(:call_id)       { rand }
    let(:mock_offer)    { flexmock 'Offer', :call_id => call_id }
    let(:mock_call)     { flexmock('Call', :id => call_id).tap { |call| call.should_ignore_missing } }
    let(:event_queue)   { Queue.new }
    let(:mock_manager)  { flexmock 'a mock dialplan manager' }

    subject { Dispatcher.new event_queue }

    describe "reading Punchblock event queue" do
      before do
        event_queue << :foo
        event_queue << :bar
      end

      let(:latch) { CountDownLatch.new 2 }

      it "should dispatch incoming events" do
        flexmock(subject).should_receive(:dispatch_event).once.with(:foo).ordered.and_return { latch.countdown! }
        flexmock(subject).should_receive(:dispatch_event).once.with(:bar).ordered.and_return { latch.countdown! }
      end

      after do
        subject.start
        latch.wait 10
      end
    end

    describe "dispatching an offer" do
      it 'should hand the call off to a new Manager' do
        flexmock(Adhearsion).should_receive(:receive_call_from).once.and_return mock_call
        mock_manager.should_receive(:handle).once.with(mock_call)
        flexmock(DialPlan::Manager).should_receive(:new).once.and_return mock_manager
      end

      after { subject.dispatch_offer mock_offer }
    end

    describe "dispatching a call event" do
      let(:mock_event)  { flexmock 'Event', :call_id => call_id }
      let(:latch)       { CountDownLatch.new 1 }

      describe "with an active call" do
        before do
          Adhearsion.active_calls << mock_call
        end

        it "should log an error" do
          flexmock(Adhearsion::Logging.get_logger(Dispatcher)).should_receive(:info).once.with("Event received for call #{call_id}: #{mock_event.inspect}")
          subject.dispatch_call_event mock_event
        end

        it "should place the event in the call's inbox" do
          mock_call.should_receive(:<<).once.with(mock_event)
          subject.dispatch_call_event mock_event, latch
          latch.wait(10).should be_true
        end
      end

      describe "with an inactive call" do
        let(:mock_event) { flexmock 'Event', :call_id => call_id }

        it "should log an error" do
          flexmock(Adhearsion::Logging.get_logger(Dispatcher)).should_receive(:error).once.with("Event received for inactive call #{call_id}: #{mock_event.inspect}")
          subject.dispatch_call_event mock_event
        end
      end
    end
  end
end
