require 'spec_helper'

module Adhearsion
  describe Call do
    subject { Adhearsion::Call.new mock_offer }

    after do
      Adhearsion.active_calls.clear!
    end

    its(:inbox) { should be_a_kind_of Queue }

    it { should respond_to :<< }

    its(:originating_voip_platform) { should == :rayo }

    its(:end_reason) { should == nil }
    it { should be_active }

    it '#id should return the ID from the Offer' do
      offer = mock_offer
      Adhearsion::Call.new(offer).id.should == offer.call_id
    end

    it 'should store the original offer' do
      offer = mock_offer
      Adhearsion::Call.new(offer).offer.should == offer
    end

    it "should store the Punchblock connection from the Offer" do
      offer = mock_offer
      connection = flexmock('Connection')
      offer.should_receive(:connection).once.and_return(connection)
      Adhearsion::Call.new(offer).connection.should == connection
    end

    it 'can create a call and add it via a top-level method on the Adhearsion module' do
      Adhearsion.active_calls.any?.should == false
      call = Adhearsion.receive_call_from mock_offer
      call.should be_a_kind_of(Adhearsion::Call)
      Adhearsion.active_calls.size.should == 1
    end

    it 'a hungup call removes itself from the active calls' do
      size_before = Adhearsion.active_calls.size

      call = Adhearsion.receive_call_from mock_offer
      Adhearsion.active_calls.size.should > size_before
      call.hangup
      Adhearsion.active_calls.size.should == size_before
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
      end
    end

    describe "tagging a call" do
      it 'with a single Symbol' do
        the_following_code {
          subject.tag :moderator
        }.should_not raise_error
      end

      it 'with multiple Symbols' do
        the_following_code {
          subject.tag :moderator
          subject.tag :female
        }.should_not raise_error
      end

      it 'with a non-Symbol, non-String object' do
        bad_objects = [123, Object.new, 888.88, nil, true, false, StringIO.new]
        bad_objects.each do |bad_object|
          the_following_code {
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
        mock_connection = flexmock('Connection')
        flexmock(subject).should_receive(:connection).once.and_return mock_connection
        mock_connection.should_receive(:async_write).once.with(subject.id, mock_command).and_return true
        subject.write_command mock_command
      end

      describe "with a hungup call" do
        before do
          flexmock(subject).should_receive(:active?).and_return(false)
        end

        it "should raise a Hangup exception" do
          lambda { subject.write_command mock_command }.should raise_error(Hangup)
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

      it "blocks until a response is received" do
        slow_command = Punchblock::Command::Dial.new
        Thread.new do
          sleep 0.5
          slow_command.response = response
        end
        starting_time = Time.now
        subject.write_and_await_response slow_command
        (Time.now - starting_time).should > 0.5
      end

      describe "with a successful response" do
        it "returns the executed command" do
          subject.write_and_await_response(message).should be message
        end
      end

      describe "with an error response" do
        let(:response) { Exception.new }

        it "raises the error" do
          lambda { subject.write_and_await_response message }.should raise_error(response)
        end
      end
    end

    describe "basic control commands" do
      include FlexMock::ArgumentTypes

      def expect_message_waiting_for_response(message)
        flexmock(subject).should_receive(:write_and_await_response).once.with(message).and_return(true)
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

          it "should do nothing" do
            flexmock(subject).should_receive(:write_and_await_response).never
            subject.hangup!
          end
        end

        describe "if the call is active" do
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
    end
  end
end
