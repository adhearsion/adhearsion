# encoding: utf-8

require 'spec_helper'

module Adhearsion
  class CallController
    describe Output do
      include CallControllerTestHelpers

      def expect_ssml_output(ssml)
        expect_component_execution Punchblock::Component::Output.new(:ssml => ssml)
      end

      def expect_async_ssml_output(ssml)
        expect_message_waiting_for_response Punchblock::Component::Output.new(:ssml => ssml)
      end

      describe "#player" do
        it "should return a Player component targetted at the current controller" do
          player = controller.player
          player.should be_a Output::Player
          player.controller.should be controller
        end

        it "should return the same player every time" do
          controller.player.should be controller.player
        end
      end

      describe "#async_player" do
        it "should return an AsyncPlayer component targetted at the current controller" do
          player = controller.async_player
          player.should be_a Output::AsyncPlayer
          player.controller.should be controller
        end

        it "should return the same player every time" do
          controller.async_player.should be controller.async_player
        end
      end

      describe "#play_audio" do
        let(:audio_file) { "/sounds/boo.wav" }

        let :ssml do
          file = audio_file
          RubySpeech::SSML.draw { audio :src => file }
        end

        it 'plays the correct ssml' do
          expect_ssml_output ssml
          subject.play_audio(audio_file).should be true
        end

        context "with a fallback" do
          let(:fallback) { "text for tts" }

          let :ssml do
            file = audio_file
            fallback_text = fallback
            RubySpeech::SSML.draw do
              audio(:src => file) { fallback_text }
            end
          end

          it 'places the fallback in the SSML doc' do
            expect_ssml_output ssml
            subject.play_audio(audio_file, :fallback => fallback).should be true
          end
        end
      end

      describe "#play_audio_async" do
        let(:audio_file) { "/sounds/boo.wav" }

        let :ssml do
          file = audio_file
          RubySpeech::SSML.draw { audio :src => file }
        end

        it 'plays the correct ssml' do
          expect_async_ssml_output ssml
          subject.play_audio_async(audio_file).should be_a Punchblock::Component::Output
        end

        context "with a fallback" do
          let(:fallback) { "text for tts" }

          let :ssml do
            file = audio_file
            fallback_text = fallback
            RubySpeech::SSML.draw do
              audio(:src => file) { fallback_text }
            end
          end

          it 'places the fallback in the SSML doc' do
            expect_async_ssml_output ssml
            subject.play_audio_async(audio_file, :fallback => fallback).should be_a Punchblock::Component::Output
          end
        end
      end

      describe "#play_numeric" do
        let :ssml do
          RubySpeech::SSML.draw do
            say_as(:interpret_as => 'cardinal') { "123" }
          end
        end

        describe "with a number" do
          let(:input) { 123 }

          it 'plays the correct ssml' do
            expect_ssml_output ssml
            subject.play_numeric(input).should be true
          end
        end

        describe "with a string representation of a number" do
          let(:input) { "123" }

          it 'plays the correct ssml' do
            expect_ssml_output ssml
            subject.play_numeric(input).should be true
          end
        end

        describe "with something that's not a number" do
          let(:input) { 'foo' }

          it 'raises ArgumentError' do
            lambda { subject.play_numeric input }.should raise_error(ArgumentError)
          end
        end
      end

      describe "#play_time" do
        let :ssml do
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
            expect_ssml_output ssml
            subject.play_time(input).should be true
          end
        end

        describe "with a date" do
          let(:input) { Date.parse('2011-01-23') }
          let(:expected_say_as_options) { {:interpret_as => 'date'} }

          it 'plays the correct SSML' do
            expect_ssml_output ssml
            subject.play_time(input).should be true
          end
        end

        describe "with a date and a say_as format" do
          let(:input)   { Date.parse('2011-01-23') }
          let(:format)  { "d-m-y" }
          let(:expected_say_as_options) { {:interpret_as => 'date', :format => format} }

          it 'plays the correct SSML' do
            expect_ssml_output ssml
            subject.play_time(input, :format => format).should be true
          end
        end

        describe "with a date and a strftime option" do
          let(:strftime)    { "%d-%m-%Y" }
          let(:base_input)  { Date.parse('2011-01-23') }
          let(:input)       { base_input.strftime(strftime) }
          let(:expected_say_as_options) { {:interpret_as => 'date'} }

          it 'plays the correct SSML' do
            expect_ssml_output ssml
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
            expect_ssml_output ssml
            subject.play_time(base_input, :format => format, :strftime => strftime).should be true
          end
        end

        describe "with an object other than Time, DateTime, or Date" do
          let(:input) { "foo" }

          it 'raises ArgumentError' do
            lambda { subject.play_time input }.should raise_error(ArgumentError)
          end
        end
      end

      describe '#play' do
        describe "with a single string" do
          let(:audio_file) { "/foo/bar.wav" }
          let :ssml do
            file = audio_file
            RubySpeech::SSML.draw { audio :src => file }
          end

          it 'plays the audio file' do
            expect_ssml_output ssml
            subject.play(audio_file).should be true
          end
        end

        describe "with multiple arguments" do
          let(:args) { ["/foo/bar.wav", "/foo/bar2.wav", "/foo/bar3.wav"] }
          let :ssml do
            file = audio_file
            RubySpeech::SSML.draw { audio :src => file }
          end

          it 'plays multiple files' do
            args.each do |file|
              ssml = RubySpeech::SSML.draw { audio :src => file }
              expect_ssml_output ssml
            end

            subject.play(*args).should be true
          end
        end

        describe "with a number" do
          let(:argument) { 123 }

          let(:ssml) do
            number = argument.to_s
            RubySpeech::SSML.draw do
              say_as(:interpret_as => 'cardinal') { number }
            end
          end

          it 'plays the number' do
            expect_ssml_output ssml
            subject.play(argument).should be true
          end
        end

        describe "with a string representation of a number" do
          let(:argument) { '123' }

          let(:ssml) do
            number = argument
            RubySpeech::SSML.draw do
              say_as(:interpret_as => 'cardinal') { number }
            end
          end

          it 'plays the number' do
            expect_ssml_output ssml
            subject.play(argument).should be true
          end
        end

        describe "with a time" do
          let(:time) { Time.parse "12/5/2000" }

          let(:ssml) do
            t = time.to_s
            RubySpeech::SSML.draw do
              say_as(:interpret_as => 'time') { t }
            end
          end

          it 'plays the time' do
            expect_ssml_output ssml
            subject.play(time).should be true
          end
        end

        describe "with a date" do
          let(:date) { Date.parse '2011-01-23' }
          let(:ssml) do
            d = date.to_s
            RubySpeech::SSML.draw do
              say_as(:interpret_as => 'date') { d }
            end
          end

          it 'plays the time' do
            expect_ssml_output ssml
            subject.play(date).should be true
          end
        end

        describe "with an array containing a Date/DateTime/Time object and a hash" do
          let(:date)      { Date.parse '2011-01-23' }
          let(:format)    { "d-m-y" }
          let(:strftime)  { "%d-%m%Y" }

          let :ssml do
            d = date.strftime strftime
            f = format
            RubySpeech::SSML.draw do
              say_as(:interpret_as => 'date', :format => f) { d }
            end
          end

          it 'plays the time with the specified format and strftime' do
            expect_ssml_output ssml
            subject.play(:value => date, :format => format, :strftime => strftime).should be true
          end
        end

        describe "with an SSML document" do
          let(:ssml) { RubySpeech::SSML.draw { string "Hello world" } }

          it "plays the SSML without generating" do
            expect_ssml_output ssml
            subject.play(ssml).should be true
          end
        end
      end

      describe "#interruptible_play" do
        let(:output1)       { "one two" }
        let(:output2)       { "three four" }
        let(:non_existing)  { "http://adhearsion.com/nonexistingfile.mp3" }

        it "plays two outputs in succession" do
          pending
          subject.should_receive(:stream_file).twice
          subject.interruptible_play output1, output2
        end

        it "stops at the first play when input is received" do
          pending
          subject.should_receive(:stream_file).once.and_return(2)
          subject.interruptible_play output1, output2
        end

        it 'raises an exception when output is unsuccessful' do
          pending
          subject.should_receive(:stream_file).once.and_raise Output::PlaybackError, "Output failed"
          expect { subject.interruptible_play non_existing }.to raise_error(Output::PlaybackError)
        end
      end

      describe "#say" do
        describe "with a RubySpeech document" do
          it 'plays the correct SSML' do
            ssml = RubySpeech::SSML.draw { string "Hello world" }
            expect_ssml_output ssml
            subject.say(ssml).should be_a Punchblock::Component::Output
          end
        end

        describe "with a string" do
          it 'outputs the correct text' do
            str = "Hello world"
            ssml = RubySpeech::SSML.draw { string str }
            expect_ssml_output ssml
            subject.say(str).should be_a Punchblock::Component::Output
          end
        end

        describe "converts the argument to a string" do
          it 'calls output with a string' do
            argument = 123
            ssml = RubySpeech::SSML.draw { string '123' }
            expect_ssml_output ssml
            subject.say(argument).should be_a Punchblock::Component::Output
          end
        end
      end

      describe "#speak" do
        it "should be an alias for #say" do
          subject.method(:speak).should be == subject.method(:say)
        end
      end
    end
  end
end
