# encoding: utf-8

require 'spec_helper'

class FinancialWizard < Adhearsion::CallController
end

module Adhearsion
  describe CallController do
    include CallControllerTestHelpers

    let(:call) { Adhearsion::Call.new mock_offer(nil, :x_foo => 'bar') }

    describe '#call' do
      subject { super().call }
      it { is_expected.to be call }
    end

    describe '#metadata' do
      subject { super().metadata }
      it { is_expected.to eq({:doo => :dah}) }
    end

    describe "setting meta-data" do
      it "should preserve data correctly" do
        expect(subject[:foo]).to be nil
        subject[:foo] = 7
        expect(subject[:foo]).to eq(7)
        subject[:bar] = 10
        expect(subject[:bar]).to eq(10)
        expect(subject[:foo]).to eq(7)
      end
    end

    describe '#logger' do
      subject { super().logger }
      it { is_expected.to be call.logger }
    end

    describe '#variables' do
      subject { super().variables }
      it { is_expected.to be call.variables }
    end

    describe "#send_message" do
      it 'should send a message' do
        expect(call).to receive(:send_message).with("Hello World!").once
        subject.send_message "Hello World!"
      end
    end

    context "when the call is dead" do
      before { call.terminate }

      it "should use an unnamed logger" do
        expect(subject.logger).to be_a ::Logging::Logger
        expect(subject.logger.name).to eq("Adhearsion::CallController")
      end
    end

    describe "execution on a call" do
      before do
        allow(subject).to receive_messages :execute_component_and_await_completion => nil
        allow(call.wrapped_object).to receive_messages :write_and_await_response => nil
      end

      it "catches Hangup exceptions and logs the hangup" do
        expect(subject).to receive(:run).once.ordered.and_raise(Call::Hangup)
        subject.exec
      end

      context "when trying to execute a command against a dead call" do
        before do
          expect(subject).to receive(:run).once.ordered.and_raise(Call::ExpiredError)
        end

        it "gracefully terminates " do
          subject.exec
        end
      end

      it "catches standard errors, triggering an exception event" do
        expect(subject).to receive(:run).once.ordered.and_raise(StandardError)
        latch = CountDownLatch.new 1
        ex = lo = nil
        Events.exception do |e, l|
          ex, lo = e, l
          latch.countdown!
        end
        expect { subject.exec }.to raise_error
        expect(latch.wait(1)).to be true
        expect(ex).to be_a StandardError
        expect(lo).to be subject.logger
      end

      context "when a block is specified" do
        let(:value) { :bar }

        let :block do
          Proc.new { foo value }
        end

        describe '#block' do
          subject { super().block }
          it { is_expected.to be block }
        end

        it "should execute the block in the context of the controller" do
          allow(subject).to receive_messages :value => :bar
          expect(subject).to receive(:foo).once.with(:bar)
          subject.run
        end

        it "should make the block's context available" do
          expect(subject).to receive(:foo).once.with(:bar)
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
        allow(subject).to receive_messages :execute_component_and_await_completion => nil
        allow(call.wrapped_object).to receive_messages :write_and_await_response => nil
        allow(call).to receive_messages :register_controller => nil
        expect(Events).to receive(:trigger).with(:exception, Exception).never
      end

      it "should invoke another controller before returning to the current controller" do
        expect(subject).to receive(:before).once.ordered
        expect(call).to receive(:answer).once.ordered
        expect(subject).to receive(:after).once.ordered

        subject.exec
      end

      it "should return the outer controller's run method return value" do
        expect_any_instance_of(SecondController).to receive(:run).once.and_return(:run_result)
        subject.exec
        expect(subject.metadata[:invoke_result]).to eq(:run_result)
      end

      it "should invoke the new controller with metadata" do
        expect_any_instance_of(SecondController).to receive(:md_check).once.with :foo => 'bar'
        subject.exec
      end

      it "should allow the outer controller to cease execution and handle remote hangups" do
        subject[:second_controller] = SecondControllerWithRemoteHangup

        expect(subject).to receive(:before).once.ordered
        expect(call).to receive(:answer).once.ordered
        expect(subject).to receive(:after).never.ordered

        subject.exec
      end
    end

    describe "#pass" do
      let(:pass_controller) do
        Class.new CallController do
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
      end

      subject { pass_controller.new call }

      before do
        allow(call.wrapped_object).to receive_messages :write_and_await_response => nil
        allow(call).to receive_messages :register_controller => nil
        allow(subject).to receive_messages :execute_component_and_await_completion => nil
        expect_any_instance_of(SecondController).to receive(:md_check).once.with :foo => 'bar'
        expect(Events).to receive(:trigger).with(:exception, Exception).never
      end

      it "should cease execution of the current controller, and instruct the call to execute another" do
        expect(subject).to receive(:before).once.ordered
        expect(call).to receive(:answer).once.ordered
        expect(subject).to receive(:after).never.ordered

        subject.exec
      end

      it "should execute after_call callbacks before passing control" do
        expect(subject).to receive(:before).once.ordered
        expect(subject).to receive(:foobar).once.ordered
        expect(call).to receive(:answer).once.ordered

        subject.exec
      end
    end

    describe "#hard_pass" do
      let(:pass_controller) do
        Class.new CallController do
          def run
            hard_pass SecondController, foo: 'bar'
          end
        end
      end

      subject { pass_controller.new call }

      before do
        allow(call.wrapped_object).to receive(:write_and_await_response) do |command|
          command.request!
          command.execute!
        end
        allow(call).to receive_messages register_controller: nil
        expect_any_instance_of(SecondController).to receive(:md_check).once.with :foo => 'bar'
        expect(Events).to receive(:trigger).with(:exception, Exception).never
      end

      it "should cease execution of the current controller, and instruct the call to execute another" do
        expect(call).to receive(:answer).once.ordered

        subject.exec
      end

      context "when components have been executed on the controller" do
        let(:pass_controller) do
          Class.new CallController do
            attr_accessor :output1, :output2

            def prep_output
              @output1 = play! 'file://foo.wav'
              @output2 = play! 'file://bar.wav'
            end

            def run
              hard_pass SecondController, foo: 'bar'
            end
          end
        end

        before { subject.prep_output }

        context "but not yet received a complete event" do
          it "should terminate the components" do
            expect(subject.output1).to receive(:stop!).once
            expect(subject.output2).to receive(:stop!).once

            subject.exec
          end

          context "and some fail to terminate" do
            before { expect(subject.output1).to receive(:stop!).and_raise(Punchblock::Component::InvalidActionError) }

            it "should terminate the others" do
              expect(subject.output2).to receive(:stop!).once
              subject.exec
            end
          end
        end

        context "when some have completed" do
          before { subject.output1.trigger_event_handler Punchblock::Event::Complete.new }

          it "should not terminate the completed components" do
            expect(subject.output1).to receive(:stop!).never
            expect(subject.output2).to receive(:stop!).once

            subject.exec
          end
        end
      end
    end

    describe '#stop_all_components' do
      let(:stop_controller) do
        Class.new CallController do
          attr_accessor :output1, :output2

          def prep_output
            @output1 = play! 'file://foo.wav'
            @output2 = play! 'file://bar.wav'
          end

          def run
            stop_all_components
          end
        end
      end

      subject { stop_controller.new call }

      context "when components have been executed on the controller" do
        before do
          allow(call.wrapped_object).to receive(:write_and_await_response) do |command|
            command.request!
            command.execute!
          end
          allow(call).to receive_messages register_controller: nil
          expect(Events).to receive(:trigger).with(:exception, Exception).never
          subject.prep_output
        end

        context "when they have not yet received a complete event" do
          it "should terminate the components" do
            expect(subject.output1).to receive(:stop!).once
            expect(subject.output2).to receive(:stop!).once

            subject.exec
          end

          context "and some fail to terminate" do
            before { expect(subject.output1).to receive(:stop!).and_raise(Punchblock::Component::InvalidActionError) }

            it "should terminate the others" do
              expect(subject.output2).to receive(:stop!).once
              subject.exec
            end
          end
        end

        context "when some have completed" do
          before { subject.output1.trigger_event_handler Punchblock::Event::Complete.new }

          it "should not terminate the completed components" do
            expect(subject.output1).to receive(:stop!).never
            expect(subject.output2).to receive(:stop!).once

            subject.exec
          end
        end
      end
    end

    describe "#write_and_await_response" do
      let(:message) { Punchblock::Command::Accept.new }

      it "delegates to the call, blocking first until it is allowed to execute" do
        expect(subject).to receive(:block_until_resumed).once.ordered
        expect(subject.call).to receive(:write_and_await_response).once.ordered.with(message)
        subject.write_and_await_response message
      end
    end

    [ :answer,
      :mute,
      :unmute].each do |method_name|
      describe "##{method_name}" do
        it "delegates to the call, blocking first until it is allowed to execute" do
          expect(subject).to receive(:block_until_resumed).once.ordered
          expect(subject.call).to receive(method_name).once.ordered
          subject.send method_name
        end
      end
    end

    [
      :hangup,
      :reject,
      :redirect
    ].each do |method_name|
      describe "##{method_name}" do
        it "delegates to the call, blocking first until it is allowed to execute, and raises Call::Hangup" do
          expect(subject).to receive(:block_until_resumed).once.ordered
          expect(subject.call).to receive(method_name).once.ordered
          expect { subject.send method_name }.to raise_error Call::Hangup
        end
      end
    end

    describe "#join" do
      it "delegates to the call, blocking first until it is allowed to execute, and unblocking when an unjoined event is received" do
        expect(subject).to receive(:block_until_resumed).once.ordered
        expect(call.wrapped_object).to receive(:write_and_await_response).once.ordered.with(Punchblock::Command::Join.new(call_uri: 'call1'))
        latch = CountDownLatch.new 1
        Thread.new do
          subject.join 'call1', :foo => :bar
          latch.countdown!
        end
        expect(latch.wait(1)).to be false
        subject.call << Punchblock::Event::Joined.new(call_uri: 'call1')
        expect(latch.wait(1)).to be false
        subject.call << Punchblock::Event::Unjoined.new(call_uri: 'call1')
        expect(latch.wait(1)).to be true
      end

      context "with a mixer" do
        it "delegates to the call, blocking first until it is allowed to execute, and unblocking when an unjoined event is received" do
          expect(subject).to receive(:block_until_resumed).once.ordered
          expect(call.wrapped_object).to receive(:write_and_await_response).once.ordered.with(Punchblock::Command::Join.new(mixer_name: 'foobar'))
          latch = CountDownLatch.new 1
          Thread.new do
            subject.join :mixer_name => 'foobar', :foo => :bar
            latch.countdown!
          end
          expect(latch.wait(1)).to be false
          subject.call << Punchblock::Event::Joined.new(:mixer_name => 'foobar')
          expect(latch.wait(1)).to be false
          subject.call << Punchblock::Event::Unjoined.new(:mixer_name => 'foobar')
          expect(latch.wait(1)).to be true
        end
      end

      context "with :async => true" do
        it "delegates to the call, blocking first until it is allowed to execute, and unblocking when the joined event is received" do
          expect(subject).to receive(:block_until_resumed).once.ordered
          expect(call.wrapped_object).to receive(:write_and_await_response).once.ordered.with(Punchblock::Command::Join.new(call_uri: 'call1'))
          latch = CountDownLatch.new 1
          Thread.new do
            subject.join 'call1', :foo => :bar, :async => true
            latch.countdown!
          end
          expect(latch.wait(1)).to be false
          subject.call << Punchblock::Event::Joined.new(call_uri: 'call1')
          expect(latch.wait(1)).to be true
        end

        context "with a mixer" do
          it "delegates to the call, blocking first until it is allowed to execute, and unblocking when the joined event is received" do
            expect(subject).to receive(:block_until_resumed).once.ordered
            expect(call.wrapped_object).to receive(:write_and_await_response).once.ordered.with(Punchblock::Command::Join.new(mixer_name: 'foobar'))
            latch = CountDownLatch.new 1
            Thread.new do
              subject.join :mixer_name => 'foobar', :foo => :bar, :async => true
              latch.countdown!
            end
            expect(latch.wait(1)).to be false
            subject.call << Punchblock::Event::Joined.new(:mixer_name => 'foobar')
            expect(latch.wait(1)).to be true
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

          expect(t2 - t1).to be < 0.2
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

          expect(latch.wait(1)).to be_truthy

          expect(t2 - t1).to be >= 0.5
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
        expect(subject.execute_component_and_await_completion(component) { |comp| @comp = comp }).to eq(component)
        expect(@comp).to eq(component)
      end

      describe "with a successful completion" do
        it "returns the executed component" do
          expect(subject.execute_component_and_await_completion(component)).to be component
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
          expect { subject.execute_component_and_await_completion component }.to raise_error(Adhearsion::Error, "#{details}: #{component}")
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
        expect(Time.now - starting_time).to be > 0.5
      end
    end

    describe "equality" do
      context "when of the same type, operating on the same call, with the same metadata" do
        let(:other) { CallController.new call, metadata }

        it "should be equal" do
          expect(subject).to eq(other)
        end
      end

      context "when of a different type" do
        let(:other) { Class.new(CallController).new call, metadata }

        it "should not be equal" do
          expect(subject).not_to eq(other)
        end
      end

      context "when operating on a different call" do
        let(:other) { CallController.new Call.new, metadata }

        it "should not be equal" do
          expect(subject).not_to eq(other)
        end
      end

      context "with different metadata" do
        let(:other) { CallController.new call, something: 'else' }

        it "should not be equal" do
          expect(subject).not_to eq(other)
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

  on_error { apologize_for_failure }
  on_error :apologize_for_failure

  def setup_models
  end

  def clean_up_models
  end

  def apologize_for_failure
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
    allow(subject).to receive_messages :execute_component_and_await_completion => nil
    allow(call.wrapped_object).to receive_messages :write_and_await_response => nil
  end

  it "should execute the before_call callbacks before processing the call" do
    expect(subject).to receive(:setup_models).twice.ordered
    expect(subject).to receive(:join_to_conference).once.ordered
    subject.exec
  end

  it "should execute the after_call callbacks after the call is hung up" do
    expect(subject).to receive(:join_to_conference).once.ordered
    expect(subject).to receive(:clean_up_models).twice.ordered
    expect(subject).to receive(:foobar).never
    subject.exec
  end

  it "should capture errors in callbacks" do
    expect(subject).to receive(:setup_models).twice.and_raise StandardError
    expect(subject).to receive(:clean_up_models).twice.and_raise StandardError
    latch = CountDownLatch.new 4
    Adhearsion::Events.exception do |e, l|
      expect(e).to be_a StandardError
      expect(l).to be subject.logger
      latch.countdown!
    end
    subject.exec
    expect(latch.wait(1)).to be true
    Adhearsion::Events.clear_handlers :exception
  end

  it "should call the requested method when an exception is encountered" do
    expect(subject).to receive(:join_to_conference).once.and_raise StandardError
    expect(subject).to receive(:apologize_for_failure).twice.ordered

    expect { subject.exec }.to raise_error
  end

  describe "when the controller finishes without a hangup" do
    it "should execute the after_call callbacks" do
      subject[:skip_hangup] = true
      expect(subject).to receive(:join_to_conference).once.ordered
      expect(subject).to receive(:foobar).once.ordered
      expect(subject).to receive(:clean_up_models).twice.ordered
      subject.exec
    end
  end

  describe "providing hooks to include call functionality" do
    let(:call) { Adhearsion::Call.new mock_offer(nil, :x_foo => 'bar') }

    it "should allow mixing in a module globally on all CallController classes" do
      Adhearsion::CallController.mixin TestBiscuit
      expect(Adhearsion::CallController.new(call)).to respond_to :throwadogabone
    end

    it "should allow mixing in a module on a single CallController class" do
      FinancialWizard.mixin MarmaladeIsBetterThanJam
      expect(FinancialWizard.new(call)).to respond_to :sobittersweet
      expect(Adhearsion::CallController.new(call)).not_to respond_to :sobittersweet
    end
  end
end
