# encoding: utf-8

require 'spec_helper'

module Adhearsion
  describe OutboundCall do
    it { should be_a Call }

    its(:id) { should be_nil }
    its(:variables) { should be == {} }

    let(:mock_client) { flexmock 'Punchblock Client' }

    before do
      PunchblockPlugin::Initializer.client = mock_client
    end

    its(:client) { should be mock_client }

    describe ".originate" do
      let(:to) { 'sip:foo@bar.com' }

      let(:mock_call) { OutboundCall.new }

      it "should dial the call to the correct endpoint and return it" do
        mock_call
        flexmock(OutboundCall).should_receive(:new).and_return mock_call
        flexmock(mock_call.wrapped_object).should_receive(:dial).with(to, :from => 'foo').once
        OutboundCall.originate(to, :from => 'foo').should be mock_call
      end

      it "should run through the router when the call is answered" do
        mock_call

        flexmock(OutboundCall).should_receive(:new).and_return mock_call
        flexmock(mock_call.wrapped_object).should_receive(:dial).once

        mock_dispatcher = flexmock 'dispatcher'
        mock_dispatcher.should_receive(:call).once.with mock_call
        flexmock(Adhearsion.router).should_receive(:handle).once.with(mock_call).and_return mock_dispatcher

        OutboundCall.originate(to).deliver_message Punchblock::Event::Answered.new
      end
    end

    describe "event handlers" do
      let(:response) { flexmock 'Response' }

      describe "for answered events" do
        let(:event) { Punchblock::Event::Answered.new }

        it "should trigger any on_answer callbacks set" do
          response.should_receive(:call).once.with(event)
          subject.on_answer { |event| response.call event }
          subject << event
        end
      end
    end

    describe "#dial" do
      def expect_message_waiting_for_response(message)
        flexmock(subject.wrapped_object).should_receive(:write_and_await_response).once.with(message, 60).and_return do
          message.target_call_id = call_id
          message
        end
      end

      let(:call_id) { 'abc123' }
      let(:to)      { '+1800 555-0199' }
      let(:from)    { '+1800 555-0122' }

      let(:expected_dial_command) { Punchblock::Command::Dial.new(:to => to, :from => from) }

      before do
        expect_message_waiting_for_response expected_dial_command
      end

      it "should send a dial stanza, wait for the response" do
        subject.dial to, :from => from
      end

      it "should set the dial command" do
        subject.dial to, :from => from
        subject.dial_command.should be == expected_dial_command
      end

      it "should set the call ID from the dial command" do
        subject.dial to, :from => from
        subject.id.should be == call_id
      end

      it "should set the to from the dial command" do
        subject.dial to, :from => from
        subject.to.should be == to
      end

      it "should set the 'from' from the dial command" do
        subject.dial to, :from => from
        subject.from.should be == from
      end

      it "should add the call to the active calls registry" do
        Adhearsion.active_calls.clear!
        subject.dial to, :from => from
        Adhearsion.active_calls[call_id].should be subject
      end
    end

    describe "basic control commands" do
      def expect_no_message_waiting_for_response
        flexmock(subject.wrapped_object).should_receive(:write_and_await_response).never
      end

      describe '#accept' do
        describe "with no headers" do
          it 'should not send any message' do
            expect_no_message_waiting_for_response
            subject.accept
          end
        end

        describe "with headers set" do
          it 'should not send any message' do
            expect_no_message_waiting_for_response
            subject.accept :foo => 'bar'
          end
        end
      end

      describe '#answer' do
        describe "with no headers" do
          it 'should not send any message' do
            expect_no_message_waiting_for_response
            subject.answer
          end
        end

        describe "with headers set" do
          it 'should not send any message' do
            expect_no_message_waiting_for_response
            subject.answer :foo => 'bar'
          end
        end
      end

      describe '#reject' do
        describe "with a reason given" do
          it 'should not send any message' do
            expect_no_message_waiting_for_response
            subject.reject :decline
          end
        end

        describe "with no reason given" do
          it 'should not send any message' do
            expect_no_message_waiting_for_response
            subject.reject
          end
        end

        describe "with no headers" do
          it 'should not send any message' do
            expect_no_message_waiting_for_response
            subject.reject
          end
        end

        describe "with headers set" do
          it 'should not send any message' do
            expect_no_message_waiting_for_response
            subject.reject nil, :foo => 'bar'
          end
        end
      end
    end
  end
end
