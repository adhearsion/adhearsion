require 'spec_helper'

module Adhearsion
  describe Call do
    subject { Adhearsion::Call.new mock_offer }

    after do
      Adhearsion.active_calls.clear!
    end

    its(:inbox) { should be_a_kind_of Queue }

    it { should respond_to :<< }

    its(:originating_voip_platform) { should == :rayo }

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

    describe "tagging a call" do
      it 'with a single Symbol' do
        the_following_code {
          subject.tag :moderator
        }.should_not raise_error
      end

      it 'with multiple Symbols' do
        the_following_code {
          subject.tag :moderator
          subject.tag :female
        }.should_not raise_error
      end

      it 'with a non-Symbol, non-String object' do
        bad_objects = [123, Object.new, 888.88, nil, true, false, StringIO.new]
        bad_objects.each do |bad_object|
          the_following_code {
            subject.tag bad_object
          }.should raise_error ArgumentError
        end
      end
    end

    it "#remove_tag" do
      subject.tag :moderator
      subject.tag :female
      subject.remove_tag :female
      subject.tag :male
      subject.tags.should == [:moderator, :male]
    end

    describe "#tagged_with?" do
      it 'with one tag' do
        subject.tag :guest
        subject.tagged_with?(:guest).should be true
        subject.tagged_with?(:authorized).should be false
      end

      it 'with many tags' do
        subject.tag :customer
        subject.tag :authorized
        subject.tagged_with?(:customer).should be true
        subject.tagged_with?(:authorized).should be true
      end
    end
  end
end
