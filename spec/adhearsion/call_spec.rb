# encoding: utf-8

require 'spec_helper'

class BrokenController < Adhearsion::CallController
  def run
    raise "Blat!"
  end
end

module Adhearsion
  describe Call do
    let(:mock_client) { double('Client').as_null_object }

    let(:call_id) { rand.to_s }
    let(:domain)  { 'rayo.net' }
    let(:headers) { nil }
    let(:to)      { 'sip:you@there.com' }
    let(:from)    { 'sip:me@here.com' }
    let(:transport) { 'footransport' }
    let(:base_time) { Time.local(2008, 9, 1, 12, 0, 0) }
    let :offer do
      Adhearsion::Event::Offer.new target_call_id: call_id,
                                   domain: domain,
                                   transport: transport,
                                   to: to,
                                   from: from,
                                   headers: headers,
                                   timestamp: base_time
    end

    subject { Adhearsion::Call.new offer }

    before do
      allow(offer).to receive(:client).and_return(mock_client)
    end

    after do
      Adhearsion.active_calls.clear
    end

    def expect_message_waiting_for_response(message = nil, fail = false, &block)
      expectation = expect(subject.wrapped_object).to receive(:write_and_await_response, &block).once
      expectation = expectation.with message if message
      if fail
        expectation.and_raise fail
      else
        expectation.and_return message
      end
    end

    it "should do recursion detection on inspect" do
      subject[:foo] = subject
      Timeout.timeout(0.2) do
        expect(subject.inspect).to match('...')
      end
    end

    it "should allow timers to be registered from outside" do
      foo = :bar
      subject.after(1) { foo = :baz }
      sleep 1.1
      expect(foo).to eq(:baz)
    end

    it { is_expected.to respond_to :<< }

    describe '#end_reason' do
      subject { super().end_reason }
      it { is_expected.to eq(nil) }
    end
    it { is_expected.to be_active }

    describe '#commands' do
      subject { super().commands }
      it { is_expected.to be_empty }
    end

    describe '#id' do
      subject { super().id }
      it { is_expected.to eq(call_id) }
    end

    describe '#domain' do
      subject { super().domain }
      it { is_expected.to eq(domain) }
    end

    describe '#uri' do
      subject { super().uri }
      it { is_expected.to eq("footransport:#{call_id}@#{domain}") }
    end

    describe '#to' do
      subject { super().to }
      it { is_expected.to eq(to) }
    end

    describe '#from' do
      subject { super().from }
      it { is_expected.to eq(from) }
    end

    describe '#auto_hangup' do
      subject { super().auto_hangup }
      it { is_expected.to be_truthy }
    end

    describe '#after_hangup_lifetime' do
      subject { super().after_hangup_lifetime }
      it { is_expected.to eq(nil) }
    end

    context "when the ID is nil" do
      let(:call_id) { nil }

      describe '#uri' do
        subject { super().uri }
        it { is_expected.to eq(nil) }
      end
    end

    context "when the domain is nil" do
      let(:domain) { nil }

      describe '#uri' do
        subject { super().uri }
        it { is_expected.to eq("footransport:#{call_id}") }
      end
    end

    context "when the transport is nil" do
      let(:transport) { nil }

      describe '#uri' do
        subject { super().uri }
        it { is_expected.to eq("#{call_id}@#{domain}") }
      end
    end

    it "should mark its start time" do
      expect(subject.start_time).to eq(base_time)
    end

    describe "#commands" do
      it "should use a duplicating accessor for the command registry" do
        expect(subject.commands).not_to be subject.commands
      end
    end

    describe "its variables" do
      context "with an offer" do
        context "with headers" do
          let(:headers)   { {'X-foo' => 'bar'} }

          describe '#variables' do
            subject { super().variables }
            it { is_expected.to eq({'x_foo' => 'bar'}) }
          end

          it "should be made available via []" do
            expect(subject[:x_foo]).to eq('bar')
          end

          it "should be alterable using []=" do
            subject[:x_foo] = 'baz'
            expect(subject[:x_foo]).to eq('baz')
          end

          context "when receiving an event with headers" do
            let(:event) { Adhearsion::Event::End.new :headers => {'X-bar' => 'foo'} }

            it "should merge later headers" do
              subject << event
              expect(subject.variables).to eq({'x_foo' => 'bar', 'x_bar' => 'foo'})
            end

            context "with have symbol names" do
              let(:event) { Adhearsion::Event::End.new :headers => {:x_bar => 'foo'} }

              it "should merge later headers" do
                subject << event
                expect(subject.variables).to eq({'x_foo' => 'bar', 'x_bar' => 'foo'})
              end
            end
          end

          context "when sending a command with headers" do
            let(:command) { Adhearsion::Rayo::Command::Accept.new :headers => {'X-bar' => 'foo'} }

            it "should merge later headers" do
              subject.write_command command
              expect(subject.variables).to eq({'x_foo' => 'bar', 'x_bar' => 'foo'})
            end
          end
        end

        context "without headers" do
          let(:headers)   { nil }

          describe '#variables' do
            subject { super().variables }
            it { is_expected.to eq({}) }
          end
        end
      end

      context "without an offer" do
        let(:offer)     { nil }

        describe '#variables' do
          subject { super().variables }
          it { is_expected.to eq({}) }
        end
      end
    end

    describe 'without an offer' do
      it 'should not raise an exception' do
        expect { Adhearsion::Call.new }.not_to raise_error
      end
    end

    context 'registered event handlers' do
      let(:event)     { double 'Event' }
      let(:response)  { double 'Response' }

      it 'are called when messages are delivered' do
        expect(event).to receive(:foo?).and_return true
        expect(response).to receive(:call).once
        subject.register_event_handler(:foo?) { response.call }
        subject << event
      end

      context 'when a handler raises' do
        it 'does not cause the call actor to crash' do
          subject.register_event_handler { raise 'Boom' }
          subject << event
          expect(subject).to be_alive
        end

        it "triggers an exception event" do
          e = StandardError.new('Boom')
          expect(Events).to receive(:trigger).once.with(:exception, [e, subject.logger])
          subject.register_event_handler { raise e }
          subject << event
        end

        it 'executes all handlers for each event' do
          expect(response).to receive(:call).once
          subject.register_event_handler { raise 'Boom' }
          subject.register_event_handler { response.call }
          subject << event
        end
      end
    end

    describe "event handlers" do
      let(:response) { double 'Response' }

      describe "for joined events" do
        context "joined to another call" do
          let :event do
            Adhearsion::Event::Joined.new call_uri: 'footransport:foobar@rayo.net'
          end

          it "should trigger any on_joined callbacks set for the matching call ID" do
            expect(response).to receive(:call).once.with(event)
            subject.on_joined(:call_uri => 'footransport:foobar@rayo.net') { |event| response.call event }
            subject << event
          end

          it "should trigger any on_joined callbacks set for the matching call ID as a string" do
            expect(response).to receive(:call).once.with(event)
            subject.on_joined('foobar') { |event| response.call event }
            subject << event
          end

          it "should trigger any on_joined callbacks set for the matching call" do
            expect(response).to receive(:call).once.with(event)
            call = Call.new
            allow(call.wrapped_object).to receive_messages id: 'foobar', domain: 'rayo.net', transport: 'footransport'
            subject.on_joined(call) { |event| response.call event }
            subject << event
          end

          it "should not trigger on_joined callbacks for other call IDs" do
            expect(response).to receive(:call).never
            subject.on_joined(:call_uri => 'barfoo') { |event| response.call event }
            subject << event
          end

          it "should not trigger on_joined callbacks for mixers" do
            expect(response).to receive(:call).never
            subject.on_joined(:mixer_name => 'foobar') { |event| response.call event }
            subject << event
          end
        end

        context "joined to a mixer" do
          let :event do
            Adhearsion::Event::Joined.new :mixer_name => 'foobar'
          end

          it "should trigger on_joined callbacks for the matching mixer name" do
            expect(response).to receive(:call).once.with(event)
            subject.on_joined(:mixer_name => 'foobar') { |event| response.call event }
            subject << event
          end

          it "should not trigger on_joined callbacks for other mixer names" do
            expect(response).to receive(:call).never
            subject.on_joined(:mixer_name => 'barfoo') { |event| response.call event }
            subject << event
          end

          it "should not trigger any on_joined callbacks set for calls" do
            expect(response).to receive(:call).never
            subject.on_joined(:call_uri => 'foobar') { |event| response.call event }
            subject << event
          end

          it "should not trigger any on_joined callbacks set for the matching call ID as a string" do
            expect(response).to receive(:call).never
            subject.on_joined('foobar') { |event| response.call event }
            subject << event
          end

          it "should not trigger any on_joined callbacks set for the matching call" do
            expect(response).to receive(:call).never
            call = Call.new
            allow(call.wrapped_object).to receive_messages :id => 'foobar'
            subject.on_joined(call) { |event| response.call event }
            subject << event
          end
        end
      end

      describe "for unjoined events" do
        context "unjoined from another call" do
          let :event do
            Adhearsion::Event::Unjoined.new call_uri: 'footransport:foobar@rayo.net'
          end

          it "should trigger any on_unjoined callbacks set for the matching call ID" do
            expect(response).to receive(:call).once.with(event)
            subject.on_unjoined(:call_uri => 'footransport:foobar@rayo.net') { |event| response.call event }
            subject << event
          end

          it "should trigger any on_unjoined callbacks set for the matching call ID as a string" do
            expect(response).to receive(:call).once.with(event)
            subject.on_unjoined('foobar') { |event| response.call event }
            subject << event
          end

          it "should trigger any on_unjoined callbacks set for the matching call" do
            expect(response).to receive(:call).once.with(event)
            call = Call.new
            allow(call.wrapped_object).to receive_messages id: 'foobar', domain: 'rayo.net', transport: 'footransport'
            subject.on_unjoined(call) { |event| response.call event }
            subject << event
          end

          it "should not trigger on_unjoined callbacks for other call IDs" do
            expect(response).to receive(:call).never
            subject.on_unjoined(:call_uri => 'barfoo') { |event| response.call event }
            subject << event
          end

          it "should not trigger on_unjoined callbacks for mixers" do
            expect(response).to receive(:call).never
            subject.on_joined(:mixer_name => 'foobar') { |event| response.call event }
            subject << event
          end
        end

        context "unjoined from a mixer" do
          let :event do
            Adhearsion::Event::Unjoined.new :mixer_name => 'foobar'
          end

          it "should trigger on_unjoined callbacks for the matching mixer name" do
            expect(response).to receive(:call).once.with(event)
            subject.on_unjoined(:mixer_name => 'foobar') { |event| response.call event }
            subject << event
          end

          it "should not trigger on_unjoined callbacks for other mixer names" do
            expect(response).to receive(:call).never
            subject.on_unjoined(:mixer_name => 'barfoo') { |event| response.call event }
            subject << event
          end

          it "should not trigger any on_unjoined callbacks set for calls" do
            expect(response).to receive(:call).never
            subject.on_unjoined(:call_uri => 'foobar') { |event| response.call event }
            subject << event
          end

          it "should not trigger any on_unjoined callbacks set for the matching call ID as a string" do
            expect(response).to receive(:call).never
            subject.on_unjoined('foobar') { |event| response.call event }
            subject << event
          end

          it "should not trigger any on_unjoined callbacks set for the matching call" do
            expect(response).to receive(:call).never
            call = Call.new
            allow(call.wrapped_object).to receive_messages :id => 'foobar'
            subject.on_unjoined(call) { |event| response.call event }
            subject << event
          end
        end
      end

      describe "for end events" do
        let :event do
          Adhearsion::Event::End.new :reason => :hangup
        end

        it "should trigger any on_end callbacks set" do
          expect(response).to receive(:call).once.with(event)
          subject.on_end { |event| response.call event }
          subject << event
        end
      end

      context "when raising an exception" do
        it "does not kill the call actor" do
          subject.register_event_handler { |e| raise 'foo' }
          expect { subject << :foo }.not_to raise_error
          sleep 1
          expect(subject).to be_alive
        end

        it 'passes the exception through the Events system' do
          latch = CountDownLatch.new 1
          handler_id = Adhearsion::Events.exception do |e, l|
            expect(e).to be_a RuntimeError
            expect(l).to be subject.logger
            latch.countdown!
          end
          begin
            subject.register_event_handler { |e| raise 'foo' }
            expect { subject << :foo }.not_to raise_error
            expect(latch.wait(3)).to be true
          ensure
            Adhearsion::Events.unregister_handler :exception, handler_id
          end
        end
      end
    end

    context "peer registry" do
      let(:other_call_uri) { 'xmpp:foobar@example.com' }
      let(:other_call) { Call.new }

      before { allow(other_call).to receive_messages uri: other_call_uri }

      let :joined_event do
        Adhearsion::Event::Joined.new call_uri: other_call_uri
      end

      let :unjoined_event do
        Adhearsion::Event::Unjoined.new call_uri: other_call_uri
      end

      context "when we know about the joined call" do
        before { Adhearsion.active_calls << other_call }
        after { Adhearsion.active_calls.remove_inactive_call other_call }

        it "should add the peer to its registry" do
          subject << joined_event
          expect(subject.peers).to eq({'xmpp:foobar@example.com' => other_call})
        end

        context "in a handler for the joined event" do
          it "should have already populated the registry" do
            peer = nil

            subject.on_joined do |event|
              peer = subject.peers.keys.first
            end

            subject << joined_event

            expect(peer).to eq(other_call_uri)
          end
        end

        context "when being unjoined from a previously joined call" do
          before { subject << joined_event }

          it "should remove the peer from its registry" do
            expect(subject.peers).not_to eql({})
            subject << unjoined_event
            expect(subject.peers).to eql({})
          end

          context "in a handler for the unjoined event" do
            it "should have already been removed the registry" do
              peer_count = nil

              subject.on_unjoined do |event|
                peer_count = subject.peers.size
              end

              subject << unjoined_event

              expect(peer_count).to eq(0)
            end
          end
        end
      end

      context "when we don't know about the joined call" do
        it "should add a nil entry to its registry" do
          subject << joined_event
          expect(subject.peers).to eq({'xmpp:foobar@example.com' => nil})
        end

        context "in a handler for the joined event" do
          it "should have already populated the registry" do
            peer = nil

            subject.on_joined do |event|
              peer = subject.peers.keys.first
            end

            subject << joined_event

            expect(peer).to eq(other_call_uri)
          end
        end

        context "when being unjoined from a previously joined call" do
          before { subject << joined_event }

          it "should remove the peer from its registry" do
            expect(subject.peers).not_to eql({})
            subject << unjoined_event
            expect(subject.peers).to eql({})
          end

          context "in a handler for the unjoined event" do
            it "should have already been removed the registry" do
              peer_count = nil

              subject.on_unjoined do |event|
                peer_count = subject.peers.size
              end

              subject << unjoined_event

              expect(peer_count).to eq(0)
            end
          end
        end
      end

      it "should not return the same registry every call" do
        expect(subject.peers).not_to be subject.peers
      end
    end

    describe "#<<" do
      describe "with an End event" do
        let :end_event do
          Adhearsion::Event::End.new :reason => :hangup, :platform_code => 'arbitrary_code'
        end

        it "should mark the call as ended" do
          subject << end_event
          expect(subject).not_to be_active
        end

        it "should set the end reason" do
          subject << end_event
          expect(subject.end_reason).to eq(:hangup)
        end

        it "should set the end code" do
          subject << end_event
          expect(subject.end_code).to eq('arbitrary_code')
        end

        it "should set the end time" do
          finish_time = Time.local(2008, 9, 1, 12, 1, 3)
          Timecop.freeze finish_time
          expect(subject.end_time).to eq(nil)
          subject << end_event
          expect(subject.end_time).to eq(finish_time)
        end

        it "should set the call duration" do
          start_time = Time.local(2008, 9, 1, 12, 0, 0)
          Timecop.freeze start_time
          subject

          mid_point_time = Time.local(2008, 9, 1, 12, 0, 37)
          Timecop.freeze mid_point_time

          expect(subject.duration).to eq(37.0)

          finish_time = Time.local(2008, 9, 1, 12, 1, 3)
          Timecop.freeze finish_time

          subject << end_event

          future_time = Time.local(2008, 9, 1, 12, 2, 3)
          Timecop.freeze finish_time

          expect(subject.duration).to eq(63.0)
        end

        it "should instruct the command registry to terminate" do
          command = Adhearsion::Rayo::Command::Answer.new
          command.request!
          subject.future.write_and_await_response command
          subject << end_event
          expect(command.response(1)).to be_a Call::Hangup
        end

        it "removes itself from the active calls" do
          size_before = Adhearsion.active_calls.size

          Adhearsion.active_calls << subject
          expect(Adhearsion.active_calls.size).to be > size_before

          subject << end_event
          expect(Adhearsion.active_calls.size).to eq(size_before)
        end

        context "with no custom lifetime" do
          around do |example|
            old_val = Adhearsion.config.core.after_hangup_lifetime
            begin
              example.run
            rescue
              Adhearsion.config.core.after_hangup_lifetime = old_val
            end
          end

          it "shuts down the actor using platform config" do
            Adhearsion.config.core.after_hangup_lifetime = 2
            subject << end_event
            sleep 2.1
            expect(subject.alive?).to be false
            expect(subject.active?).to be false
            expect { subject.id }.to raise_error Call::ExpiredError, /expired and is no longer accessible/
          end
        end

        context "with a custom lifetime" do
          around do |example|
            old_val = Adhearsion.config.core.after_hangup_lifetime
            begin
              example.run
            rescue
              Adhearsion.config.core.after_hangup_lifetime = old_val
            end
          end

          it "shuts down the actor using the Call#after_hangup_lifetime" do
            Adhearsion.config.core.after_hangup_lifetime = 1
            subject.after_hangup_lifetime = 2
            subject << end_event
            sleep 1.1
            expect(subject.alive?).to be true
            expect(subject.active?).to be false
            sleep 1
            expect(subject.alive?).to be false
            expect(subject.active?).to be false
            expect { subject.id }.to raise_error Call::ExpiredError, /expired and is no longer accessible/
          end
        end
      end
    end

    describe "#wait_for_end" do
      let :end_event do
        Adhearsion::Event::End.new reason: :hangup
      end

      context "when the call has already ended" do
        before { subject << end_event }

        it "should return the end reason" do
          expect(subject.wait_for_end).to eq(:hangup)
        end
      end

      context "when the call has not yet ended" do
        it "should block until the call ends and return the end reason" do
          fut = subject.future.wait_for_end

          sleep 0.5
          expect(fut).not_to be_ready

          subject << end_event

          expect(fut.value).to eq(:hangup)
        end

        it "should unblock after a timeout" do
          fut = subject.future.wait_for_end 1

          sleep 0.5
          expect(fut).not_to be_ready

          sleep 0.5

          expect { fut.value }.to raise_error(Celluloid::ConditionError)
          expect(subject.alive?).to be(true)
        end
      end
    end

    describe "tagging a call" do
      it 'with a single Symbol' do
        expect {
          subject.tag :moderator
        }.not_to raise_error
      end

      it 'with multiple Symbols' do
        expect {
          subject.tag :moderator
          subject.tag :female
        }.not_to raise_error
      end

      it 'with a non-Symbol, non-String object' do
        bad_objects = [123, Object.new, 888.88, nil, true, false, StringIO.new]
        bad_objects.each do |bad_object|
          expect {
            subject.tag bad_object
          }.to raise_error ArgumentError
        end
      end
    end

    it "#remove_tag" do
      subject.tag :moderator
      subject.tag :female
      subject.remove_tag :female
      subject.tag :male
      expect(subject.tags).to eq([:moderator, :male])
    end

    describe "#tagged_with?" do
      it 'with one tag' do
        subject.tag :guest
        expect(subject.tagged_with?(:guest)).to be true
        expect(subject.tagged_with?(:authorized)).to be false
      end

      it 'with many tags' do
        subject.tag :customer
        subject.tag :authorized
        expect(subject.tagged_with?(:customer)).to be true
        expect(subject.tagged_with?(:authorized)).to be true
      end
    end

    describe "#write_command" do
      let(:command) { Adhearsion::Rayo::Command::Answer.new }

      it "should write the command to the Rayo connection" do
        expect(subject.wrapped_object).to receive(:client).once.and_return mock_client
        expect(mock_client).to receive(:execute_command).once.with(Adhearsion::Rayo::Command::Answer.new(target_call_id: call_id, domain: domain)).and_return true
        subject.write_command command
      end

      describe "with a hungup call" do
        before do
          expect(subject.wrapped_object).to receive(:active?).and_return(false)
        end

        it "should raise a Hangup exception" do
          expect { subject.write_command command }.to raise_error(Call::Hangup)
        end

        describe "if the command is a Hangup" do
          let(:command) { Adhearsion::Rayo::Command::Hangup.new }

          it "should not raise a Hangup exception" do
            expect { subject.write_command command }.not_to raise_error
          end
        end
      end
    end

    describe '#write_and_await_response' do
      let(:message) { Adhearsion::Rayo::Command::Accept.new }
      let(:response) { :foo }

      before do
        expect(message).to receive(:execute!).and_return true
        message.response = response
      end

      it "writes a command to the call" do
        expect(subject.wrapped_object).to receive(:write_command).once.with(message)
        subject.write_and_await_response message
      end

      it "removes the command from the registry after execution" do
        subject.write_and_await_response message
        expect(subject.commands).to be_empty
      end

      it "blocks until a response is received" do
        slow_command = Adhearsion::Rayo::Command::Dial.new
        slow_command.request!
        Thread.new do
          sleep 0.5
          slow_command.response = response
        end
        starting_time = Time.now
        subject.write_and_await_response slow_command
        expect(Time.now - starting_time).to be >= 0.5
      end

      context "while waiting for a response" do
        let(:slow_command) { Adhearsion::Rayo::Command::Dial.new }

        before { slow_command.request! }

        it "does not block the whole actor while waiting for a response" do
          fut = subject.future.write_and_await_response slow_command
          expect(subject.id).to eq(call_id)
          slow_command.response = response
          fut.value
        end

        it "adds the command to the registry" do
          subject.future.write_and_await_response slow_command
          sleep 0.2
          expect(subject.commands).not_to be_empty
          expect(subject.commands.first).to be slow_command
        end
      end

      describe "with a successful response" do
        it "returns the executed command" do
          expect(subject.write_and_await_response(message)).to be message
        end
      end

      describe "with an error response" do
        let(:new_exception) { Adhearsion::ProtocolError }
        let(:response) { new_exception.new }

        it "raises the error" do
          expect(Events).to receive(:trigger).never
          expect { subject.write_and_await_response message }.to raise_error new_exception
        end

        context "where the name is :item_not_found" do
          let(:response) { new_exception.new.setup :item_not_found }

          it "should raise a Hangup exception" do
            expect(Events).to receive(:trigger).never
            expect { subject.write_and_await_response message }.to raise_error Call::Hangup
          end
        end
      end

      describe "when the response times out" do
        before do
          message.target_call_id = call_id
          message.domain = domain
          expect(message).to receive(:response).and_raise Timeout::Error
        end

        it "should raise the error in the caller but not crash the actor" do
          expect { subject.write_and_await_response message }.to raise_error Call::CommandTimeout, message.to_s
          sleep 0.5
          expect(subject).to be_alive
        end
      end
    end

    describe "routing" do
      before do
        expect(Adhearsion::Process).to receive(:state_name).once.and_return process_state
      end

      after { subject.route }

      context "when the Adhearsion::Process is :booting" do
        let(:process_state) { :booting }

        it 'should reject a call with cause :declined' do
          expect_message_waiting_for_response Adhearsion::Rayo::Command::Reject.new(reason: :decline)
        end
      end

      [ :running, :stopping ].each do |state|
        context "when when Adhearsion::Process is in :#{state}" do
          let(:process_state) { state }

          it "should dispatch via the router" do
            Adhearsion.router do
              route 'foobar', Class.new
            end
            expect(Adhearsion.router).to receive(:handle).once.with subject
          end
        end
      end

      context "when when Adhearsion::Process is in :rejecting" do
        let(:process_state) { :rejecting }

        it 'should reject a call with cause :declined' do
          expect_message_waiting_for_response Adhearsion::Rayo::Command::Reject.new(reason: :decline)
        end
      end

      context "when when Adhearsion::Process is not :running, :stopping or :rejecting" do
        let(:process_state) { :foobar }

        it 'should reject a call with cause :error' do
          expect_message_waiting_for_response Adhearsion::Rayo::Command::Reject.new(reason: :error)
        end
      end
    end

    describe "#send_message" do
      it "should send a message through the Rayo connection using the call ID and domain" do
        expect(subject.wrapped_object).to receive(:client).once.and_return mock_client
        expect(mock_client).to receive(:send_message).once.with(subject.id, subject.domain, "Hello World!")
        subject.send_message "Hello World!"
      end

      it "should send a message with the given subject" do
        expect(subject.wrapped_object).to receive(:client).once.and_return mock_client
        expect(mock_client).to receive(:send_message).once.with(subject.id, subject.domain, nil, :subject => "Important Message")
        subject.send_message nil, :subject => "Important Message"
      end
    end

    describe "basic control commands" do
      describe '#accept' do
        describe "with no headers" do
          it 'should send an Accept message' do
            expect_message_waiting_for_response Adhearsion::Rayo::Command::Accept.new
            subject.accept
          end
        end

        describe "with headers set" do
          it 'should send an Accept message with the correct headers' do
            headers = {:foo => 'bar'}
            expect_message_waiting_for_response Adhearsion::Rayo::Command::Accept.new(:headers => headers)
            subject.accept headers
          end
        end

        describe "a second time" do
          it "should only send one Accept message" do
            expect_message_waiting_for_response Adhearsion::Rayo::Command::Accept.new
            subject.accept
            subject.accept
          end
        end

        context "with a failure response" do
          it 'should raise the error but not crash the actor' do
            error = Adhearsion::ProtocolError.new.setup(:service_unavailable)
            expect_message_waiting_for_response Adhearsion::Rayo::Command::Accept.new, error
            expect { subject.accept }.to raise_error error
            sleep 0.2
            expect(subject.alive?).to be true
          end
        end
      end

      describe '#answer' do
        describe "with no headers" do
          it 'should send an Answer message' do
            expect_message_waiting_for_response Adhearsion::Rayo::Command::Answer.new
            subject.answer
          end
        end

        describe "with headers set" do
          it 'should send an Answer message with the correct headers' do
            headers = {:foo => 'bar'}
            expect_message_waiting_for_response Adhearsion::Rayo::Command::Answer.new(:headers => headers)
            subject.answer headers
          end
        end

        context "with a failure response" do
          it 'should raise the error but not crash the actor' do
            error = Adhearsion::ProtocolError.new.setup(:service_unavailable)
            expect_message_waiting_for_response Adhearsion::Rayo::Command::Answer.new, error
            expect { subject.answer }.to raise_error error
            sleep 0.2
            expect(subject.alive?).to be true
          end
        end
      end

      describe '#reject' do
        describe "with a reason given" do
          it 'should send a Reject message with the correct reason' do
            expect_message_waiting_for_response Adhearsion::Rayo::Command::Reject.new(:reason => :decline)
            subject.reject :decline
          end
        end

        describe "with no reason given" do
          it 'should send a Reject message with the reason busy' do
            expect_message_waiting_for_response Adhearsion::Rayo::Command::Reject.new(:reason => :busy)
            subject.reject
          end
        end

        describe "with no headers" do
          it 'should send a Reject message' do
            expect_message_waiting_for_response do |c|
              c.is_a?(Adhearsion::Rayo::Command::Reject) && c.headers == {}
            end
            subject.reject
          end
        end

        describe "with headers set" do
          it 'should send a Hangup message with the correct headers' do
            headers = {:foo => 'bar'}
            expect_message_waiting_for_response do |c|
              c.is_a?(Adhearsion::Rayo::Command::Reject) && c.headers == headers
            end
            subject.reject nil, headers
          end
        end

        it "should immediately fire the :call_rejected event giving the call and the reason" do
          expect_message_waiting_for_response kind_of(Adhearsion::Rayo::Command::Reject)
          expect(Adhearsion::Events).to receive(:trigger).once.with(:call_rejected, :call => subject, :reason => :decline)
          subject.reject :decline
        end

        context "with a failure response" do
          it 'should raise the error but not crash the actor' do
            error = Adhearsion::ProtocolError.new.setup(:service_unavailable)
            expect_message_waiting_for_response Adhearsion::Rayo::Command::Reject.new(reason: :busy), error
            expect { subject.reject }.to raise_error error
            sleep 0.2
            expect(subject.alive?).to be true
          end
        end
      end

      describe '#redirect' do
        describe "with a target given" do
          it 'should send a Redirect message with the correct target' do
            expect_message_waiting_for_response Adhearsion::Rayo::Command::Redirect.new(to: 'sip:foo@bar.com')
            subject.redirect 'sip:foo@bar.com'
          end
        end

        describe "with no target given" do
          it 'should raise with ArgumentError' do
            expect { subject.redirect }.to raise_error(ArgumentError)
          end
        end

        describe "with no headers" do
          it 'should send a Redirect message' do
            expect_message_waiting_for_response do |c|
              c.is_a?(Adhearsion::Rayo::Command::Redirect) && c.headers == {}
            end
            subject.redirect 'sip:foo@bar.com'
          end
        end

        describe "with headers set" do
          it 'should send a Redirect message with the correct headers' do
            headers = {:foo => 'bar'}
            expect_message_waiting_for_response do |c|
              c.is_a?(Adhearsion::Rayo::Command::Redirect) && c.headers == headers
            end
            subject.redirect 'sip:foo@bar.com', headers
          end
        end

        context "with a failure response" do
          it 'should raise the error but not crash the actor' do
            error = Adhearsion::ProtocolError.new.setup(:service_unavailable)
            expect_message_waiting_for_response Adhearsion::Rayo::Command::Redirect.new(to: 'sip:foo@bar.com'), error
            expect { subject.redirect 'sip:foo@bar.com' }.to raise_error error
            sleep 0.2
            expect(subject.alive?).to be true
          end
        end
      end

      describe "#hangup" do
        describe "if the call is not active" do
          before do
            expect(subject.wrapped_object).to receive(:active?).and_return false
          end

          it "should do nothing and return false" do
            expect(subject).to receive(:write_and_await_response).never
            expect(subject.hangup).to be false
          end
        end

        describe "if the call is active" do
          it "should mark the call inactive" do
            expect_message_waiting_for_response Adhearsion::Rayo::Command::Hangup.new
            subject.hangup
            expect(subject).not_to be_active
          end

          describe "with no headers" do
            it 'should send a Hangup message' do
              expect_message_waiting_for_response Adhearsion::Rayo::Command::Hangup.new
              subject.hangup
            end
          end

          describe "with headers set" do
            it 'should send a Hangup message with the correct headers' do
              headers = {:foo => 'bar'}
              expect_message_waiting_for_response Adhearsion::Rayo::Command::Hangup.new(:headers => headers)
              subject.hangup headers
            end
          end
        end

        context "with a failure response" do
          it 'should raise the error but not crash the actor' do
            error = Adhearsion::ProtocolError.new.setup(:service_unavailable)
            expect_message_waiting_for_response Adhearsion::Rayo::Command::Hangup.new, error
            expect { subject.hangup }.to raise_error error
            sleep 0.2
            expect(subject.alive?).to be true
          end
        end
      end

      describe "#join" do
        def expect_join_with_options(options = {})
          Adhearsion::Rayo::Command::Join.new(options).tap do |join|
            expect_message_waiting_for_response join
          end
        end

        context "with a call" do
          let(:call_id) { rand.to_s }
          let(:domain)  { 'rayo.net' }
          let(:uri)     { "footransport:#{call_id}@#{domain}" }
          let(:target)  { described_class.new }

          before { allow(target.wrapped_object).to receive_messages uri: uri }

          it "should send a join command joining to the provided call ID" do
            expect_join_with_options call_uri: uri
            subject.join target
          end

          context "and direction/media options" do
            it "should send a join command with the correct options" do
              expect_join_with_options :call_id => uri, :media => :bridge, :direction => :recv
              subject.join target, :media => :bridge, :direction => :recv
            end
          end

          it "should return the command" do
            expect_join_with_options :call_id => uri, :media => :bridge, :direction => :recv
            result = subject.join target, :media => :bridge, :direction => :recv
            expect(result[:command]).to be_a Adhearsion::Rayo::Command::Join
            expect(result[:command].call_uri).to eql(uri)
            expect(result[:command].media).to eql(:bridge)
            expect(result[:command].direction).to eql(:recv)
          end

          it "should return something that can be blocked on until the join is complete" do
            expect_join_with_options :call_id => uri, :media => :bridge, :direction => :recv
            result = subject.join target, :media => :bridge, :direction => :recv

            expect(result[:joined_condition].wait(0.5)).to be_falsey

            subject << Adhearsion::Event::Joined.new(call_uri: uri)
            expect(result[:joined_condition].wait(0.5)).to be_truthy
          end

          it "should return something that can be blocked on until the entities are unjoined" do
            expect_join_with_options :call_id => uri, :media => :bridge, :direction => :recv
            result = subject.join target, :media => :bridge, :direction => :recv

            expect(result[:unjoined_condition].wait(0.5)).to be_falsey

            subject << Adhearsion::Event::Joined.new(call_uri: uri)
            expect(result[:unjoined_condition].wait(0.5)).to be_falsey

            subject << Adhearsion::Event::Unjoined.new(call_uri: uri)
            expect(result[:unjoined_condition].wait(0.5)).to be_truthy
          end

          it "should unblock all conditions on call end if no joined/unjoined events are received" do
            expect_join_with_options :call_id => uri, :media => :bridge, :direction => :recv
            result = subject.join target, :media => :bridge, :direction => :recv

            expect(result[:joined_condition].wait(0.5)).to be_falsey
            expect(result[:unjoined_condition].wait(0.5)).to be_falsey

            subject << Adhearsion::Event::End.new
            expect(result[:joined_condition].wait(0.5)).to be_truthy
            expect(result[:unjoined_condition].wait(0.5)).to be_truthy
          end

          it "should not error on call end when joined/unjoined events are received correctly" do
            expect_join_with_options :call_id => uri, :media => :bridge, :direction => :recv
            result = subject.join target, :media => :bridge, :direction => :recv

            subject << Adhearsion::Event::Joined.new(call_uri: uri)
            subject << Adhearsion::Event::Unjoined.new(call_uri: uri)

            subject << Adhearsion::Event::End.new
          end

          it "should not error if multiple joined events are received for the same join" do
            expect_join_with_options :call_id => uri, :media => :bridge, :direction => :recv
            result = subject.join target, :media => :bridge, :direction => :recv

            subject << Adhearsion::Event::Joined.new(call_uri: uri)
            subject << Adhearsion::Event::Joined.new(call_uri: uri)

            expect(subject).to be_alive
          end
        end

        context "with a call ID" do
          let(:target) { rand.to_s }
          let(:uri) { "footransport:#{target}@#{subject.domain}" }

          it "should send a join command joining to the provided call ID" do
            expect_join_with_options call_uri: uri
            subject.join target
          end

          context "and direction/media options" do
            it "should send a join command with the correct options" do
              expect_join_with_options :call_uri => uri, :media => :bridge, :direction => :recv
              subject.join target, :media => :bridge, :direction => :recv
            end
          end

          it "should return the command" do
            expect_join_with_options :call_id => uri, :media => :bridge, :direction => :recv
            result = subject.join target, :media => :bridge, :direction => :recv
            expect(result[:command]).to be_a Adhearsion::Rayo::Command::Join
            expect(result[:command].call_uri).to eql(uri)
            expect(result[:command].media).to eql(:bridge)
            expect(result[:command].direction).to eql(:recv)
          end

          it "should return something that can be blocked on until the join is complete" do
            expect_join_with_options :call_id => uri, :media => :bridge, :direction => :recv
            result = subject.join target, :media => :bridge, :direction => :recv

            expect(result[:joined_condition].wait(0.5)).to be_falsey

            subject << Adhearsion::Event::Joined.new(call_uri: uri)
            expect(result[:joined_condition].wait(0.5)).to be_truthy
          end

          it "should return something that can be blocked on until the entities are unjoined" do
            expect_join_with_options :call_id => uri, :media => :bridge, :direction => :recv
            result = subject.join target, :media => :bridge, :direction => :recv

            expect(result[:unjoined_condition].wait(0.5)).to be_falsey

            subject << Adhearsion::Event::Joined.new(call_uri: uri)
            expect(result[:unjoined_condition].wait(0.5)).to be_falsey

            subject << Adhearsion::Event::Unjoined.new(call_uri: uri)
            expect(result[:unjoined_condition].wait(0.5)).to be_truthy
          end

          it "should unblock all conditions on call end if no joined/unjoined events are received" do
            expect_join_with_options :call_id => uri, :media => :bridge, :direction => :recv
            result = subject.join target, :media => :bridge, :direction => :recv

            expect(result[:joined_condition].wait(0.5)).to be_falsey
            expect(result[:unjoined_condition].wait(0.5)).to be_falsey

            subject << Adhearsion::Event::End.new
            expect(result[:joined_condition].wait(0.5)).to be_truthy
            expect(result[:unjoined_condition].wait(0.5)).to be_truthy
          end

          it "should not error on call end when joined/unjoined events are received correctly" do
            expect_join_with_options :call_id => uri, :media => :bridge, :direction => :recv
            result = subject.join target, :media => :bridge, :direction => :recv

            subject << Adhearsion::Event::Joined.new(call_uri: uri)
            subject << Adhearsion::Event::Unjoined.new(call_uri: uri)

            subject << Adhearsion::Event::End.new
          end

          it "should not error if multiple joined events are received for the same join" do
            expect_join_with_options :call_id => uri, :media => :bridge, :direction => :recv
            result = subject.join target, :media => :bridge, :direction => :recv

            subject << Adhearsion::Event::Joined.new(call_uri: uri)
            subject << Adhearsion::Event::Joined.new(call_uri: uri)

            expect(subject).to be_alive
          end
        end

        context "with a call URI as a hash key" do
          let(:call_id) { rand.to_s }
          let(:uri) { call_id }
          let(:target)  { { :call_uri => call_id } }

          it "should send a join command joining to the provided call ID" do
            expect_join_with_options :call_uri => call_id
            subject.join target
          end

          context "and direction/media options" do
            it "should send a join command with the correct options" do
              expect_join_with_options :call_uri => call_id, :media => :bridge, :direction => :recv
              subject.join target.merge({:media => :bridge, :direction => :recv})
            end
          end

          it "should return the command" do
            expect_join_with_options :call_id => uri, :media => :bridge, :direction => :recv
            result = subject.join target.merge({:media => :bridge, :direction => :recv})
            expect(result[:command]).to be_a Adhearsion::Rayo::Command::Join
            expect(result[:command].call_uri).to eql(uri)
            expect(result[:command].media).to eql(:bridge)
            expect(result[:command].direction).to eql(:recv)
          end

          it "should return something that can be blocked on until the join is complete" do
            expect_join_with_options :call_id => uri, :media => :bridge, :direction => :recv
            result = subject.join target.merge({:media => :bridge, :direction => :recv})

            expect(result[:joined_condition].wait(0.5)).to be_falsey

            subject << Adhearsion::Event::Joined.new(call_uri: uri)
            expect(result[:joined_condition].wait(0.5)).to be_truthy
          end

          it "should return something that can be blocked on until the entities are unjoined" do
            expect_join_with_options :call_id => uri, :media => :bridge, :direction => :recv
            result = subject.join target.merge({:media => :bridge, :direction => :recv})

            expect(result[:unjoined_condition].wait(0.5)).to be_falsey

            subject << Adhearsion::Event::Joined.new(call_uri: uri)
            expect(result[:unjoined_condition].wait(0.5)).to be_falsey

            subject << Adhearsion::Event::Unjoined.new(call_uri: uri)
            expect(result[:unjoined_condition].wait(0.5)).to be_truthy
          end

          it "should unblock all conditions on call end if no joined/unjoined events are received" do
            expect_join_with_options :call_id => uri, :media => :bridge, :direction => :recv
            result = subject.join target.merge({:media => :bridge, :direction => :recv})

            expect(result[:joined_condition].wait(0.5)).to be_falsey
            expect(result[:unjoined_condition].wait(0.5)).to be_falsey

            subject << Adhearsion::Event::End.new
            expect(result[:joined_condition].wait(0.5)).to be_truthy
            expect(result[:unjoined_condition].wait(0.5)).to be_truthy
          end

          it "should not error on call end when joined/unjoined events are received correctly" do
            expect_join_with_options :call_id => uri, :media => :bridge, :direction => :recv
            result = subject.join target.merge({:media => :bridge, :direction => :recv})

            subject << Adhearsion::Event::Joined.new(call_uri: uri)
            subject << Adhearsion::Event::Unjoined.new(call_uri: uri)

            subject << Adhearsion::Event::End.new
          end

          it "should not error if multiple joined events are received for the same join" do
            expect_join_with_options :call_id => uri, :media => :bridge, :direction => :recv
            result = subject.join target.merge({:media => :bridge, :direction => :recv})

            subject << Adhearsion::Event::Joined.new(call_uri: uri)
            subject << Adhearsion::Event::Joined.new(call_uri: uri)

            expect(subject).to be_alive
          end
        end

        context "with a mixer name as a hash key" do
          let(:mixer_name)  { rand.to_s }
          let(:target)      { { :mixer_name => mixer_name } }

          it "should send a join command joining to the provided call ID" do
            expect_join_with_options :mixer_name => mixer_name
            subject.join target
          end

          context "and direction/media options" do
            it "should send a join command with the correct options" do
              expect_join_with_options :mixer_name => mixer_name, :media => :bridge, :direction => :recv
              subject.join target.merge({:media => :bridge, :direction => :recv})
            end
          end

          it "should return the command" do
            expect_join_with_options :mixer_name => mixer_name, :media => :bridge, :direction => :recv
            result = subject.join target.merge({:media => :bridge, :direction => :recv})
            expect(result[:command]).to be_a Adhearsion::Rayo::Command::Join
            expect(result[:command].mixer_name).to eql(mixer_name)
            expect(result[:command].media).to eql(:bridge)
            expect(result[:command].direction).to eql(:recv)
          end

          it "should return something that can be blocked on until the join is complete" do
            expect_join_with_options :mixer_name => mixer_name, :media => :bridge, :direction => :recv
            result = subject.join target.merge({:media => :bridge, :direction => :recv})

            expect(result[:joined_condition].wait(0.5)).to be_falsey

            subject << Adhearsion::Event::Joined.new(mixer_name: mixer_name)
            expect(result[:joined_condition].wait(0.5)).to be_truthy
          end

          it "should return something that can be blocked on until the entities are unjoined" do
            expect_join_with_options :mixer_name => mixer_name, :media => :bridge, :direction => :recv
            result = subject.join target.merge({:media => :bridge, :direction => :recv})

            expect(result[:unjoined_condition].wait(0.5)).to be_falsey

            subject << Adhearsion::Event::Joined.new(mixer_name: mixer_name)
            expect(result[:unjoined_condition].wait(0.5)).to be_falsey

            subject << Adhearsion::Event::Unjoined.new(mixer_name: mixer_name)
            expect(result[:unjoined_condition].wait(0.5)).to be_truthy
          end

          it "should unblock all conditions on call end if no joined/unjoined events are received" do
            expect_join_with_options :mixer_name => mixer_name, :media => :bridge, :direction => :recv
            result = subject.join target.merge({:media => :bridge, :direction => :recv})

            expect(result[:joined_condition].wait(0.5)).to be_falsey
            expect(result[:unjoined_condition].wait(0.5)).to be_falsey

            subject << Adhearsion::Event::End.new
            expect(result[:joined_condition].wait(0.5)).to be_truthy
            expect(result[:unjoined_condition].wait(0.5)).to be_truthy
          end

          it "should not error on call end when joined/unjoined events are received correctly" do
            expect_join_with_options :mixer_name => mixer_name, :media => :bridge, :direction => :recv
            result = subject.join target.merge({:media => :bridge, :direction => :recv})

            subject << Adhearsion::Event::Joined.new(mixer_name: mixer_name)
            subject << Adhearsion::Event::Unjoined.new(mixer_name: mixer_name)

            subject << Adhearsion::Event::End.new
          end

          it "should not error if multiple joined events are received for the same join" do
            expect_join_with_options :mixer_name => mixer_name, :media => :bridge, :direction => :recv
            result = subject.join target.merge({:media => :bridge, :direction => :recv})

            subject << Adhearsion::Event::Joined.new(mixer_name: mixer_name)
            subject << Adhearsion::Event::Joined.new(mixer_name: mixer_name)

            expect(subject).to be_alive
          end
        end

        context "with a call ID and a mixer name as hash keys" do
          let(:call_id)     { rand.to_s }
          let(:mixer_name)  { rand.to_s }
          let(:target)      { { :call_uri => call_id, :mixer_name => mixer_name } }

          it "should raise an ArgumentError" do
            expect { subject.join target }.to raise_error ArgumentError, /call URI and mixer name/
          end
        end

        context "with a failure response" do
          it 'should raise the error but not crash the actor' do
            error = Adhearsion::ProtocolError.new.setup(:service_unavailable)
            expect_message_waiting_for_response Adhearsion::Rayo::Command::Join.new(call_id: 'footransport:foo@rayo.net'), error
            expect { subject.join 'foo' }.to raise_error error
            sleep 0.2
            expect(subject.alive?).to be true
          end
        end
      end

      describe "#unjoin" do
        def expect_unjoin_with_options(options = {})
          Adhearsion::Rayo::Command::Unjoin.new(options).tap do |unjoin|
            expect_message_waiting_for_response unjoin
          end
        end

        context "without a target" do
          it "should send an unjoin command unjoining from every existing join" do
            expect_unjoin_with_options nil
            subject.unjoin
          end
        end

        context "with a call" do
          let(:call_id) { rand.to_s }
          let(:domain)  { 'rayo.net' }
          let(:uri)     { "footransport:#{call_id}@#{domain}" }
          let(:target)  { described_class.new }

          before { allow(target.wrapped_object).to receive_messages uri: uri }

          it "should send an unjoin command unjoining from the provided call ID" do
            expect_unjoin_with_options call_uri: "footransport:#{call_id}@#{domain}"
            subject.unjoin target
          end
        end

        context "with a call ID" do
          let(:target) { rand.to_s }

          it "should send an unjoin command unjoining from the provided call ID" do
            expect_unjoin_with_options call_uri: "footransport:#{target}@#{subject.domain}"
            subject.unjoin target
          end
        end

        context "with a call URI as a hash key" do
          let(:call_id) { rand.to_s }
          let(:target)  { { call_uri: call_id } }

          it "should send an unjoin command unjoining from the provided call ID" do
            expect_unjoin_with_options call_uri: call_id
            subject.unjoin target
          end
        end

        context "with a mixer name as a hash key" do
          let(:mixer_name)  { rand.to_s }
          let(:target)      { { :mixer_name => mixer_name } }

          it "should send an unjoin command unjoining from the provided call ID" do
            expect_unjoin_with_options :mixer_name => mixer_name
            subject.unjoin target
          end
        end

        context "with a call URI and a mixer name as hash keys" do
          let(:call_id)     { rand.to_s }
          let(:mixer_name)  { rand.to_s }
          let(:target)      { { call_uri: call_id, mixer_name: mixer_name } }

          it "should raise an ArgumentError" do
            expect { subject.unjoin target }.to raise_error ArgumentError, /call URI and mixer name/
          end
        end

        context "with a failure response" do
          it 'should raise the error but not crash the actor' do
            error = Adhearsion::ProtocolError.new.setup(:service_unavailable)
            expect_message_waiting_for_response Adhearsion::Rayo::Command::Unjoin.new(call_id: 'footransport:foo@rayo.net'), error
            expect { subject.unjoin 'foo' }.to raise_error error
            sleep 0.2
            expect(subject.alive?).to be true
          end
        end
      end

      describe "#mute" do
        it 'should send a Mute message' do
          expect_message_waiting_for_response Adhearsion::Rayo::Command::Mute.new
          subject.mute
        end

        context "with a failure response" do
          it 'should raise the error but not crash the actor' do
            error = Adhearsion::ProtocolError.new.setup(:service_unavailable)
            expect_message_waiting_for_response Adhearsion::Rayo::Command::Mute.new, error
            expect { subject.mute }.to raise_error error
            sleep 0.2
            expect(subject.alive?).to be true
          end
        end
      end

      describe "#unmute" do
        it 'should send a Mute message' do
          expect_message_waiting_for_response Adhearsion::Rayo::Command::Unmute.new
          subject.unmute
        end

        context "with a failure response" do
          it 'should raise the error but not crash the actor' do
            error = Adhearsion::ProtocolError.new.setup(:service_unavailable)
            expect_message_waiting_for_response Adhearsion::Rayo::Command::Unmute.new, error
            expect { subject.unmute }.to raise_error error
            sleep 0.2
            expect(subject.alive?).to be true
          end
        end
      end

      describe "#execute_controller" do
        let(:latch)           { CountDownLatch.new 1 }
        let(:mock_controller) { CallController.new(subject) }

        before do
          allow(subject.wrapped_object).to receive_messages :write_and_await_response => true
        end

        it "should call #bg_exec on the controller instance" do
          expect(mock_controller).to receive(:exec).once
          subject.execute_controller mock_controller, lambda { |call| latch.countdown! }
          expect(latch.wait(3)).to be_truthy
        end

        it "should use the passed block as a controller if none is specified" do
          expect(mock_controller).to receive(:exec).once
          expect(CallController).to receive(:new).once.and_return mock_controller
          subject.execute_controller nil, lambda { |call| latch.countdown! } do
            foo
          end
          expect(latch.wait(3)).to be_truthy
        end

        it "should raise ArgumentError if both a controller and a block are passed" do
          expect { subject.execute_controller(mock_controller) { foo } }.to raise_error(ArgumentError)
        end

        it "should pass the exception to the events system" do
          latch = CountDownLatch.new 1
          Adhearsion::Events.exception do |e, l|
            expect(e).to be_a RuntimeError
            expect(l).to be subject.logger
            latch.countdown!
          end
          subject.execute_controller BrokenController.new(subject), lambda { |call| latch.countdown! }
          expect(latch.wait(3)).to be true
        end

        it "should execute a callback after the controller executes" do
          foo = nil
          subject.execute_controller mock_controller, lambda { |call| foo = call; latch.countdown! }
          expect(latch.wait(3)).to be_truthy
          expect(foo).to be subject
        end

        it "should prevent exceptions in controllers from being raised" do
          expect(mock_controller).to receive(:run).once.ordered.and_raise StandardError
          expect { subject.execute_controller mock_controller, lambda { |call| latch.countdown! } }.to_not raise_error
          expect(latch.wait(3)).to be_truthy
          expect(subject.alive?).to be true
        end
      end

      describe "#register_controller" do
        it "should add the controller to a list on the call" do
          subject.register_controller :foo
          expect(subject.controllers).to include :foo
        end
      end

      context "with two controllers registered" do
        let(:controller1) { double 'CallController1' }
        let(:controller2) { double 'CallController2' }

        before { subject.controllers << controller1 << controller2 }

        describe "#pause_controllers" do
          it "should pause each of the registered controllers" do
            expect(controller1).to receive(:pause!).once
            expect(controller2).to receive(:pause!).once

            subject.pause_controllers
          end
        end

        describe "#resume_controllers" do
          it "should resume each of the registered controllers" do
            expect(controller1).to receive(:resume!).once
            expect(controller2).to receive(:resume!).once

            subject.resume_controllers
          end
        end
      end

      describe "after termination" do
        it "should delete its logger" do
          logger = subject.logger
          subject.terminate
          expect(::Logging::Repository.instance[logger.name]).to be_nil
        end
      end
    end

    describe Call::CommandRegistry do
      subject { Call::CommandRegistry.new }

      it { is_expected.to be_empty }

      describe "#<<" do
        it "should add a command to the registry" do
          subject << :foo
          expect(subject).not_to be_empty
        end
      end

      describe "#delete" do
        it "should remove a command from the registry" do
          subject << :foo
          expect(subject).not_to be_empty
          subject.delete :foo
          expect(subject).to be_empty
        end
      end

      describe "#terminate" do
        let :commands do
          [
            Adhearsion::Rayo::Command::Answer.new,
            Adhearsion::Rayo::Command::Answer.new
          ]
        end

        it "should set each command's response to an instance of Adhearsion::Hangup if it doesn't already have a response" do
          finished_command = Adhearsion::Rayo::Command::Answer.new
          finished_command.request!
          finished_command.response = :foo
          subject << finished_command
          commands.each do |command|
            command.request!
            subject << command
          end
          subject.terminate
          commands.each do |command|
            expect(command.response).to be_a Call::Hangup
          end
          expect(finished_command.response).to eq(:foo)
        end
      end
    end
  end
end
