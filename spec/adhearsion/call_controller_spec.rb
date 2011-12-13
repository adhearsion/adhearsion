require 'spec_helper'

module Adhearsion
  describe CallController do
    include CallControllerTestHelpers

    let(:call) { Adhearsion::Call.new mock_offer(nil, :x_foo => 'bar') }

    its(:call) { should be call }

    it "should add plugin dialplan methods" do
      subject.should respond_to :foo
    end

    it "should add accessor methods for call variables" do
      subject.x_foo == 'bar'
    end

    its(:logger)    { should be call.logger }
    its(:variables) { should be call.variables }

    describe "execution on a call" do
      before do
        flexmock subject, :execute_component_and_await_completion => nil
        flexmock call, :write_and_await_response => nil
      end

      context "when auto-accept is enabled" do
        before do
          Adhearsion.config.platform.automatically_accept_incoming_calls = true
        end

        it "should accept the call" do
          subject.should_receive(:accept).once.ordered
          subject.should_receive(:run).once.ordered
          subject.execute
        end
      end

      context "when auto-accept is disabled" do
        before do
          Adhearsion.config.platform.automatically_accept_incoming_calls = false
        end

        it "should not accept the call" do
          subject.should_receive(:accept).never
          subject.should_receive(:run).once
          subject.execute
        end
      end

      it "catches Hangup exceptions and logs the hangup" do
        subject.should_receive(:run).once.and_raise(Hangup).ordered
        flexmock(subject.logger).should_receive(:info).once.with(/Call was hung up/).ordered
        subject.execute
      end

      it "catches standard errors, triggering an exception event" do
        subject.should_receive(:run).once.and_raise(StandardError).ordered
        flexmock(Events).should_receive(:trigger).once.with(:exception, StandardError).ordered
        subject.execute
      end

      it "hangs up the call" do
        subject.should_receive(:run).once.and_raise(StandardError).ordered
        subject.should_receive(:hangup).once.ordered
        subject.execute
      end
    end

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

class ExampleCallController < Adhearsion::CallController
  before_call { setup_models }
  before_call :setup_models

  after_call { clean_up_models }
  after_call :clean_up_models

  def setup_models
  end

  def clean_up_models
  end

  def run
    join_to_conference
    hangup
    foobar
  end

  def join_to_conference
  end

  def foobar
  end
end

describe ExampleCallController do
  include CallControllerTestHelpers

  before do
    flexmock subject, :execute_component_and_await_completion => nil
    flexmock call, :write_and_await_response => nil
    Adhearsion.config.platform.automatically_accept_incoming_calls = true
  end

  it "should execute the before_call callbacks before accepting the call" do
    subject.should_receive(:setup_models).twice.ordered
    subject.should_receive(:accept).once.ordered
    subject.should_receive(:join_to_conference).once.ordered
    subject.execute
  end

  it "should execute the after_call callbacks after the call is hung up" do
    subject.should_receive(:join_to_conference).once.ordered
    subject.should_receive(:clean_up_models).twice.ordered
    subject.should_receive(:foobar).once.ordered
    subject.execute
  end

  it "should capture errors in callbacks" do
    subject.should_receive(:setup_models).and_raise StandardError
    subject.should_receive(:clean_up_models).and_raise StandardError
    flexmock(Adhearsion::Events).should_receive(:trigger).times(4).with :exception, StandardError
    subject.execute
  end
end
