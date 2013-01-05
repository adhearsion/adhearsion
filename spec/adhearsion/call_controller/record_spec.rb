# encoding: utf-8

require 'spec_helper'
require 'ruby_speech'

module Adhearsion
  class CallController
    describe Record do
      include CallControllerTestHelpers

      describe Recorder do
        let(:interruptible)     { false }
        let(:async)             { false }
        let(:component_options) { { :start_beep => true } }
        let :options do
          component_options.merge :interruptible => interruptible,
            :async => async
        end

        let(:component) { Punchblock::Component::Record.new component_options }
        let :stopper_grammar do
          RubySpeech::GRXML.draw :mode => 'dtmf', :root => 'inputdigits' do
            rule id: 'inputdigits', scope: 'public' do
              one_of do
                item { '0' }
                item { '1' }
                item { '2' }
                item { '3' }
                item { '4' }
                item { '5' }
                item { '6' }
                item { '7' }
                item { '8' }
                item { '9' }
                item { '#' }
                item { '*' }
              end
            end
          end
        end
        let(:input_component) { Punchblock::Component::Input.new mode: :dtmf, grammar: { :value => stopper_grammar } }

        subject { Recorder.new controller, options }

        its(:record_component) { should == component }

        context "when passing time related options" do
          let :component_options do
            { :max_duration => 5.5, :initial_timeout => 6.5, :final_timeout => 3.2 }
          end

          let :component do
            Punchblock::Component::Record.new :max_duration => 5500,
              :initial_timeout => 6500,
              :final_timeout => 3200
          end

          it "takes seconds but sets milliseconds on the command" do
            subject.record_component.should == component
          end
        end

        describe "#run" do
          context "with :async => false" do
            it "executes the component synchronously" do
              expect_component_execution subject.record_component
              subject.run
            end
          end

          context "with :async => true" do
            let(:async) { true }

            it "executes the component asynchronously" do
              expect_message_waiting_for_response subject.record_component
              subject.run
            end
          end

          context "with :interruptible => false" do
            its(:stopper_component) { should be_nil }

            it "does not use an Input component" do
              controller.should_receive(:execute_component_and_await_completion).once.with(component)
              controller.should_receive(:write_and_await_response).never.with(input_component)
              subject.run
            end
          end

          context "with :interruptible => true" do
            let(:interruptible) { true }

            its(:stopper_component) { should == input_component }

            describe "when the input component completes" do
              let(:complete_event) { Punchblock::Event::Complete.new }

              before do
                subject.stopper_component.request!
                subject.stopper_component.execute!
              end

              it "stops the recording" do
                flexmock(subject.record_component).should_receive(:stop!).once
                subject.stopper_component.trigger_event_handler complete_event
              end
            end

            describe "when the recording completes" do
              it "stops the input component" do
                controller.should_receive(:execute_component_and_await_completion).once.with(component)
                controller.should_receive(:write_and_await_response).once.with(input_component)
                flexmock(subject.stopper_component).should_receive(:stop!).once
                subject.run
              end
            end
          end
        end

        describe "setting completion handlers" do
          let(:complete_event) { Punchblock::Event::Complete.new }

          it "should execute those handlers when recording completes" do
            foo = flexmock 'foo'
            foo.should_receive(:call).once.with Punchblock::Event::Complete
            subject.handle_record_completion { |e| foo.call e }
            subject.record_component.trigger_event_handler complete_event
          end
        end
      end

      describe "#record" do
        let(:max_duration) { 5.5 }
        let(:options) do
          {
            :start_beep => true,
            :max_duration => max_duration
          }
        end
        let(:parsed_options) do
          options.merge(max_duration: max_duration * 1000)
        end
        let(:component) { Punchblock::Component::Record.new parsed_options }
        let(:response)  { Punchblock::Event::Complete.new }

        describe "with :async => true and an :on_complete callback" do
          before do
            component
            flexmock(Punchblock::Component::Record).should_receive(:new).once.with(parsed_options).and_return component
            expect_message_waiting_for_response component
            @rec = Queue.new
            subject.record(options.merge(async: true)) { |rec| @rec.push rec }
            component.request!
            component.execute!
          end

          it "should execute the callback" do
            component.trigger_event_handler response
            Timeout::timeout 5 do
              @rec.pop.should be response
            end
          end
        end

        describe "when the callback raises an exception" do
          before do
            TestException = Class.new StandardError
            component
            flexmock(Punchblock::Component::Record).should_receive(:new).once.with({}).and_return component
          end

          it "should pass the exception to the events system" do
            latch = CountDownLatch.new 1
            Adhearsion::Events.exception do |e, l|
              e.should be_a TestException
              l.should be subject.logger
              latch.countdown!
            end
            expect_component_execution component
            subject.record { |rec| raise TestException }
            component.request!
            component.execute!
            component.trigger_event_handler response
            latch.wait(1).should be true
            Adhearsion::Events.clear_handlers :exception
          end
        end

        describe "with :async => false" do
          before do
            component
            flexmock(Punchblock::Component::Record).should_receive(:new).once.with(parsed_options).and_return component
            expect_component_execution component
            @rec = Queue.new
            subject.record(options.merge(:async => false)) { |rec| @rec.push rec }
            component.request!
            component.execute!
          end

          it 'should execute a passed block' do
            component.trigger_event_handler response
            Timeout::timeout 5 do
              @rec.pop.should be == response
            end
          end
        end

        describe "with :interruptible => false" do
          let(:input_component) { Punchblock::Component::Input.new }
          it "does not use an Input component" do
            subject.should_receive(:execute_component_and_await_completion).once.with(component)
            subject.should_receive(:write_and_await_response).never.with(input_component)
            subject.record(options.merge(:async => false, :interruptible => false)) { |rec| @rec.push rec }
          end
        end

        describe "with :interruptible => true" do
          let(:input_component) { Punchblock::Component::Input.new }
          it "stops the recording" do
            flexmock(Punchblock::Event::Complete).new_instances.should_receive(:reason => flexmock(:name => :input))

            def subject.write_and_await_response(input_component)
              input_component.trigger_event_handler Punchblock::Event::Complete.new
            end

            complete_event = Punchblock::Event::Complete.new
            flexmock(complete_event).should_receive(:reason => flexmock(:name => :input))
            flexmock(Punchblock::Component::Input).new_instances do |input|
              input.should_receive(:complete?).and_return(true)
              input.should_receive(:complete_event).and_return(complete_event)
            end
            flexmock(Punchblock::Component::Record).new_instances.should_receive(:stop!)
            subject.should_receive(:execute_component_and_await_completion).once.with(component)
            subject.record(options.merge(:async => false, :interruptible => true)) { |rec| @rec.push rec }
          end

        end

        describe "check for the return value" do
          it "returns a Record component" do
            component
            flexmock(Punchblock::Component::Record).should_receive(:new).once.with(parsed_options).and_return component
            expect_component_execution component
            subject.record(options.merge(:async => false)).should be == component
            component.request!
            component.execute!
          end
        end

      end
    end
  end
end
