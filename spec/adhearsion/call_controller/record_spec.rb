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

    end
  end
end
