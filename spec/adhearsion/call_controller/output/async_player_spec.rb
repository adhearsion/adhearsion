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
            component = Adhearsion::Rayo::Component::Output.new :ssml => content
            expect_message_waiting_for_response component
            subject.output content
          end

          it "should allow extra options to be passed to the output component" do
            component = Adhearsion::Rayo::Component::Output.new :ssml => content, :start_paused => true
            expect_message_waiting_for_response component
            subject.output content, :start_paused => true
          end

          it "returns the component" do
            component = Adhearsion::Rayo::Component::Output.new :ssml => content
            expect_message_waiting_for_response component
            expect(subject.output(content)).to be_a Adhearsion::Rayo::Component::Output
          end

          it "raises a PlaybackError if the component fails to start" do
            expect_message_waiting_for_response Adhearsion::Rayo::Component::Output.new(:ssml => content), Adhearsion::ProtocolError
            expect { subject.output content }.to raise_error(PlaybackError)
          end

          it "logs the complete event if it is an error" do
            response = Adhearsion::Event::Complete.new
            response.reason = Adhearsion::Event::Complete::Error.new
            component = Adhearsion::Rayo::Component::Output.new(:ssml => content)
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
            component = Adhearsion::Rayo::Component::Output.new :ssml => ssml
            expect_message_waiting_for_response component
            subject.play_ssml ssml
          end
        end

        describe "#play_url" do
          let(:url) { "http://example.com/ex.ssml" }

          it 'executes an Output with the URL' do
            component = Adhearsion::Rayo::Component::Output.new({render_document: {value: url, content_type: "application/ssml+xml"}})
            expect_message_waiting_for_response component
            subject.play_url url
          end
        end
      end
    end
  end
end
