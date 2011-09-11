require 'spec_helper'

module Adhearsion
  module Rayo
    module Commands
      describe Record do
        include RayoCommandTestHelpers

        describe "#record" do
          let(:options) {{
            :start_beep => true,
            :max_duration => 5000
          }}
          let(:component) { Punchblock::Component::Record.new(options) }
          let(:response) { Punchblock::Event::Complete.new }

          it 'should accept :async => true and executes :on_complete => lambda' do
            expect_component_execution component
            mock_execution_environment.record(options.merge({:async => true, :on_complete => lambda {|rec| rec }})).should be true
          end

          it 'should accept :async => false and executes a block' do
            expect_message_waiting_for_response component
            component.complete_event.resource = response
            mock_execution_environment.record(options.merge({:async => true})).should be true
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
            component.complete_event.resource = response
          end

          it 'executes a #record with the correct options' do
            mock_execution_environment.execute_component_and_await_completion component
          end

          it 'takes a block which is executed after acknowledgement but before waiting on completion' do
            @comp = nil
            mock_execution_environment.execute_component_and_await_completion(component) { |comp| @comp = comp }.should == component
            @comp.should == component
          end

          describe "with a successful completion" do
            it 'returns the executed component' do
              mock_execution_environment.execute_component_and_await_completion(component).should be component
            end
          end

          describe 'with an error response' do
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

            let(:details) { "Something came up" }

            it 'raises the error' do
              lambda { mock_execution_environment.execute_component_and_await_completion component }.should raise_error(StandardError, details)
            end
          end
        end

      end
    end
  end
end
