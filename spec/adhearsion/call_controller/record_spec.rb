# encoding: utf-8

require 'spec_helper'

module Adhearsion
  class CallController
    describe Record do
      include CallControllerTestHelpers

      describe "Recorder" do
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

        describe "#initialize" do
          it "creates the Record component and assigns it to the accessor" do
            recorder = Recorder.new subject, options
            flexmock(Punchblock::Component::Record).should_receive(:new).once.with(parsed_options).and_return component
            recorder.record_component.should be_a Punchblock::Component::Record
          end
        end

        describe "#run" do
          let(:interruptible) { false }
          let(:async) { false }
          let(:recorder) { flexmock(Recorder.new subject, options.merge(:interruptible => interruptible, :async => async)) }
          let(:input_component) { Punchblock::Component::Input.new }

          context "with :async => false" do
            it "executes the component synchronously" do
              flexmock(Punchblock::Component::Record).should_receive(:new).with(parsed_options).and_return component
              expect_component_execution component
              recorder.run
            end
          end

          context "with :async => true" do
            let(:async) { true }
            it "executes the component asynchronously" do
              flexmock(Punchblock::Component::Record).should_receive(:new).with(parsed_options).and_return component
               expect_message_waiting_for_response component
              recorder.run
            end
          end

          context "with :interruptible => false" do
            it "does not call #setup_stopper" do
              recorder.should_receive(:setup_stopper).never
              recorder.should_receive(:execute_recording).once
              recorder.should_receive(:terminate_stopper).once
              recorder.run
            end
            it "does not use an Input component" do
              subject.should_receive(:execute_component_and_await_completion).once.with(component)
              subject.should_receive(:write_and_await_response).never.with(input_component)
              recorder.run
            end
          end

          context "with :interruptible => true" do
            let(:interruptible) { true }
            it "does call #setup_stopper" do
              recorder.should_receive(:setup_stopper).once
              recorder.should_receive(:execute_recording).once
              recorder.should_receive(:terminate_stopper).once
              recorder.run
            end
            
            it "stops the recording" do
              flexmock(Punchblock::Event::Complete).new_instances.should_receive(:reason => flexmock(:name => :input))

              def subject.write_and_await_response(input_component)
                input_component.trigger_event_handler Punchblock::Event::Complete.new
              end

              complete_event = Punchblock::Event::Complete.new
              flexmock(complete_event).should_receive(:reason => flexmock(:name => :input))
              flexmock(Punchblock::Component::Input).new_instances do |input|
                input.should_receive(:complete?).and_return(false)
                input.should_receive(:complete_event).and_return(complete_event)
              end
              flexmock(Punchblock::Component::Record).new_instances.should_receive(:stop!)
              subject.should_receive(:execute_component_and_await_completion).once.with(component)
              recorder.run
            end
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
              input.should_receive(:complete?).and_return(false)
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
