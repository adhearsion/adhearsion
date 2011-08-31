require 'spec_helper'

module Adhearsion
  module Rayo
    describe Commands do
      include RayoCommandTestHelpers

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

      describe "#execute_component_and_await_completion" do
        let(:component) { Punchblock::Component::Output.new }
        let(:response) { Punchblock::Event::Complete.new }

        before do
          expect_message_waiting_for_response component
          component.complete_event.resource = response
        end

        it "writes component to the server and waits on response" do
          mock_execution_environment.execute_component_and_await_completion component
        end

        it "takes a block which is executed after acknowledgement but before waiting on completion" do
          @comp = nil
          mock_execution_environment.execute_component_and_await_completion(component) { |comp| @comp = comp }.should == component
          @comp.should == component
        end

        describe "with a successful completion" do
          it "returns the executed component" do
            mock_execution_environment.execute_component_and_await_completion(component).should be component
          end
        end

        describe "with an error response" do
          let(:response) do
            Punchblock::Event::Complete.new.tap do |complete|
              complete << error
            end
          end

          let(:error) do |error|
            Punchblock::Event::Complete::Error.new.tap do |error|
              error << details
            end
          end

          let(:details) { "Oh noes, it's all borked" }

          it "raises the error" do
            lambda { mock_execution_environment.execute_component_and_await_completion component }.should raise_error(StandardError, details)
          end
        end

        it "blocks until the component receives a complete event" do
          slow_component = Punchblock::Component::Output.new
          Thread.new do
            sleep 0.5
            slow_component.complete_event.resource = response
          end
          starting_time = Time.now
          mock_execution_environment.execute_component_and_await_completion slow_component
          (Time.now - starting_time).should > 0.5
        end
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
    end
  end
end
