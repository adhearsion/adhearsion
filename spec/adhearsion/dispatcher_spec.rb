require 'spec_helper'

module Adhearsion
  describe Dispatcher do
    before do
      Adhearsion::Events.reinitialize_theatre!
    end

    let(:call_id)     { rand }
    let(:mock_offer)  { flexmock 'Offer', :call_id => call_id }
    let(:mock_call)   { flexmock 'Call', :id => call_id }
    let(:mock_client) { flexmock 'Client' }

    subject { Dispatcher.new mock_client }

    describe "dispatching an offer" do
      it 'should hand the call off to a new Manager' do
        flexmock(Adhearsion).should_receive(:receive_call_from).once.and_return mock_call
        manager_mock = flexmock 'a mock dialplan manager'
        manager_mock.should_receive(:handle).once.with(mock_call)
        flexmock(DialPlan::Manager).should_receive(:new).once.and_return manager_mock
        subject.dispatch_offer mock_offer
      end
    end
  end
end
