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
      Punchblock::Event::Offer.new :target_call_id => call_id || random_call_id, :headers => headers
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

      context "by dead call object" do
        before do
          @call_id = deleted_call.id
          deleted_call.terminate
          deleted_call.should_not be_alive
          subject.remove_inactive_call deleted_call
        end

        it "should remove the call from the collection" do
          subject.size.should be == number_of_calls - 1
          subject[@call_id].should be_nil
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

    describe "when a call in the collection crashes" do
      let(:wrapped_object) { call.wrapped_object }

      before do
        def wrapped_object.crash_me
          raise StandardError, "Someone crashed me"
        end
      end

      def crash
        lambda { call.crash_me }.should raise_error(StandardError, "Someone crashed me")
        sleep 0.5
      end

      it "is removed from the collection" do
        call_id = call.id
        size_before = subject.size

        subject << call
        subject.size.should be > size_before
        subject[call_id].should be call

        crash
        subject.size.should be == size_before
        subject[call_id].should be_nil
      end

      it "is sends a hangup command for the call" do
        call_id = call.id
        flexmock PunchblockPlugin, :client => flexmock('Client')
        flexmock(PunchblockPlugin.client).should_receive(:execute_command).once.with(Punchblock::Command::Hangup.new, :async => true, :call_id => call_id)

        subject << call

        crash
      end

      it "shuts down the actor" do
        crash
        call.should_not be_alive
      end
    end
  end
end
