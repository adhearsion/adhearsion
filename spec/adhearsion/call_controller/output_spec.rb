# encoding: utf-8

require 'spec_helper'

module Adhearsion
  class CallController
    describe Output do
      include CallControllerTestHelpers

      describe "#play_ssml" do
        let(:ssml) { RubySpeech::SSML.draw { string "BOO" } }

        it 'executes an Output with the correct ssml' do
          expect_component_execution Punchblock::Component::Output.new(:ssml => ssml.to_s)
          subject.play_ssml ssml
        end

        describe "if an error is returned" do
          before do
            pending
            subject.should_receive(:execute_component_and_await_completion).once.and_raise(StandardError)
          end

          it 'should return false' do
            pending
            subject.play_ssml(ssml).should be false
          end
        end
      end

      describe "#play_audio" do
        let(:audio_file)  { "/sounds/boo.wav" }
        let(:fallback)    { "text for tts" }

        let(:ssml) do
          file = audio_file
          RubySpeech::SSML.draw { audio :src => file }
        end

        let(:ssml_with_fallback) do
          file = audio_file
          fallback_text = fallback
          RubySpeech::SSML.draw {
            audio(:src => file) { fallback_text }
          }
        end

        it 'plays the correct ssml' do
          subject.should_receive(:play_ssml).once.with(ssml).and_return true
          subject.play_audio(audio_file).should be true
        end

        it 'allows for fallback tts' do
          subject.should_receive(:play_ssml).once.with(ssml_with_fallback).and_return true
          subject.play_audio(audio_file, :fallback => fallback).should be true
        end
      end

      describe "#play_numeric" do
        let :expected_doc do
          RubySpeech::SSML.draw do
            say_as(:interpret_as => 'cardinal') { "123" }
          end
        end

        describe "with a number" do
          let(:input) { 123 }

          it 'plays the correct ssml' do
            subject.should_receive(:play_ssml).once.with(expected_doc).and_return true
            subject.play_numeric(input).should be true
          end
        end

        describe "with a string representation of a number" do
          let(:input) { "123" }

          it 'plays the correct ssml' do
            subject.should_receive(:play_ssml).once.with(expected_doc).and_return true
            subject.play_numeric(input).should be true
          end
        end

        describe "with something that's not a number" do
          let(:input) { 'foo' }

          it 'returns nil' do
            subject.play_numeric(input).should be nil
          end
        end
      end

      describe "#play_time" do
        let :expected_doc do
          content = input.to_s
          opts    = expected_say_as_options
          RubySpeech::SSML.draw do
            say_as(opts) { content }
          end
        end

        describe "with a time" do
          let(:input) { Time.parse("12/5/2000") }
          let(:expected_say_as_options) { {:interpret_as => 'time'} }

          it 'plays the correct SSML' do
            subject.should_receive(:play_ssml).once.with(expected_doc).and_return true
            subject.play_time(input).should be true
          end
        end

        describe "with a date" do
          let(:input) { Date.parse('2011-01-23') }
          let(:expected_say_as_options) { {:interpret_as => 'date'} }

          it 'plays the correct SSML' do
            subject.should_receive(:play_ssml).once.with(expected_doc).and_return true
            subject.play_time(input).should be true
          end
        end

        describe "with a date and a say_as format" do
          let(:input)   { Date.parse('2011-01-23') }
          let(:format)  { "d-m-y" }
          let(:expected_say_as_options) { {:interpret_as => 'date', :format => format} }

          it 'plays the correct SSML' do
            subject.should_receive(:play_ssml).once.with(expected_doc).and_return true
            subject.play_time(input, :format => format).should be true
          end
        end

        describe "with a date and a strftime option" do
          let(:strftime)    { "%d-%m-%Y" }
          let(:base_input)  { Date.parse('2011-01-23') }
          let(:input)       { base_input.strftime(strftime) }
          let(:expected_say_as_options) { {:interpret_as => 'date'} }

          it 'plays the correct SSML' do
            subject.should_receive(:play_ssml).once.with(expected_doc).and_return true
            subject.play_time(base_input, :strftime => strftime).should be true
          end
        end

        describe "with a date, a format option and a strftime option" do
          let(:strftime)    { "%d-%m-%Y" }
          let(:format)      { "d-m-y" }
          let(:base_input)  { Date.parse('2011-01-23') }
          let(:input)       { base_input.strftime(strftime) }
          let(:expected_say_as_options) { {:interpret_as => 'date', :format => format} }

          it 'plays the correct SSML' do
            subject.should_receive(:play_ssml).once.with(expected_doc).and_return true
            subject.play_time(base_input, :format => format, :strftime => strftime).should be true
          end
        end

        describe "with an object other than Time, DateTime, or Date" do
          let(:input) { "foo" }

          it 'returns false' do
            subject.play_time(input).should be false
          end
        end
      end

      describe '#play' do
        describe "with a single string" do
          let(:file) { "cents-per-minute" }

          it 'plays the audio file' do
            subject.should_receive(:play_ssml_for).once.with(file).and_return true
            subject.play(file).should be true
          end
        end

        describe "with multiple strings" do
          let(:args) { ['rock', 'paperz', 'scissors'] }

          it 'plays multiple files' do
            args.each do |file|
              subject.should_receive(:play_ssml_for).once.with(file).and_return true
            end

            subject.play(*args).should be true
          end

          describe "if an audio file cannot be found" do
            before do
              pending
              subject.should_receive(:play_audio).with(args[0]).and_return(true).ordered
              subject.should_receive(:play_audio).with(args[1]).and_return(false).ordered
              subject.should_receive(:play_audio).with(args[2]).and_return(true).ordered
            end

            it 'should return false' do
              subject.play(*args).should be false
            end
          end
        end

        describe "with a number" do
          it 'plays the number' do
            subject.should_receive(:play_ssml_for).with(123).and_return(true)
            subject.play(123).should be true
          end
        end

        describe "with a string representation of a number" do
          it 'plays the number' do
            subject.should_receive(:play_ssml_for).with('123').and_return(true)
            subject.play('123').should be true
          end
        end

        describe "with a time" do
          let(:time) { Time.parse("12/5/2000") }

          it 'plays the time' do
            subject.should_receive(:play_ssml_for).with(time).and_return(true)
            subject.play(time).should be true
          end
        end

        describe "with a date" do
          let(:date) { Date.parse('2011-01-23') }

          it 'plays the time' do
            subject.should_receive(:play_ssml_for).with(date).and_return(true)
            subject.play(date).should be true
          end
        end

        describe "with an array containing a Date/DateTime/Time object and a hash" do
          let(:date)      { Date.parse('2011-01-23') }
          let(:format)    { "d-m-y" }
          let(:strftime)  { "%d-%m%Y" }

          it 'plays the time with the specified format and strftime' do
            subject.should_receive(:play_ssml_for).with(date, {:format => format, :strftime => strftime}).and_return(true)
            subject.play({:value => date, :format => format, :strftime => strftime}).should be true
          end
        end

        describe "with an SSML document" do
          let(:ssml) { RubySpeech::SSML.draw { string "Hello world" } }

          it "plays the SSML without generating" do
            subject.should_receive(:play_ssml).with(ssml).and_return(true)
            subject.play(ssml).should be true
          end
        end
      end

      describe "#play!" do
        let(:prompt)        { "Press any button." }
        let(:second_prompt) { "Or press nothing." }
        let(:non_existing) { "http://adhearsion.com/nonexistingfile.mp3" }

        it "calls play a single time" do
          subject.should_receive(:play).once.with(prompt).and_return(true)
          subject.play!(prompt)
        end

        it "calls play two times" do
          subject.should_receive(:play).once.with(prompt, second_prompt).and_return(true)
          subject.play!(prompt, second_prompt)
        end

        it "raises an exception if play fails" do
          subject.should_receive(:play).once.and_return false
          expect { subject.play!(non_existing) }.to raise_error(Output::PlaybackError)
        end
      end

      describe "#speak" do
        it "should be an alias for #say" do
          subject.method(:speak).should be == subject.method(:say)
        end
      end

      describe "#say" do
        describe "with a RubySpeech document" do
          it 'plays the correct SSML' do
            doc = RubySpeech::SSML.draw { string "Hello world" }
            subject.should_receive(:play_ssml).once.with(doc, {}).and_return true
            subject.should_receive(:output).never
            subject.say(doc).should be true
          end
        end

        describe "with a string" do
          it 'outputs the correct text' do
            string = "Hello world"
            subject.should_receive(:play_ssml).once.with(string, {})
            subject.should_receive(:output).once.with(:text, string, {}).and_return true
            subject.say(string).should be true
          end
        end

        describe "converts the argument to a string" do
          it 'calls output with a string' do
            expected_string = "123"
            argument = 123
            subject.should_receive(:play_ssml).once.with(argument, {})
            subject.should_receive(:output).once.with(:text, expected_string, {}).and_return true
            subject.say(argument)
          end
        end
      end

      describe "#ssml_for" do
        let(:prompt) { "Please stand by" }

        let(:ssml) do
          RubySpeech::SSML.draw do
            string 'Please stand by'
          end
        end

        it 'returns SSML for a text argument' do
          subject.ssml_for(prompt).should be == ssml
        end

        it 'returns the same SSML passed in if it is SSML' do
          subject.ssml_for(ssml) == ssml
        end
      end

      describe "#detect_type" do
        it "detects an HTTP path" do
          http_path = "http://adhearsion.com/sounds/hello.mp3"
          subject.detect_type(http_path).should be :audio
        end

        it "detects a file path" do
          file_path = "file:///usr/shared/sounds/hello.mp3"
          subject.detect_type(file_path).should be :audio

          absolute_path = "/usr/shared/sounds/hello.mp3"
          subject.detect_type(absolute_path).should be :audio

          relative_path = "foo/bar"
          subject.detect_type(relative_path).should_not be :audio
        end

        it "detects a Date object" do
          today = Date.today
          subject.detect_type(today).should be :time
        end

        it "detects a Time object" do
          now = Time.now
          subject.detect_type(now).should be :time
        end

        it "detects a DateTime object" do
          today = DateTime.now
          subject.detect_type(today).should be :time
        end

        it "detects a Numeric object" do
          number = 123
          subject.detect_type(number).should be :numeric
        end

        it "returns text as a fallback" do
          output = "Hello"
          subject.detect_type(output).should be :text
        end
      end

      describe "#stream_file" do
        let(:allowed_digits)  { '35' }
        let(:prompt)          { "Press 3 or 5 to make something happen." }

        let(:ssml) {
          RubySpeech::SSML.draw do
            string "Press 3 or 5 to make something happen."
          end
        }

        let(:grammar) {
         RubySpeech::GRXML.draw :mode => 'dtmf', :root => 'acceptdigits' do
            rule id: 'acceptdigits' do
              one_of do
                allowed_digits.each { |d| item { d.to_s } }
              end
            end
          end
        }

        let(:output_component) {
          Punchblock::Component::Output.new :ssml => ssml.to_s
        }

        let(:input_component) {
          Punchblock::Component::Input.new :mode => :dtmf,
                                           :grammar => { :value => grammar.to_s }
        }

        #test does pass and method works, but not sure if the empty method is a good idea
        it "plays the correct output" do
          def subject.write_and_await_response(input_component)
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

          def subject.write_and_await_response(input_component)
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
          subject.should_receive(:execute_component_and_await_completion).once.with(output_component)
          subject.stream_file(prompt, allowed_digits).should be == '5'
        end
      end # describe #stream_file


      describe "#interruptible_play!" do
        let(:output1)       { "one two" }
        let(:output2)       { "three four" }
        let(:non_existing)  { "http://adhearsion.com/nonexistingfile.mp3" }

        it "plays two outputs in succession" do
          subject.should_receive(:stream_file).twice
          subject.interruptible_play! output1, output2
        end

        it "stops at the first play when input is received" do
          subject.should_receive(:stream_file).once.and_return(2)
          subject.interruptible_play! output1, output2
        end

        it 'raises an exception when output is unsuccessful' do
          subject.should_receive(:stream_file).once.and_raise Output::PlaybackError, "Output failed"
          expect { subject.interruptible_play!(non_existing) }.to raise_error(Output::PlaybackError)
        end
      end # describe interruptible_play!

      describe "#interruptible_play" do
        let(:output1)       { "one two" }
        let(:output2)       { "three four" }
        let(:non_existing)  { "http://adhearsion.com/nonexistingfile.mp3" }

        it "plays two outputs in succession" do
          subject.should_receive(:interruptible_play!).twice
          subject.interruptible_play output1, output2
        end

        it "stops at the first play when input is received" do
          subject.should_receive(:interruptible_play!).once.and_return(2)
          subject.interruptible_play output1, output2
        end

        it "should not raise an exception when output is unsuccessful" do
          subject.should_receive(:stream_file).once.and_raise Output::PlaybackError, "Output failed"
          lambda { subject.interruptible_play non_existing }.should_not raise_error(Output::PlaybackError)
        end
      end # describe interruptible_play

    end
  end
end
