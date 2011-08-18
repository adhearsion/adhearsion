require 'spec_helper'

module Adhearsion
  describe Call do
    subject { Adhearsion::Call.new mock_offer }

    after do
      Adhearsion.active_calls.clear!
    end

    its(:inbox) { should be_a_kind_of Queue }

    it { should respond_to :<< }

    its(:originating_voip_platform) { should == :rayo_server }

    it '#id should return the ID from the Offer' do
      offer = mock_offer
      Adhearsion::Call.new(offer).id.should == offer.call_id
    end

    it 'should store the original offer' do
      offer = mock_offer
      Adhearsion::Call.new(offer).offer.should == offer
    end

    it 'can create a call and add it via a top-level method on the Adhearsion module' do
      Adhearsion.active_calls.any?.should == false
      call = Adhearsion.receive_call_from mock_offer
      call.should be_a_kind_of(Adhearsion::Call)
      Adhearsion.active_calls.size.should == 1
    end

    it 'a hungup call removes itself from the active calls' do
      pending
      size_before = Adhearsion.active_calls.size

      call = Adhearsion.receive_call_from mock_io
      Adhearsion.active_calls.size.should > size_before
      call.hangup!
      Adhearsion.active_calls.size.should == size_before
    end
  end
end
