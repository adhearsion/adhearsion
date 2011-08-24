require 'spec_helper'

module Adhearsion
  module Rayo
    describe Commands do
      include RayoCommandTestHelpers
      include FlexMock::ArgumentTypes

      let(:mock_execution_environment) do
        ee = Object.new.tap do |ee|
          ee.metaclass.send :attr_reader, :call
          ee.instance_variable_set :@call, RayoCommandTestHelpers::MockCall.new
          ee.extend Adhearsion::Rayo::Commands
        end
        flexmock(ee)
      end

      before do
        Adhearsion::Configuration.configure { |config| config.enable_punchblock }
      end

      describe '#write' do
        it "writes a command to the call" do
          message = 'oh hai'
          flexmock(mock_execution_environment.call).should_receive(:write_command).once.with(message)
          mock_execution_environment.write message
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
          flexmock(mock_execution_environment).should_receive(:write).once.with(message)
          mock_execution_environment.write_and_await_response message
        end

        it "blocks until a response is received" do
          slow_command = Punchblock::Command::Dial.new
          Thread.new do
            sleep 0.5
            slow_command.response = response
          end
          starting_time = Time.now
          mock_execution_environment.write_and_await_response slow_command
          (Time.now - starting_time).should > 0.5
        end

        describe "with a successful response" do
          it "returns the executed command" do
            mock_execution_environment.write_and_await_response(message).should be message
          end
        end

        describe "with an error response" do
          let(:response) { Exception.new }

          it "raises the error" do
            lambda { mock_execution_environment.write_and_await_response message }.should raise_error(response)
          end
        end
      end

      def expect_message_waiting_for_response(message)
        mock_execution_environment.should_receive(:write_and_await_response).once.with(message).and_return(true)
      end

      describe '#accept' do
        describe "with no headers" do
          it 'should send an Accept message' do
            expect_message_waiting_for_response Punchblock::Command::Accept.new
            mock_execution_environment.accept
          end
        end

        describe "with headers set" do
          it 'should send an Accept message with the correct headers' do
            headers = {:foo => 'bar'}
            expect_message_waiting_for_response Punchblock::Command::Accept.new(:headers => headers)
            mock_execution_environment.accept headers
          end
        end
      end

      describe '#answer' do
        describe "with no headers" do
          it 'should send an Answer message' do
            expect_message_waiting_for_response Punchblock::Command::Answer.new
            mock_execution_environment.answer
          end
        end

        describe "with headers set" do
          it 'should send an Answer message with the correct headers' do
            headers = {:foo => 'bar'}
            expect_message_waiting_for_response Punchblock::Command::Answer.new(:headers => headers)
            mock_execution_environment.answer headers
          end
        end
      end

      describe '#reject' do
        describe "with a reason given" do
          it 'should send a Reject message with the correct reason' do
            expect_message_waiting_for_response Punchblock::Command::Reject.new(:reason => :decline)
            mock_execution_environment.reject :decline
          end
        end

        describe "with no reason given" do
          it 'should send a Reject message with the reason busy' do
            expect_message_waiting_for_response Punchblock::Command::Reject.new(:reason => :busy)
            mock_execution_environment.reject
          end
        end

        describe "with no headers" do
          it 'should send a Reject message' do
            expect_message_waiting_for_response on { |c| c.is_a?(Punchblock::Command::Reject) && c.headers_hash == {} }
            mock_execution_environment.reject
          end
        end

        describe "with headers set" do
          it 'should send a Hangup message with the correct headers' do
            headers = {:foo => 'bar'}
            expect_message_waiting_for_response on { |c| c.is_a?(Punchblock::Command::Reject) && c.headers_hash == headers }
            mock_execution_environment.reject nil, headers
          end
        end
      end

      describe '#hangup' do
        describe "with no headers" do
          it 'should send a Hangup message' do
            expect_message_waiting_for_response Punchblock::Command::Hangup.new
            mock_execution_environment.hangup
          end
        end

        describe "with headers set" do
          it 'should send a Hangup message with the correct headers' do
            headers = {:foo => 'bar'}
            expect_message_waiting_for_response Punchblock::Command::Hangup.new(:headers => headers)
            mock_execution_environment.hangup headers
          end
        end
      end

      describe '#mute' do
        it 'should send a Mute message' do
          expect_message_waiting_for_response Punchblock::Command::Mute.new
          mock_execution_environment.mute
        end
      end

      describe '#unmute' do
        it 'should send an Unmute message' do
          expect_message_waiting_for_response Punchblock::Command::Unmute.new
          mock_execution_environment.unmute
        end
      end

      describe "#execute_component_and_await_completion" do
        let(:component) { Punchblock::Component::Output.new }

        it "writes component to the server and waits on response" do
          expect_message_waiting_for_response component
          mock_execution_environment.execute_component_and_await_completion component
        end

        it "blocks until the component receives a complete event"
      end

      describe "#raw_output" do
        pending
      end

      describe "#raw_input" do
        pending
      end

      describe "#raw_record" do
        pending
      end
    end
  end
end
