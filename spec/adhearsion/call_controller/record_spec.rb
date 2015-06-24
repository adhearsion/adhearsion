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

        let(:component) { Adhearsion::Rayo::Component::Record.new component_options }
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
        let(:input_component) { Adhearsion::Rayo::Component::Input.new mode: :dtmf, grammar: { :value => stopper_grammar } }

        subject { Recorder.new controller, options }

        describe '#record_component' do
          subject { super().record_component }
          it { is_expected.to eq(component) }
        end

        context "when passing time related options" do
          let :component_options do
            { :max_duration => 5.5, :initial_timeout => 6.5, :final_timeout => 3.2 }
          end

          let :component do
            Adhearsion::Rayo::Component::Record.new :max_duration => 5500,
              :initial_timeout => 6500,
              :final_timeout => 3200
          end

          it "takes seconds but sets milliseconds on the command" do
            expect(subject.record_component).to eq(component)
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
            describe '#stopper_component' do
              subject { super().stopper_component }
              it { is_expected.to be_nil }
            end

            it "does not use an Input component" do
              expect(controller).to receive(:execute_component_and_await_completion).once.with(component)
              expect(controller).to receive(:write_and_await_response).never.with(input_component)
              subject.run
            end
          end

          context "with :interruptible => true" do
            let(:interruptible) { true }

            describe '#stopper_component' do
              subject { super().stopper_component }
              it { is_expected.to eq(input_component) }
            end

            describe "when the input component completes" do
              let(:complete_event) { Adhearsion::Event::Complete.new }

              before do
                subject.stopper_component.request!
                subject.stopper_component.execute!
              end

              it "stops the recording" do
                expect(subject.record_component).to receive(:stop!).once
                subject.stopper_component.trigger_event_handler complete_event
              end
            end

            describe "when the recording completes" do
              it "stops the input component" do
                expect(controller).to receive(:execute_component_and_await_completion).once.with(component)
                expect(controller).to receive(:write_and_await_response).once.with(input_component)
                expect(subject.stopper_component).to receive(:stop!).once
                subject.run
              end
            end
          end
        end

        context "with :interruptible => '123'" do
          let(:interruptible) { '123' }

          let :stopper_grammar do
            RubySpeech::GRXML.draw :mode => 'dtmf', :root => 'inputdigits' do
              rule id: 'inputdigits', scope: 'public' do
                one_of do
                  item { '1' }
                  item { '2' }
                  item { '3' }
                end
              end
            end
          end

          describe '#stopper_component' do
            subject { super().stopper_component }
            it { is_expected.to eq(input_component) }
          end
        end

        describe "setting completion handlers" do
          let(:complete_event) { Adhearsion::Event::Complete.new }

          it "should execute those handlers when recording completes" do
            foo = double 'foo'
            expect(foo).to receive(:call).once.with kind_of(Adhearsion::Event::Complete)
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
        let(:component) { Adhearsion::Rayo::Component::Record.new parsed_options }
        let(:response)  { Adhearsion::Event::Complete.new }

        describe "with :async => true and an :on_complete callback" do
          before do
            component
            expect(Adhearsion::Rayo::Component::Record).to receive(:new).once.with(parsed_options).and_return component
            expect_message_waiting_for_response component
            @rec = Queue.new
            subject.record(options.merge(async: true)) { |rec| @rec.push rec }
            component.request!
            component.execute!
          end

          it "should execute the callback" do
            component.trigger_event_handler response
            Timeout::timeout 5 do
              expect(@rec.pop).to be response
            end
          end
        end

        describe "when the callback raises an exception" do
          before do
            TestException = Class.new StandardError
            component
            expect(Adhearsion::Rayo::Component::Record).to receive(:new).once.with({}).and_return component
          end

          it "should pass the exception to the events system" do
            latch = CountDownLatch.new 1
            Adhearsion::Events.exception do |e, l|
              expect(e).to be_a TestException
              expect(l).to be subject.logger
              latch.countdown!
            end
            expect_component_execution component
            subject.record { |rec| raise TestException }
            component.request!
            component.execute!
            component.trigger_event_handler response
            expect(latch.wait(1)).to be true
          end
        end

        describe "with :async => false" do
          before do
            component
            expect(Adhearsion::Rayo::Component::Record).to receive(:new).once.with(parsed_options).and_return component
            expect_component_execution component
            @rec = Queue.new
            subject.record(options.merge(:async => false)) { |rec| @rec.push rec }
            component.request!
            component.execute!
          end

          it 'should execute a passed block' do
            component.trigger_event_handler response
            Timeout::timeout 5 do
              expect(@rec.pop).to eq(response)
            end
          end
        end

        describe "with :interruptible => false" do
          let(:input_component) { Adhearsion::Rayo::Component::Input.new }
          it "does not use an Input component" do
            expect(subject).to receive(:execute_component_and_await_completion).once.with(component)
            expect(subject).to receive(:write_and_await_response).never.with(input_component)
            subject.record(options.merge(:async => false, :interruptible => false)) { |rec| @rec.push rec }
          end
        end

        describe "with :interruptible => true" do
          it "stops the recording" do
            def subject.write_and_await_response(input_component)
              input_component.trigger_event_handler Adhearsion::Event::Complete.new
            end

            expect_input_component_complete_event 'dtmf-5'

            expect_any_instance_of(Adhearsion::Rayo::Component::Record).to receive(:stop!)
            expect(subject).to receive(:execute_component_and_await_completion).once.with(component)
            subject.record(options.merge(:async => false, :interruptible => true)) { |rec| @rec.push rec }
          end

        end

        describe "check for the return value" do
          it "returns a Record component" do
            component
            expect(Adhearsion::Rayo::Component::Record).to receive(:new).once.with(parsed_options).and_return component
            expect_component_execution component
            expect(subject.record(options.merge(:async => false))).to eq(component)
            component.request!
            component.execute!
          end
        end

      end
    end
  end
end
