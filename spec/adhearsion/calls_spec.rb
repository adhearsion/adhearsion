# encoding: utf-8

require 'spec_helper'

module Adhearsion
  describe Calls do
    let(:call) { Adhearsion::Call.new new_offer }

    let(:number_of_calls) { 10 }
    let :calls do
      Array.new(number_of_calls) { Adhearsion::Call.new new_offer }
    end

    def new_offer(call_id = nil, headers = {})
      Punchblock::Event::Offer.new :call_id => call_id || rand, :headers => headers
    end

    it 'can create a call and add it to the collection' do
      subject.any?.should be == false
      call = subject.from_offer new_offer
      call.should be_a Adhearsion::Call
      subject.size.should be == 1
      subject[call.id].should be call
    end

    it '#size should return the number of calls in the collection' do
      subject.size.should be == 0
      subject << call
      subject.size.should be == 1
    end

    describe "removing a call" do
      let(:deleted_call) { calls[number_of_calls / 2] }

      before { calls.each { |call| subject << call } }

      context "by call object" do
        before { subject.remove_inactive_call deleted_call }

        it "should remove the call from the collection" do
          subject.size.should be == number_of_calls - 1
          subject[deleted_call.id].should be_nil
        end
      end

      context "by ID" do
        before { subject.remove_inactive_call deleted_call.id }

        it "should remove the call from the collection" do
          subject.size.should be == number_of_calls - 1
          subject[deleted_call.id].should be_nil
        end
      end
    end

    it "finding calls by a tag" do
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
