# encoding: utf-8

require 'spec_helper'

class FinancialWizard < Adhearsion::CallController
end

module Adhearsion
  describe CallController do
    include CallControllerTestHelpers

    let(:call) { Adhearsion::Call.new mock_offer(nil, :x_foo => 'bar') }

    its(:call)      { should be call }
    its(:metadata)  { should be == {:doo => :dah} }

    describe "setting meta-data" do
      it "should preserve data correctly" do
        subject[:foo].should be nil
        subject[:foo] = 7
        subject[:foo].should be == 7
        subject[:bar] = 10
        subject[:bar].should be == 10
        subject[:foo].should be == 7
      end
    end

    its(:logger)    { should be call.logger }
    its(:variables) { should be call.variables }

    context "when the call is dead" do
      before { call.terminate }

      it "should use an unnamed logger" do
        subject.logger.should be_a ::Logging::Logger
        subject.logger.name.should == "Adhearsion::CallController"
      end
    end

    describe "execution on a call" do
      before do
        subject.stub :execute_component_and_await_completion => nil
        call.wrapped_object.stub :write_and_await_response => nil
      end

      it "catches Hangup exceptions and logs the hangup" do
        subject.should_receive(:run).once.ordered.and_raise(Call::Hangup)
        subject.logger.should_receive(:info).once.with(/Call was hung up/).ordered
        subject.execute!
      end

      it "catches standard errors, triggering an exception event" do
        subject.should_receive(:run).once.ordered.and_raise(StandardError)
        latch = CountDownLatch.new 1
        ex = lo = nil
        Events.exception do |e, l|
          ex, lo = e, l
          latch.countdown!
        end
        subject.execute!
        latch.wait(1).should be true
        ex.should be_a StandardError
        lo.should be subject.logger
      end

      context "when a block is specified" do
        let :block do
          Proc.new { foo value }
        end

        its(:block) { should be block }

        it "should execute the block in the context of the controller" do
          subject.stub :value => :bar
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
        raise Call::Hangup
      end
    end

    describe "#invoke" do
      class InvokeController < CallController
        def run
          before
          metadata[:invoke_result] = invoke second_controller, :foo => 'bar'
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
        subject.stub :execute_component_and_await_completion => nil
        call.wrapped_object.stub :write_and_await_response => nil
        call.stub :register_controller => nil
        Events.should_receive(:trigger).with(:exception, Exception).never
      end

      it "should invoke another controller before returning to the current controller" do
        subject.should_receive(:before).once.ordered
        call.should_receive(:answer).once.ordered
        subject.should_receive(:after).once.ordered

        subject.execute!
      end

      it "should return the outer controller's run method return value" do
        SecondController.any_instance.should_receive(:run).once.and_return(:run_result)
        subject.execute!
        subject.metadata[:invoke_result].should be == :run_result
      end

      it "should invoke the new controller with metadata" do
        SecondController.any_instance.should_receive(:md_check).once.with :foo => 'bar'
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
        call.wrapped_object.stub :write_and_await_response => nil
        call.stub :register_controller => nil
        subject.stub :execute_component_and_await_completion => nil
        SecondController.any_instance.should_receive(:md_check).once.with :foo => 'bar'
        Events.should_receive(:trigger).with(:exception, Exception).never
      end

      it "should cease execution of the current controller, and instruct the call to execute another" do
        subject.should_receive(:before).once.ordered
        call.should_receive(:answer).once.ordered
        subject.should_receive(:after).never.ordered

        subject.exec
      end

      it "should execute after_call callbacks before passing control" do
        subject.should_receive(:before).once.ordered
        subject.should_receive(:foobar).once.ordered
        call.should_receive(:answer).once.ordered

        subject.exec
      end
    end

    describe "#write_and_await_response" do
      let(:message) { Punchblock::Command::Accept.new }

      it "delegates to the call, blocking first until it is allowed to execute" do
        subject.should_receive(:block_until_resumed).once.ordered
        subject.call.should_receive(:write_and_await_response).once.ordered.with(message)
        subject.write_and_await_response message
      end
    end

    [ :answer,
      :reject,
      :mute,
      :unmute].each do |method_name|
      describe "##{method_name}" do
        it "delegates to the call, blocking first until it is allowed to execute" do
          subject.should_receive(:block_until_resumed).once.ordered
          subject.call.should_receive(method_name).once.ordered
          subject.send method_name
        end
      end
    end

    describe "#hangup" do
      it "delegates to the call, blocking first until it is allowed to execute" do
        subject.should_receive(:block_until_resumed).once.ordered
        subject.call.should_receive(:hangup).once.ordered
        lambda { subject.send :hangup }.should raise_error Call::Hangup
      end
    end

    describe "#join" do
      it "delegates to the call, blocking first until it is allowed to execute, and unblocking when an unjoined event is received" do
        subject.should_receive(:block_until_resumed).once.ordered
        subject.call.should_receive(:join).once.with('call1', :foo => :bar).ordered.and_return Punchblock::Command::Join.new(:call_id => 'call1')
        latch = CountDownLatch.new 1
        Thread.new do
          subject.join 'call1', :foo => :bar
          latch.countdown!
        end
        latch.wait(1).should be false
        subject.call << Punchblock::Event::Joined.new(:call_id => 'call1')
        latch.wait(1).should be false
        subject.call << Punchblock::Event::Unjoined.new(:call_id => 'call1')
        latch.wait(1).should be true
      end

      context "with a mixer" do
        it "delegates to the call, blocking first until it is allowed to execute, and unblocking when an unjoined event is received" do
          subject.should_receive(:block_until_resumed).once.ordered
          subject.call.should_receive(:join).once.with({:mixer_name => 'foobar', :foo => :bar}, {}).ordered.and_return Punchblock::Command::Join.new(:mixer_name => 'foobar')
          latch = CountDownLatch.new 1
          Thread.new do
            subject.join :mixer_name => 'foobar', :foo => :bar
            latch.countdown!
          end
          latch.wait(1).should be false
          subject.call << Punchblock::Event::Joined.new(:mixer_name => 'foobar')
          latch.wait(1).should be false
          subject.call << Punchblock::Event::Unjoined.new(:mixer_name => 'foobar')
          latch.wait(1).should be true
        end
      end

      context "with :async => true" do
        it "delegates to the call, blocking first until it is allowed to execute, and unblocking when the joined event is received" do
          subject.should_receive(:block_until_resumed).once.ordered
          subject.call.should_receive(:join).once.with('call1', :foo => :bar).ordered.and_return Punchblock::Command::Join.new(:call_id => 'call1')
          latch = CountDownLatch.new 1
          Thread.new do
            subject.join 'call1', :foo => :bar, :async => true
            latch.countdown!
          end
          latch.wait(1).should be false
          subject.call << Punchblock::Event::Joined.new(:call_id => 'call1')
          latch.wait(1).should be true
        end

        context "with a mixer" do
          it "delegates to the call, blocking first until it is allowed to execute, and unblocking when the joined event is received" do
            subject.should_receive(:block_until_resumed).once.ordered
            subject.call.should_receive(:join).once.with({:mixer_name => 'foobar', :foo => :bar}, {}).ordered.and_return Punchblock::Command::Join.new(:mixer_name => 'foobar')
            latch = CountDownLatch.new 1
            Thread.new do
              subject.join :mixer_name => 'foobar', :foo => :bar, :async => true
              latch.countdown!
            end
            latch.wait(1).should be false
            subject.call << Punchblock::Event::Joined.new(:mixer_name => 'foobar')
            latch.wait(1).should be true
          end
        end
      end
    end

    describe "#block_until_resumed" do
      context "when the controller has not been paused" do
        it "should not block" do
          t1 = Time.now
          subject.block_until_resumed
          t2 = Time.now

          (t2 - t1).should < 0.2
        end
      end

      context "when the controller is paused" do
        before { subject.pause! }

        it "should unblock when the controller is unpaused" do
          t2 = nil
          latch = CountDownLatch.new 1
          t1 = Time.now
          Thread.new do
            subject.block_until_resumed
            t2 = Time.now
            latch.countdown!
          end

          sleep 0.5

          subject.resume!

          latch.wait(1).should be_true

          (t2 - t1).should >= 0.5
        end
      end
    end

    describe "#execute_component_and_await_completion" do
      let(:component) { Punchblock::Component::Output.new }
      let(:response)  { Punchblock::Event::Complete.new }

      before do
        expect_message_of_type_waiting_for_response component
        component.request!
        component.execute!
        component.complete_event = response
      end

      it "writes component to the server and waits on response" do
        subject.execute_component_and_await_completion component
      end

      it "takes a block which is executed after acknowledgement but before waiting on completion" do
        @comp = nil
        subject.execute_component_and_await_completion(component) { |comp| @comp = comp }.should be == component
        @comp.should be == component
      end

      describe "with a successful completion" do
        it "returns the executed component" do
          subject.execute_component_and_await_completion(component).should be component
        end
      end

      describe "with an error response" do
        let(:response) do
          Punchblock::Event::Complete.new :reason => error
        end

        let(:error) do
          Punchblock::Event::Complete::Error.new :details => details
        end

        let(:details) { "Oh noes, it's all borked" }

        it "raises the error" do
          lambda { subject.execute_component_and_await_completion component }.should raise_error(Adhearsion::Error, "#{details}: #{component}")
        end
      end

      it "blocks until the component receives a complete event" do
        slow_component = Punchblock::Component::Output.new
        slow_component.request!
        slow_component.execute!
        Thread.new do
          sleep 0.5
          slow_component.complete_event = response
        end
        starting_time = Time.now
        subject.execute_component_and_await_completion slow_component
        (Time.now - starting_time).should > 0.5
      end
    end

    describe "equality" do
      context "when of the same type, operating on the same call, with the same metadata" do
        let(:other) { CallController.new call, metadata }

        it "should be equal" do
          subject.should == other
        end
      end

      context "when of a different type" do
        let(:other) { Class.new(CallController).new call, metadata }

        it "should not be equal" do
          subject.should_not == other
        end
      end

      context "when operating on a different call" do
        let(:other) { CallController.new Call.new, metadata }

        it "should not be equal" do
          subject.should_not == other
        end
      end

      context "with different metadata" do
        let(:other) { CallController.new call, something: 'else' }

        it "should not be equal" do
          subject.should_not == other
        end
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
    subject.stub :execute_component_and_await_completion => nil
    call.wrapped_object.stub :write_and_await_response => nil
  end

  it "should execute the before_call callbacks before processing the call" do
    subject.should_receive(:setup_models).twice.ordered
    subject.should_receive(:join_to_conference).once.ordered
    subject.execute!
  end

  it "should execute the after_call callbacks after the call is hung up" do
    subject.should_receive(:join_to_conference).once.ordered
    subject.should_receive(:clean_up_models).twice.ordered
    subject.should_receive(:foobar).never
    subject.execute!
  end

  it "should capture errors in callbacks" do
    subject.should_receive(:setup_models).twice.and_raise StandardError
    subject.should_receive(:clean_up_models).twice.and_raise StandardError
    latch = CountDownLatch.new 4
    Adhearsion::Events.exception do |e, l|
      e.should be_a StandardError
      l.should be subject.logger
      latch.countdown!
    end
    subject.execute!
    latch.wait(1).should be true
    Adhearsion::Events.clear_handlers :exception
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
