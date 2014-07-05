# encoding: utf-8

require 'spec_helper'
require 'ruby_speech'

module Adhearsion
  class CallController
    module Output
      describe AsyncPlayer do
        include CallControllerTestHelpers

        let(:controller) { new_controller }

        subject { AsyncPlayer.new controller }

        describe "#output" do
          let(:content) { RubySpeech::SSML.draw { string "BOO" } }

          it "should execute an output component with the provided SSML content" do
            component = Punchblock::Component::Output.new :ssml => content
            expect_message_waiting_for_response component
            subject.output content
          end

          it "should allow extra options to be passed to the output component" do
            component = Punchblock::Component::Output.new :ssml => content, :start_paused => true
            expect_message_waiting_for_response component
            subject.output content, :start_paused => true
          end

          it "returns the component" do
            component = Punchblock::Component::Output.new :ssml => content
            expect_message_waiting_for_response component
            expect(subject.output(content)).to be_a Punchblock::Component::Output
          end

          it "raises a PlaybackError if the component fails to start" do
            expect_message_waiting_for_response Punchblock::Component::Output.new(:ssml => content), Punchblock::ProtocolError
            expect { subject.output content }.to raise_error(PlaybackError)
          end

          it "logs the complete event if it is an error" do
            response = Punchblock::Event::Complete.new
            response.reason = Punchblock::Event::Complete::Error.new
            component = Punchblock::Component::Output.new(:ssml => content)
            allow(subject).to receive_messages :new_output => component
            expect_message_waiting_for_response component
            expect(controller.logger).to receive(:error).once
            subject.output content
            component.request!
            component.execute!
            component.trigger_event_handler response
          end
        end

        describe "#play_ssml" do
          let(:ssml) { RubySpeech::SSML.draw { string "BOO" } }

          it 'executes an Output with the correct ssml' do
            component = Punchblock::Component::Output.new :ssml => ssml
            expect_message_waiting_for_response component
            subject.play_ssml ssml
          end
        end
      end
    end
  end
end
