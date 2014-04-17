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
      Punchblock::Event::Offer.new target_call_id: call_id,
                                   domain: domain,
                                   transport: transport,
                                   to: to,
                                   from: from,
                                   headers: headers,
                                   timestamp: base_time
    end

    subject { Adhearsion::Call.new offer }

    before do
      offer.stub(:client).and_return(mock_client)
    end

    after do
      Adhearsion.active_calls.clear
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
      foo.should == :baz
    end

    it { should respond_to :<< }

    its(:end_reason) { should be == nil }
    it { should be_active }

    its(:commands) { should be_empty }

    its(:id)      { should be == call_id }
    its(:domain)  { should be == domain }
    its(:uri)     { should be == "footransport:#{call_id}@#{domain}" }
    its(:to)      { should be == to }
    its(:from)    { should be == from }

    its(:auto_hangup) { should be_true }

    context "when the ID is nil" do
      let(:call_id) { nil }

      its(:uri) { should be == nil }
    end

    context "when the domain is nil" do
      let(:domain) { nil }

      its(:uri) { should be == "footransport:#{call_id}" }
    end

    context "when the transport is nil" do
      let(:transport) { nil }

      its(:uri) { should be == "#{call_id}@#{domain}" }
    end

    it "should mark its start time" do
      subject.start_time.should == base_time
    end

    describe "#commands" do
      it "should use a duplicating accessor for the command registry" do
        subject.commands.should_not be subject.commands
      end
    end

    describe "its variables" do
      context "with an offer" do
        context "with headers" do
          let(:headers)   { {'X-foo' => 'bar'} }
          its(:variables) { should be == {'x_foo' => 'bar'} }

          it "should be made available via []" do
            subject[:x_foo].should be == 'bar'
          end

          it "should be alterable using []=" do
            subject[:x_foo] = 'baz'
            subject[:x_foo].should be == 'baz'
          end

          context "when receiving an event with headers" do
            let(:event) { Punchblock::Event::End.new :headers => {'X-bar' => 'foo'} }

            it "should merge later headers" do
              subject << event
              subject.variables.should be == {'x_foo' => 'bar', 'x_bar' => 'foo'}
            end

            context "with have symbol names" do
              let(:event) { Punchblock::Event::End.new :headers => {:x_bar => 'foo'} }

              it "should merge later headers" do
                subject << event
                subject.variables.should be == {'x_foo' => 'bar', 'x_bar' => 'foo'}
              end
            end
          end

          context "when sending a command with headers" do
            let(:command) { Punchblock::Command::Accept.new :headers => {'X-bar' => 'foo'} }

            it "should merge later headers" do
              subject.write_command command
              subject.variables.should be == {'x_foo' => 'bar', 'x_bar' => 'foo'}
            end
          end
        end

        context "without headers" do
          let(:headers)   { nil }
          its(:variables) { should be == {} }
        end
      end

      context "without an offer" do
        let(:offer)     { nil }
        its(:variables) { should be == {} }
      end
    end

    describe 'without an offer' do
      it 'should not raise an exception' do
        lambda { Adhearsion::Call.new }.should_not raise_error
      end
    end

    context 'registered event handlers' do
      let(:event)     { double 'Event' }
      let(:response)  { double 'Response' }

      it 'are called when messages are delivered' do
        event.should_receive(:foo?).and_return true
        response.should_receive(:call).once
        subject.register_event_handler(:foo?) { response.call }
        subject << event
      end

      context 'when a handler raises' do
        it 'does not cause the call actor to crash' do
          subject.register_event_handler { raise 'Boom' }
          subject << event
          subject.should be_alive
        end

        it "triggers an exception event" do
          e = StandardError.new('Boom')
          Events.should_receive(:trigger).once.with(:exception, [e, subject.logger])
          subject.register_event_handler { raise e }
          subject << event
        end

        it 'executes all handlers for each event' do
          response.should_receive(:call).once
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
            Punchblock::Event::Joined.new call_uri: 'footransport:foobar@rayo.net'
          end

          it "should trigger any on_joined callbacks set for the matching call ID" do
            response.should_receive(:call).once.with(event)
            subject.on_joined(:call_uri => 'footransport:foobar@rayo.net') { |event| response.call event }
            subject << event
          end

          it "should trigger any on_joined callbacks set for the matching call ID as a string" do
            response.should_receive(:call).once.with(event)
            subject.on_joined('foobar') { |event| response.call event }
            subject << event
          end

          it "should trigger any on_joined callbacks set for the matching call" do
            response.should_receive(:call).once.with(event)
            call = Call.new
            call.wrapped_object.stub id: 'foobar', domain: 'rayo.net', transport: 'footransport'
            subject.on_joined(call) { |event| response.call event }
            subject << event
          end

          it "should not trigger on_joined callbacks for other call IDs" do
            response.should_receive(:call).never
            subject.on_joined(:call_uri => 'barfoo') { |event| response.call event }
            subject << event
          end

          it "should not trigger on_joined callbacks for mixers" do
            response.should_receive(:call).never
            subject.on_joined(:mixer_name => 'foobar') { |event| response.call event }
            subject << event
          end
        end

        context "joined to a mixer" do
          let :event do
            Punchblock::Event::Joined.new :mixer_name => 'foobar'
          end

          it "should trigger on_joined callbacks for the matching mixer name" do
            response.should_receive(:call).once.with(event)
            subject.on_joined(:mixer_name => 'foobar') { |event| response.call event }
            subject << event
          end

          it "should not trigger on_joined callbacks for other mixer names" do
            response.should_receive(:call).never
            subject.on_joined(:mixer_name => 'barfoo') { |event| response.call event }
            subject << event
          end

          it "should not trigger any on_joined callbacks set for calls" do
            response.should_receive(:call).never
            subject.on_joined(:call_uri => 'foobar') { |event| response.call event }
            subject << event
          end

          it "should not trigger any on_joined callbacks set for the matching call ID as a string" do
            response.should_receive(:call).never
            subject.on_joined('foobar') { |event| response.call event }
            subject << event
          end

          it "should not trigger any on_joined callbacks set for the matching call" do
            response.should_receive(:call).never
            call = Call.new
            call.wrapped_object.stub :id => 'foobar'
            subject.on_joined(call) { |event| response.call event }
            subject << event
          end
        end
      end

      describe "for unjoined events" do
        context "unjoined from another call" do
          let :event do
            Punchblock::Event::Unjoined.new call_uri: 'footransport:foobar@rayo.net'
          end

          it "should trigger any on_unjoined callbacks set for the matching call ID" do
            response.should_receive(:call).once.with(event)
            subject.on_unjoined(:call_uri => 'footransport:foobar@rayo.net') { |event| response.call event }
            subject << event
          end

          it "should trigger any on_unjoined callbacks set for the matching call ID as a string" do
            response.should_receive(:call).once.with(event)
            subject.on_unjoined('foobar') { |event| response.call event }
            subject << event
          end

          it "should trigger any on_unjoined callbacks set for the matching call" do
            response.should_receive(:call).once.with(event)
            call = Call.new
            call.wrapped_object.stub id: 'foobar', domain: 'rayo.net', transport: 'footransport'
            subject.on_unjoined(call) { |event| response.call event }
            subject << event
          end

          it "should not trigger on_unjoined callbacks for other call IDs" do
            response.should_receive(:call).never
            subject.on_unjoined(:call_uri => 'barfoo') { |event| response.call event }
            subject << event
          end

          it "should not trigger on_unjoined callbacks for mixers" do
            response.should_receive(:call).never
            subject.on_joined(:mixer_name => 'foobar') { |event| response.call event }
            subject << event
          end
        end

        context "unjoined from a mixer" do
          let :event do
            Punchblock::Event::Unjoined.new :mixer_name => 'foobar'
          end

          it "should trigger on_unjoined callbacks for the matching mixer name" do
            response.should_receive(:call).once.with(event)
            subject.on_unjoined(:mixer_name => 'foobar') { |event| response.call event }
            subject << event
          end

          it "should not trigger on_unjoined callbacks for other mixer names" do
            response.should_receive(:call).never
            subject.on_unjoined(:mixer_name => 'barfoo') { |event| response.call event }
            subject << event
          end

          it "should not trigger any on_unjoined callbacks set for calls" do
            response.should_receive(:call).never
            subject.on_unjoined(:call_uri => 'foobar') { |event| response.call event }
            subject << event
          end

          it "should not trigger any on_unjoined callbacks set for the matching call ID as a string" do
            response.should_receive(:call).never
            subject.on_unjoined('foobar') { |event| response.call event }
            subject << event
          end

          it "should not trigger any on_unjoined callbacks set for the matching call" do
            response.should_receive(:call).never
            call = Call.new
            call.wrapped_object.stub :id => 'foobar'
            subject.on_unjoined(call) { |event| response.call event }
            subject << event
          end
        end
      end

      describe "for end events" do
        let :event do
          Punchblock::Event::End.new :reason => :hangup
        end

        it "should trigger any on_end callbacks set" do
          response.should_receive(:call).once.with(event)
          subject.on_end { |event| response.call event }
          subject << event
        end
      end

      context "when raising an exception" do
        it "does not kill the call actor" do
          subject.register_event_handler { |e| raise 'foo' }
          lambda { subject << :foo }.should_not raise_error
          sleep 1
          subject.should be_alive
        end

        it 'passes the exception through the Events system' do
          latch = CountDownLatch.new 1
          Adhearsion::Events.exception do |e, l|
            e.should be_a RuntimeError
            l.should be subject.logger
            latch.countdown!
          end
          subject.register_event_handler { |e| raise 'foo' }
          lambda { subject << :foo }.should_not raise_error
          latch.wait(3).should be true
          Adhearsion::Events.clear_handlers :exception
        end
      end
    end

    context "peer registry" do
      let(:other_call_uri) { 'xmpp:foobar@example.com' }
      let(:other_call) { Call.new }

      before { other_call.stub uri: other_call_uri }

      let :joined_event do
        Punchblock::Event::Joined.new call_uri: other_call_uri
      end

      let :unjoined_event do
        Punchblock::Event::Unjoined.new call_uri: other_call_uri
      end

      context "when we know about the joined call" do
        before { Adhearsion.active_calls << other_call }
        after { Adhearsion.active_calls.remove_inactive_call other_call }

        it "should add the peer to its registry" do
          subject << joined_event
          subject.peers.should == {'xmpp:foobar@example.com' => other_call}
        end

        context "in a handler for the joined event" do
          it "should have already populated the registry" do
            peer = nil

            subject.on_joined do |event|
              peer = subject.peers.keys.first
            end

            subject << joined_event

            peer.should == other_call_uri
          end
        end

        context "when being unjoined from a previously joined call" do
          before { subject << joined_event }

          it "should remove the peer from its registry" do
            subject.peers.should_not eql({})
            subject << unjoined_event
            subject.peers.should eql({})
          end

          context "in a handler for the unjoined event" do
            it "should have already been removed the registry" do
              peer_count = nil

              subject.on_unjoined do |event|
                peer_count = subject.peers.size
              end

              subject << unjoined_event

              peer_count.should == 0
            end
          end
        end
      end

      context "when we don't know about the joined call" do
        it "should add a nil entry to its registry" do
          subject << joined_event
          subject.peers.should == {'xmpp:foobar@example.com' => nil}
        end

        context "in a handler for the joined event" do
          it "should have already populated the registry" do
            peer = nil

            subject.on_joined do |event|
              peer = subject.peers.keys.first
            end

            subject << joined_event

            peer.should == other_call_uri
          end
        end

        context "when being unjoined from a previously joined call" do
          before { subject << joined_event }

          it "should remove the peer from its registry" do
            subject.peers.should_not eql({})
            subject << unjoined_event
            subject.peers.should eql({})
          end

          context "in a handler for the unjoined event" do
            it "should have already been removed the registry" do
              peer_count = nil

              subject.on_unjoined do |event|
                peer_count = subject.peers.size
              end

              subject << unjoined_event

              peer_count.should == 0
            end
          end
        end
      end

      it "should not return the same registry every call" do
        subject.peers.should_not be subject.peers
      end
    end

    describe "#<<" do
      describe "with a Punchblock End" do
        let :end_event do
          Punchblock::Event::End.new :reason => :hangup, :platform_code => 'arbitrary_code'
        end

        it "should mark the call as ended" do
          subject << end_event
          subject.should_not be_active
        end

        it "should set the end reason" do
          subject << end_event
          subject.end_reason.should be == :hangup
        end

        it "should set the end code" do
          subject << end_event
          subject.end_code.should be == 'arbitrary_code'
        end

        it "should set the end time" do
          finish_time = Time.local(2008, 9, 1, 12, 1, 3)
          Timecop.freeze finish_time
          subject.end_time.should == nil
          subject << end_event
          subject.end_time.should == finish_time
        end

        it "should set the call duration" do
          start_time = Time.local(2008, 9, 1, 12, 0, 0)
          Timecop.freeze start_time
          subject

          mid_point_time = Time.local(2008, 9, 1, 12, 0, 37)
          Timecop.freeze mid_point_time

          subject.duration.should == 37.0

          finish_time = Time.local(2008, 9, 1, 12, 1, 3)
          Timecop.freeze finish_time

          subject << end_event

          future_time = Time.local(2008, 9, 1, 12, 2, 3)
          Timecop.freeze finish_time

          subject.duration.should == 63.0
        end

        it "should instruct the command registry to terminate" do
          command = Punchblock::Command::Answer.new
          command.request!
          subject.future.write_and_await_response command
          subject << end_event
          command.response(1).should be_a Call::Hangup
        end

        it "removes itself from the active calls" do
          size_before = Adhearsion.active_calls.size

          Adhearsion.active_calls << subject
          Adhearsion.active_calls.size.should be > size_before

          subject << end_event
          Adhearsion.active_calls.size.should be == size_before
        end

        it "shuts down the actor" do
          Adhearsion.config.platform.after_hangup_lifetime = 2
          subject << end_event
          sleep 2.1
          subject.should_not be_alive
          lambda { subject.id }.should raise_error Call::ExpiredError, /expired and is no longer accessible/
        end
      end
    end

    describe "#wait_for_end" do
      let :end_event do
        Punchblock::Event::End.new reason: :hangup
      end

      context "when the call has already ended" do
        before { subject << end_event }

        it "should return the end reason" do
          subject.wait_for_end.should == :hangup
        end
      end

      context "when the call has not yet ended" do
        it "should block until the call ends and return the end reason" do
          fut = subject.future.wait_for_end

          sleep 0.5
          fut.should_not be_ready

          subject << end_event

          fut.value.should == :hangup
        end
      end
    end

    describe "tagging a call" do
      it 'with a single Symbol' do
        lambda {
          subject.tag :moderator
        }.should_not raise_error
      end

      it 'with multiple Symbols' do
        lambda {
          subject.tag :moderator
          subject.tag :female
        }.should_not raise_error
      end

      it 'with a non-Symbol, non-String object' do
        bad_objects = [123, Object.new, 888.88, nil, true, false, StringIO.new]
        bad_objects.each do |bad_object|
          lambda {
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
      subject.tags.should be == [:moderator, :male]
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

    describe "#write_command" do
      let(:command) { Punchblock::Command::Answer.new }

      it "should write the command to the Punchblock connection" do
        subject.wrapped_object.should_receive(:client).once.and_return mock_client
        mock_client.should_receive(:execute_command).once.with(Punchblock::Command::Answer.new(target_call_id: call_id, domain: domain)).and_return true
        subject.write_command command
      end

      describe "with a hungup call" do
        before do
          subject.wrapped_object.should_receive(:active?).and_return(false)
        end

        it "should raise a Hangup exception" do
          lambda { subject.write_command command }.should raise_error(Call::Hangup)
        end

        describe "if the command is a Hangup" do
          let(:command) { Punchblock::Command::Hangup.new }

          it "should not raise a Hangup exception" do
            lambda { subject.write_command command }.should_not raise_error
          end
        end
      end
    end

    describe '#write_and_await_response' do
      let(:message) { Punchblock::Command::Accept.new }
      let(:response) { :foo }

      before do
        message.should_receive(:execute!).and_return true
        message.response = response
      end

      it "writes a command to the call" do
        subject.wrapped_object.should_receive(:write_command).once.with(message)
        subject.write_and_await_response message
      end

      it "removes the command from the registry after execution" do
        subject.write_and_await_response message
        subject.commands.should be_empty
      end

      it "blocks until a response is received" do
        slow_command = Punchblock::Command::Dial.new
        slow_command.request!
        Thread.new do
          sleep 0.5
          slow_command.response = response
        end
        starting_time = Time.now
        subject.write_and_await_response slow_command
        (Time.now - starting_time).should >= 0.5
      end

      context "while waiting for a response" do
        let(:slow_command) { Punchblock::Command::Dial.new }

        before { slow_command.request! }

        it "does not block the whole actor while waiting for a response" do
          fut = subject.future.write_and_await_response slow_command
          subject.id.should == call_id
          slow_command.response = response
          fut.value
        end

        it "adds the command to the registry" do
          subject.future.write_and_await_response slow_command
          sleep 0.2
          subject.commands.should_not be_empty
          subject.commands.first.should be slow_command
        end
      end

      describe "with a successful response" do
        it "returns the executed command" do
          subject.write_and_await_response(message).should be message
        end
      end

      describe "with an error response" do
        let(:new_exception) { Punchblock::ProtocolError }
        let(:response) { new_exception.new }

        it "raises the error" do
          Events.should_receive(:trigger).never
          lambda { subject.write_and_await_response message }.should raise_error new_exception
        end

        context "where the name is :item_not_found" do
          let(:response) { new_exception.new.setup :item_not_found }

          it "should raise a Hangup exception" do
            Events.should_receive(:trigger).never
            lambda { subject.write_and_await_response message }.should raise_error Call::Hangup
          end
        end
      end

      describe "when the response times out" do
        before do
          message.target_call_id = call_id
          message.domain = domain
          message.should_receive(:response).and_raise Timeout::Error
        end

        it "should raise the error in the caller but not crash the actor" do
          lambda { subject.write_and_await_response message }.should raise_error Call::CommandTimeout, message.to_s
          sleep 0.5
          subject.should be_alive
        end
      end
    end

    describe "#send_message" do
      it "should send a message through the Punchblock connection using the call ID and domain" do
        subject.wrapped_object.should_receive(:client).once.and_return mock_client
        mock_client.should_receive(:send_message).once.with(subject.id, subject.domain, "Hello World!", {})
        subject.send_message "Hello World!"
      end

      it "should send a message with the given subject" do
        subject.wrapped_object.should_receive(:client).once.and_return mock_client
        mock_client.should_receive(:send_message).once.with(subject.id, subject.domain, nil, :subject => "Important Message")
        subject.send_message nil, :subject => "Important Message"
      end
    end

    describe "basic control commands" do
      def expect_message_waiting_for_response(message = nil, fail = false, &block)
        expectation = subject.wrapped_object.should_receive(:write_and_await_response, &block).once
        expectation = expectation.with message if message
        if fail
          expectation.and_raise fail
        else
          expectation.and_return message
        end
      end

      describe '#accept' do
        describe "with no headers" do
          it 'should send an Accept message' do
            expect_message_waiting_for_response Punchblock::Command::Accept.new
            subject.accept
          end
        end

        describe "with headers set" do
          it 'should send an Accept message with the correct headers' do
            headers = {:foo => 'bar'}
            expect_message_waiting_for_response Punchblock::Command::Accept.new(:headers => headers)
            subject.accept headers
          end
        end

        describe "a second time" do
          it "should only send one Accept message" do
            expect_message_waiting_for_response Punchblock::Command::Accept.new
            subject.accept
            subject.accept
          end
        end
      end

      describe '#answer' do
        describe "with no headers" do
          it 'should send an Answer message' do
            expect_message_waiting_for_response Punchblock::Command::Answer.new
            subject.answer
          end
        end

        describe "with headers set" do
          it 'should send an Answer message with the correct headers' do
            headers = {:foo => 'bar'}
            expect_message_waiting_for_response Punchblock::Command::Answer.new(:headers => headers)
            subject.answer headers
          end
        end
      end

      describe '#reject' do
        describe "with a reason given" do
          it 'should send a Reject message with the correct reason' do
            expect_message_waiting_for_response Punchblock::Command::Reject.new(:reason => :decline)
            subject.reject :decline
          end
        end

        describe "with no reason given" do
          it 'should send a Reject message with the reason busy' do
            expect_message_waiting_for_response Punchblock::Command::Reject.new(:reason => :busy)
            subject.reject
          end
        end

        describe "with no headers" do
          it 'should send a Reject message' do
            expect_message_waiting_for_response do |c|
              c.is_a?(Punchblock::Command::Reject) && c.headers == {}
            end
            subject.reject
          end
        end

        describe "with headers set" do
          it 'should send a Hangup message with the correct headers' do
            headers = {:foo => 'bar'}
            expect_message_waiting_for_response do |c|
              c.is_a?(Punchblock::Command::Reject) && c.headers == headers
            end
            subject.reject nil, headers
          end
        end

        it "should immediately fire the :call_rejected event giving the call and the reason" do
          expect_message_waiting_for_response kind_of(Punchblock::Command::Reject)
          Adhearsion::Events.should_receive(:trigger_immediately).once.with(:call_rejected, :call => subject, :reason => :decline)
          subject.reject :decline
        end
      end

      describe '#redirect' do
        describe "with a target given" do
          it 'should send a Redirect message with the correct target' do
            expect_message_waiting_for_response Punchblock::Command::Redirect.new(to: 'sip:foo@bar.com')
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
              c.is_a?(Punchblock::Command::Redirect) && c.headers == {}
            end
            subject.redirect 'sip:foo@bar.com'
          end
        end

        describe "with headers set" do
          it 'should send a Redirect message with the correct headers' do
            headers = {:foo => 'bar'}
            expect_message_waiting_for_response do |c|
              c.is_a?(Punchblock::Command::Redirect) && c.headers == headers
            end
            subject.redirect 'sip:foo@bar.com', headers
          end
        end
      end

      describe "#hangup" do
        describe "if the call is not active" do
          before do
            subject.wrapped_object.should_receive(:active?).and_return false
          end

          it "should do nothing and return false" do
            subject.should_receive(:write_and_await_response).never
            subject.hangup.should be false
          end
        end

        describe "if the call is active" do
          it "should mark the call inactive" do
            expect_message_waiting_for_response Punchblock::Command::Hangup.new
            subject.hangup
            subject.should_not be_active
          end

          describe "with no headers" do
            it 'should send a Hangup message' do
              expect_message_waiting_for_response Punchblock::Command::Hangup.new
              subject.hangup
            end
          end

          describe "with headers set" do
            it 'should send a Hangup message with the correct headers' do
              headers = {:foo => 'bar'}
              expect_message_waiting_for_response Punchblock::Command::Hangup.new(:headers => headers)
              subject.hangup headers
            end
          end
        end
      end

      describe "#join" do
        def expect_join_with_options(options = {})
          Punchblock::Command::Join.new(options).tap do |join|
            expect_message_waiting_for_response join
          end
        end

        context "with a call" do
          let(:call_id) { rand.to_s }
          let(:domain)  { 'rayo.net' }
          let(:uri)     { "footransport:#{call_id}@#{domain}" }
          let(:target)  { described_class.new }

          before { target.wrapped_object.stub uri: uri }

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
            result[:command].should be_a Punchblock::Command::Join
            result[:command].call_uri.should eql(uri)
            result[:command].media.should eql(:bridge)
            result[:command].direction.should eql(:recv)
          end

          it "should return something that can be blocked on until the join is complete" do
            expect_join_with_options :call_id => uri, :media => :bridge, :direction => :recv
            result = subject.join target, :media => :bridge, :direction => :recv

            result[:joined_condition].wait(0.5).should be_false

            subject << Punchblock::Event::Joined.new(call_uri: uri)
            result[:joined_condition].wait(0.5).should be_true
          end

          it "should return something that can be blocked on until the entities are unjoined" do
            expect_join_with_options :call_id => uri, :media => :bridge, :direction => :recv
            result = subject.join target, :media => :bridge, :direction => :recv

            result[:unjoined_condition].wait(0.5).should be_false

            subject << Punchblock::Event::Joined.new(call_uri: uri)
            result[:unjoined_condition].wait(0.5).should be_false

            subject << Punchblock::Event::Unjoined.new(call_uri: uri)
            result[:unjoined_condition].wait(0.5).should be_true
          end

          it "should unblock all conditions on call end if no joined/unjoined events are received" do
            expect_join_with_options :call_id => uri, :media => :bridge, :direction => :recv
            result = subject.join target, :media => :bridge, :direction => :recv

            result[:joined_condition].wait(0.5).should be_false
            result[:unjoined_condition].wait(0.5).should be_false

            subject << Punchblock::Event::End.new
            result[:joined_condition].wait(0.5).should be_true
            result[:unjoined_condition].wait(0.5).should be_true
          end

          it "should not error on call end when joined/unjoined events are received correctly" do
            expect_join_with_options :call_id => uri, :media => :bridge, :direction => :recv
            result = subject.join target, :media => :bridge, :direction => :recv

            subject << Punchblock::Event::Joined.new(call_uri: uri)
            subject << Punchblock::Event::Unjoined.new(call_uri: uri)

            subject << Punchblock::Event::End.new
          end

          it "should not error if multiple joined events are received for the same join" do
            expect_join_with_options :call_id => uri, :media => :bridge, :direction => :recv
            result = subject.join target, :media => :bridge, :direction => :recv

            subject << Punchblock::Event::Joined.new(call_uri: uri)
            subject << Punchblock::Event::Joined.new(call_uri: uri)

            subject.should be_alive
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
            result[:command].should be_a Punchblock::Command::Join
            result[:command].call_uri.should eql(uri)
            result[:command].media.should eql(:bridge)
            result[:command].direction.should eql(:recv)
          end

          it "should return something that can be blocked on until the join is complete" do
            expect_join_with_options :call_id => uri, :media => :bridge, :direction => :recv
            result = subject.join target, :media => :bridge, :direction => :recv

            result[:joined_condition].wait(0.5).should be_false

            subject << Punchblock::Event::Joined.new(call_uri: uri)
            result[:joined_condition].wait(0.5).should be_true
          end

          it "should return something that can be blocked on until the entities are unjoined" do
            expect_join_with_options :call_id => uri, :media => :bridge, :direction => :recv
            result = subject.join target, :media => :bridge, :direction => :recv

            result[:unjoined_condition].wait(0.5).should be_false

            subject << Punchblock::Event::Joined.new(call_uri: uri)
            result[:unjoined_condition].wait(0.5).should be_false

            subject << Punchblock::Event::Unjoined.new(call_uri: uri)
            result[:unjoined_condition].wait(0.5).should be_true
          end

          it "should unblock all conditions on call end if no joined/unjoined events are received" do
            expect_join_with_options :call_id => uri, :media => :bridge, :direction => :recv
            result = subject.join target, :media => :bridge, :direction => :recv

            result[:joined_condition].wait(0.5).should be_false
            result[:unjoined_condition].wait(0.5).should be_false

            subject << Punchblock::Event::End.new
            result[:joined_condition].wait(0.5).should be_true
            result[:unjoined_condition].wait(0.5).should be_true
          end

          it "should not error on call end when joined/unjoined events are received correctly" do
            expect_join_with_options :call_id => uri, :media => :bridge, :direction => :recv
            result = subject.join target, :media => :bridge, :direction => :recv

            subject << Punchblock::Event::Joined.new(call_uri: uri)
            subject << Punchblock::Event::Unjoined.new(call_uri: uri)

            subject << Punchblock::Event::End.new
          end

          it "should not error if multiple joined events are received for the same join" do
            expect_join_with_options :call_id => uri, :media => :bridge, :direction => :recv
            result = subject.join target, :media => :bridge, :direction => :recv

            subject << Punchblock::Event::Joined.new(call_uri: uri)
            subject << Punchblock::Event::Joined.new(call_uri: uri)

            subject.should be_alive
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
            result[:command].should be_a Punchblock::Command::Join
            result[:command].call_uri.should eql(uri)
            result[:command].media.should eql(:bridge)
            result[:command].direction.should eql(:recv)
          end

          it "should return something that can be blocked on until the join is complete" do
            expect_join_with_options :call_id => uri, :media => :bridge, :direction => :recv
            result = subject.join target.merge({:media => :bridge, :direction => :recv})

            result[:joined_condition].wait(0.5).should be_false

            subject << Punchblock::Event::Joined.new(call_uri: uri)
            result[:joined_condition].wait(0.5).should be_true
          end

          it "should return something that can be blocked on until the entities are unjoined" do
            expect_join_with_options :call_id => uri, :media => :bridge, :direction => :recv
            result = subject.join target.merge({:media => :bridge, :direction => :recv})

            result[:unjoined_condition].wait(0.5).should be_false

            subject << Punchblock::Event::Joined.new(call_uri: uri)
            result[:unjoined_condition].wait(0.5).should be_false

            subject << Punchblock::Event::Unjoined.new(call_uri: uri)
            result[:unjoined_condition].wait(0.5).should be_true
          end

          it "should unblock all conditions on call end if no joined/unjoined events are received" do
            expect_join_with_options :call_id => uri, :media => :bridge, :direction => :recv
            result = subject.join target.merge({:media => :bridge, :direction => :recv})

            result[:joined_condition].wait(0.5).should be_false
            result[:unjoined_condition].wait(0.5).should be_false

            subject << Punchblock::Event::End.new
            result[:joined_condition].wait(0.5).should be_true
            result[:unjoined_condition].wait(0.5).should be_true
          end

          it "should not error on call end when joined/unjoined events are received correctly" do
            expect_join_with_options :call_id => uri, :media => :bridge, :direction => :recv
            result = subject.join target.merge({:media => :bridge, :direction => :recv})

            subject << Punchblock::Event::Joined.new(call_uri: uri)
            subject << Punchblock::Event::Unjoined.new(call_uri: uri)

            subject << Punchblock::Event::End.new
          end

          it "should not error if multiple joined events are received for the same join" do
            expect_join_with_options :call_id => uri, :media => :bridge, :direction => :recv
            result = subject.join target.merge({:media => :bridge, :direction => :recv})

            subject << Punchblock::Event::Joined.new(call_uri: uri)
            subject << Punchblock::Event::Joined.new(call_uri: uri)

            subject.should be_alive
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
            result[:command].should be_a Punchblock::Command::Join
            result[:command].mixer_name.should eql(mixer_name)
            result[:command].media.should eql(:bridge)
            result[:command].direction.should eql(:recv)
          end

          it "should return something that can be blocked on until the join is complete" do
            expect_join_with_options :mixer_name => mixer_name, :media => :bridge, :direction => :recv
            result = subject.join target.merge({:media => :bridge, :direction => :recv})

            result[:joined_condition].wait(0.5).should be_false

            subject << Punchblock::Event::Joined.new(mixer_name: mixer_name)
            result[:joined_condition].wait(0.5).should be_true
          end

          it "should return something that can be blocked on until the entities are unjoined" do
            expect_join_with_options :mixer_name => mixer_name, :media => :bridge, :direction => :recv
            result = subject.join target.merge({:media => :bridge, :direction => :recv})

            result[:unjoined_condition].wait(0.5).should be_false

            subject << Punchblock::Event::Joined.new(mixer_name: mixer_name)
            result[:unjoined_condition].wait(0.5).should be_false

            subject << Punchblock::Event::Unjoined.new(mixer_name: mixer_name)
            result[:unjoined_condition].wait(0.5).should be_true
          end

          it "should unblock all conditions on call end if no joined/unjoined events are received" do
            expect_join_with_options :mixer_name => mixer_name, :media => :bridge, :direction => :recv
            result = subject.join target.merge({:media => :bridge, :direction => :recv})

            result[:joined_condition].wait(0.5).should be_false
            result[:unjoined_condition].wait(0.5).should be_false

            subject << Punchblock::Event::End.new
            result[:joined_condition].wait(0.5).should be_true
            result[:unjoined_condition].wait(0.5).should be_true
          end

          it "should not error on call end when joined/unjoined events are received correctly" do
            expect_join_with_options :mixer_name => mixer_name, :media => :bridge, :direction => :recv
            result = subject.join target.merge({:media => :bridge, :direction => :recv})

            subject << Punchblock::Event::Joined.new(mixer_name: mixer_name)
            subject << Punchblock::Event::Unjoined.new(mixer_name: mixer_name)

            subject << Punchblock::Event::End.new
          end

          it "should not error if multiple joined events are received for the same join" do
            expect_join_with_options :mixer_name => mixer_name, :media => :bridge, :direction => :recv
            result = subject.join target.merge({:media => :bridge, :direction => :recv})

            subject << Punchblock::Event::Joined.new(mixer_name: mixer_name)
            subject << Punchblock::Event::Joined.new(mixer_name: mixer_name)

            subject.should be_alive
          end
        end

        context "with a call ID and a mixer name as hash keys" do
          let(:call_id)     { rand.to_s }
          let(:mixer_name)  { rand.to_s }
          let(:target)      { { :call_uri => call_id, :mixer_name => mixer_name } }

          it "should raise an ArgumentError" do
            lambda { subject.join target }.should raise_error ArgumentError, /call URI and mixer name/
          end
        end
      end

      describe "#unjoin" do
        def expect_unjoin_with_options(options = {})
          Punchblock::Command::Unjoin.new(options).tap do |unjoin|
            expect_message_waiting_for_response unjoin
          end
        end

        context "with a call" do
          let(:call_id) { rand.to_s }
          let(:domain)  { 'rayo.net' }
          let(:uri)     { "footransport:#{call_id}@#{domain}" }
          let(:target)  { described_class.new }

          before { target.wrapped_object.stub uri: uri }

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
            lambda { subject.unjoin target }.should raise_error ArgumentError, /call URI and mixer name/
          end
        end
      end

      describe "#mute" do
        it 'should send a Mute message' do
          expect_message_waiting_for_response Punchblock::Command::Mute.new
          subject.mute
        end
      end

      describe "#unmute" do
        it 'should send a Mute message' do
          expect_message_waiting_for_response Punchblock::Command::Unmute.new
          subject.unmute
        end
      end

      describe "#execute_controller" do
        let(:latch)           { CountDownLatch.new 1 }
        let(:mock_controller) { CallController.new(subject) }

        before do
          subject.wrapped_object.stub :write_and_await_response => true
        end

        it "should call #bg_exec on the controller instance" do
          mock_controller.should_receive(:exec).once
          subject.execute_controller mock_controller, lambda { |call| latch.countdown! }
          latch.wait(3).should be_true
        end

        it "should use the passed block as a controller if none is specified" do
          mock_controller.should_receive(:exec).once
          CallController.should_receive(:new).once.and_return mock_controller
          subject.execute_controller nil, lambda { |call| latch.countdown! } do
            foo
          end
          latch.wait(3).should be_true
        end

        it "should raise ArgumentError if both a controller and a block are passed" do
          lambda { subject.execute_controller(mock_controller) { foo } }.should raise_error(ArgumentError)
        end

        it "should pass the exception to the events system" do
          latch = CountDownLatch.new 1
          Adhearsion::Events.exception do |e, l|
            e.should be_a RuntimeError
            l.should be subject.logger
            latch.countdown!
          end
          subject.execute_controller BrokenController.new(subject), lambda { |call| latch.countdown! }
          latch.wait(3).should be true
          Adhearsion::Events.clear_handlers :exception
        end

        it "should execute a callback after the controller executes" do
          foo = nil
          subject.execute_controller mock_controller, lambda { |call| foo = call; latch.countdown! }
          latch.wait(3).should be_true
          foo.should be subject
        end
      end

      describe "#register_controller" do
        it "should add the controller to a list on the call" do
          subject.register_controller :foo
          subject.controllers.should include :foo
        end
      end

      context "with two controllers registered" do
        let(:controller1) { double 'CallController1' }
        let(:controller2) { double 'CallController2' }

        before { subject.controllers << controller1 << controller2 }

        describe "#pause_controllers" do
          it "should pause each of the registered controllers" do
            controller1.should_receive(:pause!).once
            controller2.should_receive(:pause!).once

            subject.pause_controllers
          end
        end

        describe "#resume_controllers" do
          it "should resume each of the registered controllers" do
            controller1.should_receive(:resume!).once
            controller2.should_receive(:resume!).once

            subject.resume_controllers
          end
        end
      end

      describe "after termination" do
        it "should delete its logger" do
          logger = subject.logger
          subject.terminate
          ::Logging::Repository.instance[logger.name].should be_nil
        end
      end
    end

    describe Call::CommandRegistry do
      subject { Call::CommandRegistry.new }

      it { should be_empty }

      describe "#<<" do
        it "should add a command to the registry" do
          subject << :foo
          subject.should_not be_empty
        end
      end

      describe "#delete" do
        it "should remove a command from the registry" do
          subject << :foo
          subject.should_not be_empty
          subject.delete :foo
          subject.should be_empty
        end
      end

      describe "#terminate" do
        let :commands do
          [
            Punchblock::Command::Answer.new,
            Punchblock::Command::Answer.new
          ]
        end

        it "should set each command's response to an instance of Adhearsion::Hangup if it doesn't already have a response" do
          finished_command = Punchblock::Command::Answer.new
          finished_command.request!
          finished_command.response = :foo
          subject << finished_command
          commands.each do |command|
            command.request!
            subject << command
          end
          subject.terminate
          commands.each do |command|
            command.response.should be_a Call::Hangup
          end
          finished_command.response.should be == :foo
        end
      end
    end
  end
end
