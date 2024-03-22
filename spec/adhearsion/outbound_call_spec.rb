# encoding: utf-8

require 'spec_helper'

module Adhearsion
  describe OutboundCall do
    it { is_expected.to be_a Call }

    describe '#id' do
      subject { super().id }
      it { is_expected.to be_nil }
    end

    describe '#variables' do
      subject { super().variables }
      it { is_expected.to eq({}) }
    end

    let(:mock_client) { double 'Rayo Client', execute_command: true, new_call_uri: call_uri }

    before do
      Adhearsion::Rayo::Initializer.client = mock_client
      Adhearsion.active_calls.clear
    end

    describe '#client' do
      subject { super().client }
      it { is_expected.to be mock_client }
    end

    describe '#start_time' do
      subject { super().start_time }
      it { is_expected.to be nil }
    end

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
      expect(foo).to eq(:baz)
    end

    describe ".originate" do
      let(:to) { 'sip:foo@bar.com' }

      let(:mock_call) { OutboundCall.new }

      before do
        mock_call
        expect(OutboundCall).to receive(:new).and_return mock_call
      end

      it "should dial the call to the correct endpoint and return it" do
        expect(mock_call.wrapped_object).to receive(:dial).with(to, Hash(from: 'foo')).once
        expect(OutboundCall.originate(to, Hash(from: 'foo'))).to be mock_call
      end

      it "should run through the router when the call is answered" do
        expect(mock_call.wrapped_object).to receive(:dial).once

        expect(Adhearsion.router).to receive(:handle).once.with(mock_call)

        OutboundCall.originate(to) << Adhearsion::Event::Answered.new
      end

      context "when a controller class is specified for the call" do
        let(:controller) { CallController }

        it "should execute the controller on the call when it is answered" do
          expect(mock_call).to receive(:dial).once.with(to)
          expect(mock_call).to receive(:execute_controller).once.with(kind_of(controller), kind_of(Proc))
          call = OutboundCall.originate(to, :controller => controller)
          call << Adhearsion::Event::Answered.new
        end

        it "should hangup the call after all controllers have executed" do
          expect(mock_call).to receive(:dial).once
          expect(mock_call).to receive(:hangup).once

          call = OutboundCall.originate to, :controller => controller
          call << Adhearsion::Event::Answered.new
          sleep 0.5
        end

        context "with controller metadata specified" do
          it "should set the metadata on the controller" do
            expect(mock_call).to receive(:dial).once.with(to)
            expected_controller = controller.new(mock_call, foo: 'bar')
            expect(mock_call).to receive(:execute_controller).with(expected_controller, kind_of(Proc)).once
            call = OutboundCall.originate to, :controller => controller, :controller_metadata => {:foo => 'bar'}
            call << Adhearsion::Event::Answered.new
          end
        end
      end

      context "when given a block" do
        it "should execute the block as a controller on the call when it is answered" do
          expect(mock_call).to receive(:dial).once.with(to)
          expect(mock_call).to receive(:execute_controller).once.with(kind_of(CallController), kind_of(Proc)) do |controller|
            expect(controller.block.call).to eq(:foobar)
          end

          call = OutboundCall.originate to do
            :foobar
          end
          call << Adhearsion::Event::Answered.new
        end
      end

      context "when the dial fails" do
        before do
          expect(subject.wrapped_object).to receive(:write_command)
          expect_any_instance_of(Adhearsion::Rayo::Command::Dial).to receive(:response).and_return StandardError.new("User not registered")
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
          expect(subject.alive?).to be false
        end
      end
    end

    describe "event handlers" do
      let(:response) { double 'Response' }

      describe "for answered events" do
        let(:event) { Adhearsion::Event::Answered.new }

        it "should trigger any on_answer callbacks set" do
          expect(response).to receive(:call).once.with(event)
          subject.on_answer { |event| response.call event }
          subject << event
        end

        it "should record the call answer time" do
          originate_time = Time.local(2008, 9, 1, 12, 0, 0)
          Timecop.freeze originate_time
          expect(subject.duration).to eq(0.0)

          mid_point_time = Time.local(2008, 9, 1, 12, 0, 20)
          Timecop.freeze mid_point_time
          expect(subject.duration).to eq(0.0)

          answer_time = Time.local(2008, 9, 1, 12, 0, 40)
          Timecop.freeze answer_time
          subject << event
          expect(subject.answer_time).to eq(answer_time)
        end
      end
    end

    describe "#dial" do
      def expect_message_waiting_for_response(message, uri = call_uri)
        expect(subject.wrapped_object).to receive(:write_and_await_response).once.with(message, 60, true) do |real_message|
          real_message.request!
          real_message.response = Adhearsion::Rayo::Ref.new(uri: uri)
          real_message
        end
      end

      let(:expected_dial_command) { Adhearsion::Rayo::Command::Dial.new(:to => to, :from => from, :uri => call_uri) }

      context "while waiting for a response" do
        before do
          expect(mock_client).to receive(:execute_command).once.with(expected_dial_command).and_return true
          subject.async.dial to, from: from
          sleep 1
        end

        it "should set the dial command" do
          expect(subject.dial_command).to eq(expected_dial_command)
        end

        it "should know its requested URI" do
          expect(subject.uri).to eq(call_uri)
        end

        it "should know its requested ID" do
          expect(subject.id).to eq(call_id)
        end

        it "should know its domain" do
          expect(subject.domain).to eq(domain)
        end

        it "should be entered in the active calls registry" do
          expect(Adhearsion.active_calls[call_id]).to be subject
        end
      end

      context "with a successful response" do
        let(:returned_uri) { call_uri }
        let(:originate_time) { Time.local(1981, 4, 13, 10, 56, 0) }

        before do
          Timecop.freeze originate_time
          expect_message_waiting_for_response expected_dial_command, returned_uri
        end

        it "should send a dial stanza, wait for the response" do
          subject.dial to, :from => from
        end

        it "should set the dial command" do
          subject.dial to, :from => from
          expect(subject.dial_command).to eq(Adhearsion::Rayo::Command::Dial.new(:to => to, :from => from, :uri => call_uri, target_call_id: call_id, domain: domain, transport: transport))
        end

        it "should set the URI from the reference" do
          subject.dial to, :from => from
          expect(subject.uri).to eq(call_uri)
        end

        it "should set the call ID from the reference" do
          subject.dial to, :from => from
          expect(subject.id).to eq(call_id)
        end

        it "should set the call domain from the reference" do
          subject.dial to, :from => from
          expect(subject.domain).to eq(domain)
        end

        it "should set the to from the dial command" do
          subject.dial to, :from => from
          expect(subject.to).to eq(to)
        end

        it "should set the 'from' from the dial command" do
          subject.dial to, :from => from
          expect(subject.from).to eq(from)
        end

        it "should add the call to the active calls registry" do
          subject.dial to, :from => from
          expect(Adhearsion.active_calls[call_id]).to be subject
        end

        it "should set the start time" do
          subject.dial to, :from => from
          expect(subject.start_time).to eq(originate_time)
        end

        context "when a different ref is returned than the one expected" do
          let(:returned_uri) { 'xmpp:otherid@wonderland.lit' }

          before do
            subject.dial to, :from => from
          end

          it "should set the URI from the reference" do
            expect(subject.uri).to eq(returned_uri)
          end

          it "should set the call ID from the reference" do
            expect(subject.id).to eq('otherid')
          end

          it "should set the call domain from the reference" do
            expect(subject.domain).to eq('wonderland.lit')
          end

          it "should make the call addressible in the active calls registry by the new ID" do
            expect(Adhearsion.active_calls[call_id]).to be_nil
            expect(Adhearsion.active_calls['otherid']).to be subject
          end
        end

        it "should immediately fire the :call_dialed event giving the call" do
          expect(Adhearsion::Events).to receive(:trigger).once.with(:call_dialed, subject)
          subject.dial to, :from => from
        end

        it "should not modify the provided options" do
          options = {:from => from}
          original_options = Marshal.load(Marshal.dump(options))
          expect(options).to eq(original_options)
          subject.dial to, options
          expect(options).to eq(original_options)
        end
      end

      context "when the dial fails" do
        before do
          expect(subject.wrapped_object).to receive(:write_command)
          expect_any_instance_of(Adhearsion::Rayo::Command::Dial).to receive(:response).and_return StandardError.new("User not registered")
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
          expect(subject.alive?).to be false
        end

        it "should remove the call from the active calls hash" do
          expect { subject.dial to }.to raise_error("User not registered")
          sleep 0.1
          expect(Adhearsion.active_calls[call_id]).to be_nil
        end
      end
    end

    describe "basic control commands" do
      def expect_no_message_waiting_for_response
        expect(subject.wrapped_object).to receive(:write_and_await_response).never
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
