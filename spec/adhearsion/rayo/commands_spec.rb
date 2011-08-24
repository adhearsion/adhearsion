require 'spec_helper'

module Adhearsion
  module Rayo
    describe Commands do
      include RayoCommandTestHelpers

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
        it 'should send an Accept message' do
          expect_message_waiting_for_response Punchblock::Command::Accept
          mock_execution_environment.accept
        end
      end

      describe '#answer' do
        it 'should send an Answer message' do
          expect_message_waiting_for_response Punchblock::Command::Answer
          mock_execution_environment.answer
        end
      end

      describe '#hangup' do
        it 'should send a Hangup message' do
          expect_message_waiting_for_response Punchblock::Command::Hangup
          mock_execution_environment.hangup
        end
      end
    end
  end
end
