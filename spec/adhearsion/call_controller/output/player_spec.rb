# encoding: utf-8

require 'spec_helper'

module Adhearsion
  class CallController
    module Output
      describe Player do
        include CallControllerTestHelpers

        let(:controller) { flexmock new_controller }

        subject { Player.new controller }

        describe "#stream_file" do
          let(:allowed_digits)  { '35' }
          let(:prompt)          { "Press 3 or 5 to make something happen." }

          let(:ssml) do
            RubySpeech::SSML.draw do
              string "Press 3 or 5 to make something happen."
            end
          end

          let(:grammar) do
            RubySpeech::GRXML.draw :mode => 'dtmf', :root => 'acceptdigits' do
              rule id: 'acceptdigits' do
                one_of do
                  allowed_digits.each { |d| item { d.to_s } }
                end
              end
            end
          end

          let(:output_component) {
            Punchblock::Component::Output.new :ssml => ssml.to_s
          }

          let(:input_component) {
            Punchblock::Component::Input.new :mode => :dtmf,
                                             :grammar => { :value => grammar.to_s }
          }

          #test does pass and method works, but not sure if the empty method is a good idea
          it "plays the correct output" do
            def controller.write_and_await_response(input_component)
              # it is actually a no-op here
            end

            def expect_component_complete_event
              complete_event = Punchblock::Event::Complete.new
              flexmock(complete_event).should_receive(:reason => flexmock(:interpretation => 'dtmf-5', :name => :input))
              flexmock(Punchblock::Component::Input).new_instances do |input|
                input.should_receive(:complete?).and_return(false)
                input.should_receive(:complete_event).and_return(complete_event)
              end
            end

            expect_component_complete_event
            expect_component_execution Punchblock::Component::Output.new(:ssml => ssml.to_s)
            subject.stream_file prompt, allowed_digits
          end

          it "returns a single digit amongst the allowed when pressed" do
            flexmock(Punchblock::Event::Complete).new_instances.should_receive(:reason => flexmock(:interpretation => 'dtmf-5', :name => :input))

            def controller.write_and_await_response(input_component)
              input_component.trigger_event_handler Punchblock::Event::Complete.new
            end

            def expect_component_complete_event
              complete_event = Punchblock::Event::Complete.new
              flexmock(complete_event).should_receive(:reason => flexmock(:interpretation => 'dtmf-5', :name => :input))
              flexmock(Punchblock::Component::Input).new_instances do |input|
                input.should_receive(:complete?).and_return(false)
                input.should_receive(:complete_event).and_return(complete_event)
              end
            end

            expect_component_complete_event
            flexmock(Punchblock::Component::Output).new_instances.should_receive(:stop!)
            expect_component_execution output_component
            subject.stream_file(prompt, allowed_digits).should be == '5'
          end
        end

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
