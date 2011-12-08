require 'spec_helper'

module Adhearsion
  describe CallController do
    include CallControllerTestHelpers

    its(:call) { should be call }

    describe '#write_and_await_response' do
      let(:message) { Punchblock::Command::Accept.new }

      it "delegates to the call" do
        flexmock(subject.call).should_receive(:write_and_await_response).once.with(message, nil)
        subject.write_and_await_response message
      end
    end

    describe "#execute_component_and_await_completion" do
      let(:component) { Punchblock::Component::Output.new }
      let(:response)  { Punchblock::Event::Complete.new }

      before do
        expect_message_waiting_for_response component
        component.execute!
        component.complete_event = response
      end

      it "writes component to the server and waits on response" do
        subject.execute_component_and_await_completion component
      end

      it "takes a block which is executed after acknowledgement but before waiting on completion" do
        @comp = nil
        subject.execute_component_and_await_completion(component) { |comp| @comp = comp }.should == component
        @comp.should == component
      end

      describe "with a successful completion" do
        it "returns the executed component" do
          subject.execute_component_and_await_completion(component).should be component
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
          lambda { subject.execute_component_and_await_completion component }.should raise_error(StandardError, details)
        end
      end

      it "blocks until the component receives a complete event" do
        slow_component = Punchblock::Component::Output.new
        Thread.new do
          sleep 0.5
          slow_component.complete_event = response
        end
        starting_time = Time.now
        subject.execute_component_and_await_completion slow_component
        (Time.now - starting_time).should > 0.5
      end
    end

    describe '#accept' do
      it "should delegate to the call" do
        flexmock(subject.call).should_receive(:accept).once.with(:foo)
        subject.accept :foo
      end
    end

    describe '#answer' do
      it "should delegate to the call" do
        flexmock(subject.call).should_receive(:answer).once.with(:foo)
        subject.answer :foo
      end
    end

    describe '#reject' do
      it "should delegate to the call" do
        flexmock(subject.call).should_receive(:reject).once.with(:foo, :bar)
        subject.reject :foo, :bar
      end
    end

    describe '#hangup' do
      it "should delegate to the call" do
        flexmock(subject.call).should_receive(:hangup!).once.with(:foo)
        subject.hangup :foo
      end
    end

    describe '#mute' do
      it 'should send a Mute message' do
        expect_message_waiting_for_response Punchblock::Command::Mute.new
        subject.mute
      end
    end

    describe '#unmute' do
      it 'should send an Unmute message' do
        expect_message_waiting_for_response Punchblock::Command::Unmute.new
        subject.unmute
      end
    end

    it_should_behave_like "output commands"
    it_should_behave_like "input commands"
    it_should_behave_like "conference commands"
    it_should_behave_like "dial commands"
    it_should_behave_like "record commands"
  end
end
