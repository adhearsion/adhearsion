# encoding: utf-8

require 'spec_helper'

module Adhearsion
  class CallController
    describe Record do
      include CallControllerTestHelpers

      describe "#record" do
        let(:options) do
          {
            :start_beep => true,
            :max_duration => 5000
          }
        end
        let(:component) { ::Punchblock::Component::Record.new options }
        let(:response)  { ::Punchblock::Event::Complete.new }

        describe "with :async => true and an :on_complete callback" do
          before do
            component
            flexmock(::Punchblock::Component::Record).should_receive(:new).once.with(options).and_return component
            expect_message_waiting_for_response component
            @rec = Queue.new
            subject.record(options.merge(async: true)) { |rec| @rec.push rec }
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
            flexmock(::Punchblock::Component::Record).should_receive(:new).once.with({}).and_return component
          end

          it "should pass the exception to the events system" do
            flexmock(Events).should_receive(:trigger).once.with(:exception, TestException)
            expect_component_execution component
            subject.record { |rec| raise TestException }
            component.request!
            component.execute!
            component.trigger_event_handler response
          end
        end

        describe "with :async => false" do
          before do
            component
            flexmock(::Punchblock::Component::Record).should_receive(:new).once.with(options).and_return component
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
      end

      describe "#record with default options" do
        let(:options) {{
          :start_beep => true,
          :format => 'mp3',
          :start_paused => false,
          :stop_beep => true,
          :max_duration => 500000,
          :initial_timeout => 10000,
          :final_timeout => 30000
        }}

        let(:component) { Punchblock::Component::Record.new(options) }
        let(:response) { Punchblock::Event::Complete.new }

        before do
          expect_message_waiting_for_response component
          component.execute!
          component.complete_event = response
        end

        it 'executes a #record with the correct options' do
          subject.execute_component_and_await_completion component
        end

        it 'takes a block which is executed after acknowledgement but before waiting on completion' do
          @comp = nil
          subject.execute_component_and_await_completion(component) { |comp| @comp = comp }.should be == component
          @comp.should be == component
        end

        describe "with a successful completion" do
          it 'returns the executed component' do
            subject.execute_component_and_await_completion(component).should be component
          end
        end

        describe 'with an error response' do
          let(:response) do
            Punchblock::Event::Complete.new.tap do |complete|
              complete << error
            end
          end

          let(:error) do |error|
            Punchblock::Event::Complete::Error.new.tap do |e|
              e << details
            end
          end

          let(:details) { "Something came up" }

          it 'raises the error' do
            lambda { subject.execute_component_and_await_completion component }.should raise_error(StandardError, details)
          end
        end
      end

    end
  end
end
