require 'spec_helper'

class FinancialWizard < Adhearsion::CallController
end

module Adhearsion
  describe CallController do
    include CallControllerTestHelpers

    let(:call) { Adhearsion::Call.new mock_offer(nil, :x_foo => 'bar') }

    its(:call)      { should be call }
    its(:metadata)  { should == {:doo => :dah} }

    describe "setting meta-data" do
      it "should preserve data correctly" do
        subject[:foo].should be nil
        subject[:foo] = 7
        subject[:foo].should == 7
        subject[:bar] = 10
        subject[:bar].should == 10
        subject[:foo].should == 7
      end
    end

    its(:logger)    { should be call.logger }
    its(:variables) { should be call.variables }

    describe "execution on a call" do
      before do
        flexmock subject, :execute_component_and_await_completion => nil
        flexmock call.wrapped_object, :write_and_await_response => nil
      end

      it "catches Hangup exceptions and logs the hangup" do
        subject.should_receive(:run).once.and_raise(Hangup).ordered
        flexmock(subject.logger).should_receive(:info).once.with(/Call was hung up/).ordered
        subject.execute!
      end

      it "catches standard errors, triggering an exception event" do
        subject.should_receive(:run).once.and_raise(StandardError).ordered
        flexmock(Events).should_receive(:trigger).once.with(:exception, StandardError).ordered
        subject.execute!
      end

      context "when a block is specified" do
        let :block do
          Proc.new { foo value }
        end

        its(:block) { should be block }

        it "should execute the block in the context of the controller" do
          flexmock subject, :value => :bar
          subject.should_receive(:foo).once.with(:bar)
          subject.run
        end
      end
    end

    class SecondController < CallController
      def run
        md_check metadata
        answer
      end

      def md_check(md)
      end
    end

    class SecondControllerWithRemoteHangup < SecondController
      def run
        super
        simulate_remote_hangup
      end

      def simulate_remote_hangup
        raise Hangup
      end
    end

    describe "#invoke" do
      class InvokeController < CallController
        def run
          before
          invoke second_controller, :foo => 'bar'
          after
        end

        def before
        end

        def after
        end

        def second_controller
          metadata[:second_controller] || SecondController
        end
      end

      subject { InvokeController.new call }

      before do
        flexmock subject, :execute_component_and_await_completion => nil
        flexmock call.wrapped_object, :write_and_await_response => nil
        flexmock(Events).should_receive(:trigger).with(:exception, Exception).never
      end

      it "should invoke another controller before returning to the current controller" do
        subject.should_receive(:before).once.ordered
        call.should_receive(:answer).once.ordered
        subject.should_receive(:after).once.ordered

        subject.execute!
      end

      it "should invoke the new controller with metadata" do
        flexmock(SecondController).new_instances.should_receive(:md_check).once.with :foo => 'bar'
        subject.execute!
      end

      it "should allow the outer controller to cease execution and handle remote hangups" do
        subject[:second_controller] = SecondControllerWithRemoteHangup

        subject.should_receive(:before).once.ordered
        call.should_receive(:answer).once.ordered
        subject.should_receive(:after).never.ordered

        subject.execute!
      end
    end

    describe "#pass" do
      class PassController < CallController
        after_call :foobar

        def run
          before
          pass SecondController, :foo => 'bar'
          after
        end

        def before
        end

        def after
        end

        def foobar
        end
      end

      subject { PassController.new call }

      before do
        flexmock(call.wrapped_object).should_receive(:write_and_await_response).and_return nil
        flexmock subject, :execute_component_and_await_completion => nil
        flexmock(SecondController).new_instances.should_receive(:md_check).once.with :foo => 'bar'
        flexmock(Events).should_receive(:trigger).with(:exception, Exception).never
      end

      let(:latch) { CountDownLatch.new 1 }

      it "should cease execution of the current controller, and instruct the call to execute another" do
        subject.should_receive(:before).once.ordered
        call.should_receive(:answer).once.ordered
        subject.should_receive(:after).never.ordered
        call.wrapped_object.should_receive(:hangup).once.ordered

        call.execute_controller subject, latch
        latch.wait(1).should be_true
      end

      it "should execute after_call callbacks before passing control" do
        subject.should_receive(:before).once.ordered
        subject.should_receive(:foobar).once.ordered
        call.should_receive(:answer).once.ordered

        CallController.exec subject
      end
    end

    describe '#write_and_await_response' do
      let(:message) { Punchblock::Command::Accept.new }

      it "delegates to the call" do
        flexmock(subject.call).should_receive(:write_and_await_response).once.with(message, 20)
        subject.write_and_await_response message, 20
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

    describe '#answer' do
      it "should delegate to the call" do
        flexmock(call).should_receive(:answer).once.with(:foo)
        subject.answer :foo
      end
    end

    describe '#reject' do
      it "should delegate to the call" do
        flexmock(call).should_receive(:reject).once.with(:foo, :bar)
        subject.reject :foo, :bar
      end
    end

    describe '#hangup' do
      it "should delegate to the call" do
        flexmock(call).should_receive(:hangup).once.with(:foo)
        subject.hangup :foo
      end
    end

    describe '#mute' do
      it 'should delegate to the call' do
        flexmock(call).should_receive(:mute).once
        subject.mute
      end
    end

    describe '#unmute' do
      it 'should delegate to the call' do
        flexmock(call).should_receive(:unmute).once
        subject.unmute
      end
    end

    describe '#join' do
      it 'should delegate to the call' do
        flexmock(call).should_receive(:join).once.with(:foo)
        subject.join :foo
      end
    end
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
    hangup unless metadata[:skip_hangup]
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
    flexmock call.wrapped_object, :write_and_await_response => nil
  end

  it "should execute the before_call callbacks before processing the call" do
    subject.should_receive(:setup_models).twice.ordered
    subject.should_receive(:join_to_conference).once.ordered
    subject.execute!
  end

  it "should execute the after_call callbacks after the call is hung up" do
    subject.should_receive(:join_to_conference).once.ordered
    subject.should_receive(:clean_up_models).twice.ordered
    subject.should_receive(:foobar).once.ordered
    subject.execute!
  end

  it "should capture errors in callbacks" do
    subject.should_receive(:setup_models).and_raise StandardError
    subject.should_receive(:clean_up_models).and_raise StandardError
    flexmock(Adhearsion::Events).should_receive(:trigger).times(4).with :exception, StandardError
    subject.execute!
  end

  describe "when the controller finishes without a hangup" do
    it "should execute the after_call callbacks" do
      subject[:skip_hangup] = true
      subject.should_receive(:join_to_conference).once.ordered
      subject.should_receive(:foobar).once.ordered
      subject.should_receive(:clean_up_models).twice.ordered
      subject.execute!
    end
  end

  describe "providing hooks to include call functionality" do
    let(:call) { Adhearsion::Call.new mock_offer(nil, :x_foo => 'bar') }

    it "should allow mixing in a module globally on all CallController classes" do
      Adhearsion::CallController.mixin TestBiscuit
      Adhearsion::CallController.new(call).should respond_to :throwadogabone
    end

    it "should allow mixing in a module on a single CallController class" do
      FinancialWizard.mixin MarmaladeIsBetterThanJam
      FinancialWizard.new(call).should respond_to :sobittersweet
      Adhearsion::CallController.new(call).should_not respond_to :sobittersweet
    end
  end
end
