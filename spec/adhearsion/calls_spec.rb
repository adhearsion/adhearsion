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
      Punchblock::Event::Offer.new domain: 'example.com', transport: 'xmpp', :target_call_id => call_id || random_call_id, :headers => headers
    end

    it 'can add a call to the collection' do
      expect(subject.any?).to eq(false)
      call = Call.new new_offer
      subject << call
      expect(call).to be_a Adhearsion::Call
      expect(subject.size).to eq(1)
      expect(subject[call.id]).to be call
    end

    it '#size should return the number of calls in the collection' do
      expect(subject.size).to eq(0)
      subject << call
      expect(subject.size).to eq(1)
    end

    describe "removing a call" do
      let(:deleted_call) { calls[number_of_calls / 2] }

      before { calls.each { |call| subject << call } }

      context "by call object" do
        before { subject.remove_inactive_call deleted_call }

        it "should remove the call from the collection" do
          expect(subject.size).to eq(number_of_calls - 1)
          expect(subject[deleted_call.id]).to be_nil
          expect(subject.with_uri(deleted_call.uri)).to be_nil
        end
      end

      context "by dead call object" do
        before do
          @call_id = deleted_call.id
          @call_uri = deleted_call.uri
          Celluloid::Actor.kill deleted_call
          expect(deleted_call.alive?).to be false
          subject.remove_inactive_call deleted_call
        end

        it "should remove the call from the collection" do
          expect(subject.size).to eq(number_of_calls - 1)
          expect(subject[@call_id]).to be_nil
          expect(subject.with_uri(@call_uri)).to be_nil
        end
      end

      context "by ID" do
        before { subject.remove_inactive_call deleted_call.id }

        it "should remove the call from the collection" do
          expect(subject.size).to eq(number_of_calls - 1)
          expect(subject[deleted_call.id]).to be_nil
          expect(subject.with_uri(deleted_call.uri)).to be_nil
        end
      end
    end

    context "tagged calls" do
      it "finding calls by a tag" do
        calls.each { |call| subject << call }

        tagged_call = calls.last
        tagged_call.tag :moderator

        expect(subject.with_tag(:moderator)).to eq([tagged_call])
      end

      it "when a call is dead, ignore it in the search" do
        calls.each { |call| subject << call }

        tagged_call = calls.last
        tagged_call.tag :moderator
        Celluloid::Actor.kill tagged_call

        expect(subject.with_tag(:moderator)).to eq([])
      end
    end

    it "finding calls by uri" do
      calls.each { |call| subject << call }

      expect(subject.with_uri(calls.last.uri)).to eq(calls.last)
    end

    describe "#<<" do
      it "should allow chaining" do
        subject << Call.new(new_offer) << Call.new(new_offer)
        expect(subject.size).to eq(2)
      end
    end

    describe "when a call in the collection terminates cleanly" do
      it "is removed from the collection" do
        call_id = call.id
        call_uri = call.uri
        size_before = subject.size

        subject << call
        call.terminate

        sleep 0.1

        expect(subject.size).to eq(size_before)
        expect(subject[call_id]).to be_nil
        expect(subject.with_uri(call_uri)).to be_nil
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
        expect { call.crash_me }.to raise_error(StandardError, "Someone crashed me")
        sleep 0.5
      end

      it "is removed from the collection" do
        call_id = call.id
        call_uri = call.uri
        size_before = subject.size

        subject << call
        expect(subject.size).to be > size_before
        expect(subject[call_id]).to be call
        expect(subject.with_uri(call_uri)).to be call

        crash
        expect(subject.size).to eq(size_before)
        expect(subject[call_id]).to be_nil
        expect(subject.with_uri(call_uri)).to be_nil
      end

      it "is sends a hangup command for the call" do
        call_id = call.id
        allow(PunchblockPlugin).to receive_messages :client => double('Client')
        expect(PunchblockPlugin.client).to receive(:execute_command).once.with(Punchblock::Command::Hangup.new, :async => true, :call_id => call_id)

        subject << call

        crash
      end

      it "shuts down the actor" do
        crash
        expect(call.alive?).to be false
      end
    end
  end
end
