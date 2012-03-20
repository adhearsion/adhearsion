# encoding: utf-8

require 'spec_helper'

module Adhearsion
  describe Calls do
    before { Adhearsion.active_calls.clear! }

    let(:call) { Adhearsion::Call.new new_offer }

    def new_offer(call_id = nil, headers = {})
      Punchblock::Event::Offer.new :call_id => call_id || rand, :headers => headers
    end

    it 'can create a call and add it to the active calls' do
      Adhearsion.active_calls.any?.should be == false
      call = Adhearsion.active_calls.from_offer new_offer
      call.should be_a Adhearsion::Call
      Adhearsion.active_calls.size.should be == 1
    end

    it '#size should return the size of the collection' do
      subject.size.should be == 0
      subject << call
      subject.size.should be == 1
    end

    it '#remove_inactive_call should delete the call in the Hash' do
      number_of_calls = 10
      calls = Array.new(number_of_calls) { Adhearsion::Call.new new_offer }
      calls.each { |call| subject << call }

      deleted_call = calls[number_of_calls / 2]
      subject.remove_inactive_call deleted_call
      subject.size.should be == number_of_calls - 1
    end

    it '#find should pull the Call from the Hash using the id' do
      subject << call
      subject.find(call.id).should be call
    end

    it "finding calls by a tag" do
      calls = Array.new(3) { Adhearsion::Call.new new_offer }
      calls.each { |call| subject << call }

      tagged_call = calls.last
      tagged_call.tag :moderator

      subject.with_tag(:moderator).should be == [tagged_call]
    end

    describe "#<<" do
      it "should allow chaining" do
        subject << Call.new(new_offer) << Call.new(new_offer)
        subject.size.should be == 2
      end
    end
  end
end
