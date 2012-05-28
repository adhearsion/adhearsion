# encoding: utf-8

require 'spec_helper'

module Adhearsion
  class CallController
    module Output
      describe Formatter, :focus do
        subject { Formatter }

        describe ".ssml_for" do
          let(:prompt) { "Please stand by" }

          let(:ssml) do
            RubySpeech::SSML.draw { string 'Please stand by' }
          end

          it 'returns SSML for a text argument' do
            subject.ssml_for(prompt).should be == ssml
          end

          it 'returns the same SSML passed in if it is SSML' do
            subject.ssml_for(ssml) == ssml
          end
        end

        describe ".detect_type" do
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
      end
    end
  end
end
