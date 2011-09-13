require 'spec_helper'

module Adhearsion
  describe OutboundCall do
    it { should be_a Call }

    its(:id) { should be_nil }

    let(:mock_client) { flexmock 'Punchblock Client' }

    before do
      Initializer::Punchblock.client = mock_client
    end

    its(:connection) { should be mock_client }

    describe ".originate" do
      let(:to) { 'sip:foo@bar.com' }

      let(:mock_manager)  { flexmock 'DialPlan::Manager' }
      let(:mock_call)     { OutboundCall.new }

      def mock_dial
        flexmock(OutboundCall).new_instances.should_receive(:dial).and_return true
      end

      it "should create a new call and return it" do
        mock_dial
        OutboundCall.originate(to).should be_a OutboundCall
      end

      it "should allow setting the call's dialplan context" do
        mock_dial
        call = OutboundCall.originate to, :context => :foo
        call.context.should == :foo
      end

      it "uses the default context if none is provided" do
        mock_dial
        call = OutboundCall.originate to
        call.context.should == Call.new.context
      end

      it "should dial the call to the correct endpoint" do
        mock_call
        flexmock(OutboundCall).should_receive(:new).and_return mock_call
        flexmock(mock_call).should_receive(:dial).with(to, :from => 'foo').once
        OutboundCall.originate to, :from => 'foo'
      end

      it "should run the dialplan when the call is answered" do
        mock_call

        flexmock(OutboundCall).should_receive(:new).and_return mock_call
        flexmock(mock_call).should_receive(:dial).once

        flexmock(DialPlan::Manager).should_receive(:handle).once.with(mock_call)

        OutboundCall.originate(to).deliver_message Punchblock::Event::Answered.new
      end
    end

    describe "#dial" do
      def expect_message_waiting_for_response(message)
        flexmock(subject).should_receive(:write_and_await_response).once.with(message).and_return do
          message.call_id = call_id
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
        subject.dial_command.should == expected_dial_command
      end

      it "should set the call ID from the dial command" do
        subject.dial to, :from => from
        subject.id.should == call_id
      end
    end

    describe "#on_accept" do
      it "should take a lambda" do
        l = lambda { :foo }
        subject.on_accept = l
        subject.on_accept.should == l
      end
    end

    describe "#on_answer" do
      it "should take a lambda" do
        l = lambda { :foo }
        subject.on_answer = l
        subject.on_answer.should == l
      end
    end

    describe "#<<" do
      describe "with a Ringing event" do
        let(:event) { Punchblock::Event::Ringing.new }

        describe "with an on_accept callback set" do
          before do
            @foo = nil
            subject.on_accept = lambda { |event| @foo = event }
          end

          it "should fire the on_accept callback" do
            subject << event
            @foo.should == event
          end
        end

        describe "without an on_accept callback set" do
          it "should not raise an exception" do
            lambda { subject << event }.should_not raise_error
          end
        end
      end

      describe "with an Answered event" do
        let(:event) { Punchblock::Event::Answered.new }

        describe "with an on_answer callback set" do
          before do
            @foo = nil
            subject.on_answer = lambda { |event| @foo = event }
          end

          it "should fire the on_answer callback" do
            subject << event
            @foo.should == event
          end
        end

        describe "without an on_answer callback set" do
          it "should not raise an exception" do
            lambda { subject << event }.should_not raise_error
          end
        end
      end
    end
  end
end
