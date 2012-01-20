require 'spec_helper'

module Adhearsion
  describe Call do
    let(:mock_client) { flexmock('Client').tap &:should_ignore_missing }

    let(:call_id) { rand }
    let(:headers) { nil }
    let(:offer)   { Punchblock::Event::Offer.new :call_id => call_id, :headers => headers }

    subject { Adhearsion::Call.new offer }

    before do
      flexmock(offer).should_receive(:client).and_return(mock_client)
    end

    after do
      Adhearsion.active_calls.clear!
    end

    it { should respond_to :<< }

    its(:end_reason) { should == nil }
    it { should be_active }

    its(:commands) { should be_a Call::CommandRegistry }
    its(:commands) { should be_empty }

    its(:id)      { should == call_id }
    its(:offer)   { should be offer }
    its(:client)  { should be mock_client }

    describe "its variables" do
      context "with an offer with headers" do
        let(:headers)   { {:x_foo => 'bar'} }
        its(:variables) { should == headers }

        context "when receiving an event with headers" do
          let(:event) { Punchblock::Event::End.new :headers => {:x_bar => 'foo'} }

          it "should merge later headers" do
            subject << event
            subject.variables.should == {:x_foo => 'bar', :x_bar => 'foo'}
          end
        end

        context "when sending a command with headers" do
          let(:command) { Punchblock::Command::Accept.new :headers => {:x_bar => 'foo'} }

          it "should merge later headers" do
            subject.write_command command
            subject.variables.should == {:x_foo => 'bar', :x_bar => 'foo'}
          end
        end
      end

      context "with an offer without headers" do
        let(:headers)   { nil }
        its(:variables) { should == {} }
      end

      context "without an offer" do
        let(:offer)     { nil }
        its(:variables) { should == {} }
      end
    end

    describe 'without an offer' do
      it 'should not raise an exception' do
        lambda { Adhearsion::Call.new }.should_not raise_error
      end
    end

    it 'a hungup call removes itself from the active calls' do
      size_before = Adhearsion.active_calls.size

      call = Adhearsion.active_calls.from_offer offer
      Adhearsion.active_calls.size.should > size_before
      call.hangup
      Adhearsion.active_calls.size.should == size_before
    end

    it 'allows the registration of event handlers which are called when messages are delivered' do
      event = flexmock 'Event'
      event.should_receive(:foo?).and_return true
      response = flexmock 'Response'
      response.should_receive(:call).once
      subject.register_event_handler(:foo?) { response.call }
      subject << event
    end

    describe "event handlers" do
      let(:response) { flexmock 'Response' }

      describe "for end events" do
        let :event do
          Punchblock::Event::End.new.tap do |e|
            flexmock e, :reason => :hangup
          end
        end

        it "should trigger any on_end callbacks set" do
          response.should_receive(:call).once.with(event)
          subject.on_end { |event| response.call event }
          subject << event
        end
      end
    end

    describe "#<<" do
      describe "with a Punchblock End" do
        let :end_event do
          Punchblock::Event::End.new.tap do |e|
            flexmock e, :reason => :hangup
          end
        end

        it "should mark the call as ended" do
          flexmock(subject).should_receive(:hangup).once
          subject << end_event
          subject.should_not be_active
        end

        it "should set the end reason" do
          subject << end_event
          subject.end_reason.should == :hangup
        end

        it "should instruct the command registry to terminate" do
          flexmock(subject.commands).should_receive(:terminate).once
          subject << end_event
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
      subject.tags.should == [:moderator, :male]
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
      let(:mock_command) { flexmock('Command') }

      it "should asynchronously write the command to the Punchblock connection" do
        mock_client = flexmock('Client')
        flexmock(subject).should_receive(:client).once.and_return mock_client
        mock_client.should_receive(:execute_command).once.with(mock_command, :call_id => subject.id).and_return true
        subject.write_command mock_command
      end

      describe "with a hungup call" do
        before do
          flexmock(subject).should_receive(:active?).and_return(false)
        end

        it "should raise a Hangup exception" do
          lambda { subject.write_command mock_command }.should raise_error(Hangup)
        end

        describe "if the command is a Hangup" do
          let(:mock_command) { Punchblock::Command::Hangup.new }

          it "should not raise a Hangup exception" do
            lambda { subject.write_command mock_command }.should_not raise_error
          end
        end
      end
    end

    describe '#write_and_await_response' do
      let(:message) { Punchblock::Command::Accept.new }
      let(:response) { :foo }

      before do
        flexmock(message).should_receive(:execute!).and_return true
        message.response = response
      end

      it "writes a command to the call" do
        flexmock(subject).should_receive(:write_command).once.with(message)
        subject.write_and_await_response message
      end

      it "adds the command to the registry" do
        subject.write_and_await_response message
        subject.commands.should_not be_empty
      end

      it "blocks until a response is received" do
        slow_command = Punchblock::Command::Dial.new
        Thread.new do
          sleep 0.5
          slow_command.response = response
        end
        starting_time = Time.now
        subject.write_and_await_response slow_command
        (Time.now - starting_time).should >= 0.5
      end

      describe "with a successful response" do
        it "returns the executed command" do
          subject.write_and_await_response(message).should be message
        end
      end

      describe "with an error response" do
        let(:response) { Exception.new }

        it "raises the error" do
          lambda { subject.write_and_await_response message }.should raise_error Exception
        end
      end
    end

    describe "basic control commands" do
      include FlexMock::ArgumentTypes

      def expect_message_waiting_for_response(message)
        flexmock(subject).should_receive(:write_and_await_response).once.with(message).and_return(message)
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
            expect_message_waiting_for_response on { |c| c.is_a?(Punchblock::Command::Reject) && c.headers_hash == {} }
            subject.reject
          end
        end

        describe "with headers set" do
          it 'should send a Hangup message with the correct headers' do
            headers = {:foo => 'bar'}
            expect_message_waiting_for_response on { |c| c.is_a?(Punchblock::Command::Reject) && c.headers_hash == headers }
            subject.reject nil, headers
          end
        end
      end

      describe "#hangup!" do
        describe "if the call is not active" do
          before do
            flexmock(subject).should_receive(:active?).and_return false
          end

          it "should do nothing and return false" do
            flexmock(subject).should_receive(:write_and_await_response).never
            subject.hangup!.should be false
          end
        end

        describe "if the call is active" do
          it "should mark the call inactive" do
            expect_message_waiting_for_response Punchblock::Command::Hangup.new
            subject.hangup!
            subject.should_not be_active
          end

          describe "with no headers" do
            it 'should send a Hangup message' do
              expect_message_waiting_for_response Punchblock::Command::Hangup.new
              subject.hangup!
            end
          end

          describe "with headers set" do
            it 'should send a Hangup message with the correct headers' do
              headers = {:foo => 'bar'}
              expect_message_waiting_for_response Punchblock::Command::Hangup.new(:headers => headers)
              subject.hangup! headers
            end
          end
        end
      end

      describe "#join" do
        let(:other_call_id) { rand }

        it "should mark the call inactive" do
          expect_message_waiting_for_response Punchblock::Command::Join.new :other_call_id => other_call_id
          subject.join other_call_id
        end
      end

      describe "#execute_controller" do
        let(:latch)           { CountDownLatch.new 1 }
        let(:mock_controller) { flexmock 'CallController' }

        before do
          flexmock subject, :write_and_await_response => true
        end

        it "should call #execute on the controller instance" do
          flexmock(CallController).should_receive(:exec).once.with mock_controller
          subject.execute_controller mock_controller, latch
          latch.wait(3).should be_true
        end

        it "should hangup the call after all controllers have executed" do
          flexmock(CallController).should_receive(:exec).once.with mock_controller
          subject.should_receive(:hangup!).once
          subject.execute_controller mock_controller, latch
          latch.wait(3).should be_true
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
            command.response.should be_a Hangup
          end
          finished_command.response.should == :foo
        end
      end
    end

    describe Call::Registry do
      it "should set a value and retrieve it" do
        Adhearsion::Call::Registry[:test_value] = '123'
        Adhearsion::Call::Registry[:test_value].should == '123'
      end
    end
  end
end
