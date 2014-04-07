# encoding: utf-8

require 'spec_helper'

module Adhearsion
  describe OutboundCall do
    it { should be_a Call }

    its(:id) { should be_nil }
    its(:variables) { should be == {} }

    let(:mock_client) { double 'Punchblock Client', execute_command: true, new_call_uri: call_uri }

    before do
      PunchblockPlugin::Initializer.client = mock_client
      Adhearsion.active_calls.clear
    end

    its(:client) { should be mock_client }
    its(:start_time) { should be nil }

    let(:transport) { 'xmpp' }
    let(:call_id)   { SecureRandom.uuid }
    let(:domain)    { 'rayo.net' }
    let(:call_uri)  { "xmpp:#{call_id}@rayo.net" }
    let(:to)        { '+1800 555-0199' }
    let(:from)      { '+1800 555-0122' }

    it "should allow timers to be registered from outside" do
      foo = :bar
      subject.after(1) { foo = :baz }
      sleep 1.1
      foo.should == :baz
    end

    describe ".originate" do
      let(:to) { 'sip:foo@bar.com' }

      let(:mock_call) { OutboundCall.new }

      before do
        mock_call
        OutboundCall.should_receive(:new).and_return mock_call
      end

      it "should dial the call to the correct endpoint and return it" do
        mock_call.wrapped_object.should_receive(:dial).with(to, :from => 'foo').once
        OutboundCall.originate(to, :from => 'foo').should be mock_call
      end

      it "should run through the router when the call is answered" do
        mock_call.wrapped_object.should_receive(:dial).once

        Adhearsion.router.should_receive(:handle).once.with(mock_call)

        OutboundCall.originate(to) << Punchblock::Event::Answered.new
      end

      context "when a controller class is specified for the call" do
        let(:controller) { CallController }

        it "should execute the controller on the call when it is answered" do
          mock_call.should_receive(:dial).once.with(to, {})
          mock_call.should_receive(:execute_controller).once.with kind_of(controller), kind_of(Proc)
          call = OutboundCall.originate to, :controller => controller
          call << Punchblock::Event::Answered.new
        end

        it "should hangup the call after all controllers have executed" do
          mock_call.should_receive(:dial).once
          mock_call.should_receive(:hangup).once

          call = OutboundCall.originate to, :controller => controller
          call << Punchblock::Event::Answered.new
          sleep 0.5
        end

        context "with controller metadata specified" do
          it "should set the metadata on the controller" do
            mock_call.should_receive(:dial).once.with(to, {})
            expected_controller = controller.new mock_call, foo: 'bar'
            mock_call.should_receive(:execute_controller).with(expected_controller, kind_of(Proc)).once
            call = OutboundCall.originate to, :controller => controller, :controller_metadata => {:foo => 'bar'}
            call << Punchblock::Event::Answered.new
          end
        end
      end

      context "when given a block" do
        it "should execute the block as a controller on the call when it is answered" do
          mock_call.should_receive(:dial).once.with(to, {})
          mock_call.should_receive(:execute_controller).once.with(kind_of(CallController), kind_of(Proc)).and_return do |controller|
            controller.block.call.should be == :foobar
          end

          call = OutboundCall.originate to do
            :foobar
          end
          call << Punchblock::Event::Answered.new
        end
      end

      context "when the dial fails" do
        before do
          subject.wrapped_object.should_receive(:write_command)
          Punchblock::Command::Dial.any_instance.should_receive(:response).and_return StandardError.new("User not registered")
        end

        after do
          Adhearsion.active_calls.restart_supervisor
        end

        it "should raise the exception in the caller" do
          expect { subject.dial to }.to raise_error("User not registered")
        end

        it "should kill the actor" do
          expect { subject.dial to }.to raise_error("User not registered")
          sleep 0.1
          subject.should_not be_alive
        end
      end
    end

    describe "event handlers" do
      let(:response) { double 'Response' }

      describe "for answered events" do
        let(:event) { Punchblock::Event::Answered.new }

        it "should trigger any on_answer callbacks set" do
          response.should_receive(:call).once.with(event)
          subject.on_answer { |event| response.call event }
          subject << event
        end

        it "should record the call start time" do
          originate_time = Time.local(2008, 9, 1, 12, 0, 0)
          Timecop.freeze originate_time
          subject.duration.should == 0.0

          mid_point_time = Time.local(2008, 9, 1, 12, 0, 20)
          Timecop.freeze mid_point_time
          subject.duration.should == 0.0

          answer_time = Time.local(2008, 9, 1, 12, 0, 40)
          Timecop.freeze answer_time
          subject << event
          subject.start_time.should == answer_time

          later_time = Time.local(2008, 9, 1, 12, 0, 50)
          Timecop.freeze later_time
          subject.duration.should == 10.0
        end
      end
    end

    describe "#dial" do
      def expect_message_waiting_for_response(message)
        subject.wrapped_object.should_receive(:write_and_await_response).once.with(message, 60, true).and_return do
          message.transport = transport
          message.target_call_id = call_id
          message.domain = domain
          message
        end
      end

      let(:expected_dial_command) { Punchblock::Command::Dial.new(:to => to, :from => from, :uri => call_uri) }

      context "while waiting for a response" do
        before do
          mock_client.should_receive(:execute_command).once.with(expected_dial_command).and_return true
          subject.async.dial to, from: from
          sleep 1
        end

        it "should set the dial command" do
          subject.dial_command.should be == expected_dial_command
        end

        it "should know its requested URI" do
          subject.uri.should be == call_uri
        end

        it "should know its requested ID" do
          subject.id.should be == call_id
        end

        it "should know its domain" do
          subject.domain.should be == domain
        end

        it "should be entered in the active calls registry" do
          Adhearsion.active_calls[call_id].should be subject
        end
      end

      context "with a successful response" do
        before do
          expect_message_waiting_for_response expected_dial_command
        end

        it "should send a dial stanza, wait for the response" do
          subject.dial to, :from => from
        end

        it "should set the dial command" do
          subject.dial to, :from => from
          subject.dial_command.should be == Punchblock::Command::Dial.new(:to => to, :from => from, :uri => call_uri)
        end

        it "should set the URI from the reference" do
          subject.dial to, :from => from
          subject.uri.should be == call_uri
        end

        it "should set the call ID from the reference" do
          subject.dial to, :from => from
          subject.id.should be == call_id
        end

        it "should set the call domain from the reference" do
          subject.dial to, :from => from
          subject.domain.should be == domain
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
          subject.dial to, :from => from
          Adhearsion.active_calls[call_id].should be subject
        end

        it "should immediately fire the :call_dialed event giving the call" do
          Adhearsion::Events.should_receive(:trigger_immediately).once.with(:call_dialed, subject)
          subject.dial to, :from => from
        end

        it "should not modify the provided options" do
          options = {:from => from}
          original_options = Marshal.load(Marshal.dump(options))
          options.should be == original_options
          subject.dial to, options
          options.should be == original_options
        end
      end

      context "when the dial fails" do
        before do
          subject.wrapped_object.should_receive(:write_command)
          Punchblock::Command::Dial.any_instance.should_receive(:response).and_return StandardError.new("User not registered")
        end

        after do
          Adhearsion.active_calls.restart_supervisor
        end

        it "should raise the exception in the caller" do
          expect { subject.dial to }.to raise_error("User not registered")
        end

        it "should kill the actor" do
          expect { subject.dial to }.to raise_error("User not registered")
          sleep 0.1
          subject.should_not be_alive
        end

        it "should remove the call from the active calls hash" do
          expect { subject.dial to }.to raise_error("User not registered")
          sleep 0.1
          Adhearsion.active_calls[call_id].should be_nil
        end
      end
    end

    describe "basic control commands" do
      def expect_no_message_waiting_for_response
        subject.wrapped_object.should_receive(:write_and_await_response).never
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
