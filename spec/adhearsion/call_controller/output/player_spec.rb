# encoding: utf-8

require 'spec_helper'
require 'ruby_speech'

module Adhearsion
  class CallController
    module Output
      describe Player do
        include CallControllerTestHelpers

        let(:controller) { new_controller }

        subject { Player.new controller }

        describe "#output" do
          let(:content) { RubySpeech::SSML.draw { string "BOO" } }

          it "should execute an output component with the provided SSML content" do
            expect_component_execution Punchblock::Component::Output.new(:ssml => content)
            subject.output content
          end

          it "should allow extra options to be passed to the output component" do
            component = Punchblock::Component::Output.new :ssml => content, :start_paused => true
            expect_component_execution component
            subject.output content, :start_paused => true
          end

          it "yields the component to the block before executing it" do
            component = Punchblock::Component::Output.new :ssml => content, :start_paused => true
            expect_component_execution component
            subject.output content do |comp|
              comp.start_paused = true
            end
          end

          it "raises a PlaybackError if the component fails to start" do
            expect_component_execution Punchblock::Component::Output.new(:ssml => content), Punchblock::ProtocolError
            lambda { subject.output content }.should raise_error(PlaybackError)
          end

          it "raises a Playback Error if the component ends due to an error" do
            expect_component_execution Punchblock::Component::Output.new(:ssml => content), Adhearsion::Error
            lambda { subject.output content }.should raise_error(PlaybackError)
          end

          it "raises a Call::Hangup exception if the component ends due to an error" do
            expect_component_execution Punchblock::Component::Output.new(:ssml => content), Call::Hangup
            lambda { subject.output content }.should raise_error(Call::Hangup)
          end
        end

        describe "#play_ssml" do
          let(:ssml) { RubySpeech::SSML.draw { string "BOO" } }

          it 'executes an Output with the correct ssml' do
            expect_component_execution Punchblock::Component::Output.new(:ssml => ssml.to_s)
            subject.play_ssml ssml
          end
        end
      end
    end
  end
end
