require 'spec_helper'

module Adhearsion
  describe Dispatcher do
    def stub_before_call_hooks!
      flexstub(Events).should_receive(:trigger).with([:before_call], Proc).and_return
    end

    before do
      Adhearsion::Events.reinitialize_theatre!
    end

    let(:call_id)     { rand }
    let(:mock_offer)  { flexmock 'Offer', :call_id => call_id }
    let(:mock_call)   { flexmock 'Call', :id => call_id }
    let(:mock_client) { flexmock 'Client' }

    subject { Dispatcher.new mock_client }

    describe "dispatching an offer" do
      it 'invokes the before_call event' do
        flexmock(Adhearsion).should_receive(:receive_call_from).once.with(mock_offer).and_return mock_call

        flexmock(Events).should_receive(:trigger_immediately).once.with([:before_call], mock_call).and_throw :triggered

        the_following_code {
          subject.dispatch_offer mock_offer
        }.should throw_symbol :triggered
      end
    end

    it 'should hand the call off to a new Manager if the request is agi://IP_ADDRESS_HERE' do
      pending
      stub_before_call_hooks!
      call_mock = flexmock 'A new mock call that will be passed to the manager', :variables => {}, :id => "X"

      flexmock(Adhearsion).should_receive(:receive_call_from).once.and_return call_mock
      manager_mock = flexmock 'a mock dialplan manager'
      manager_mock.should_receive(:handle).once.with(call_mock)
      flexmock(DialPlan::Manager).should_receive(:new).once.and_return manager_mock
      server.serve(nil)
    end
  end
end
