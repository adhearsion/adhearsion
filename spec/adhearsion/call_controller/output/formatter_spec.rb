# encoding: utf-8

require 'spec_helper'
require 'ruby_speech'

module Adhearsion
  class CallController
    module Output
      describe Formatter do
        describe "#ssml_for" do
          let(:prompt) { "Please stand by" }

          let(:ssml) do
            RubySpeech::SSML.draw { string 'Please stand by' }
          end

          it 'returns SSML for a text argument' do
            subject.ssml_for(prompt).should be == ssml
          end

          it 'returns the same SSML passed in if it is SSML' do
            subject.ssml_for(ssml).should be == ssml
          end
        end

        describe "#ssml_for_collection" do
          let(:collection) { ["/foo/bar.wav", 1, Time.now] }
          let :ssml do
            file = collection[0]
            n = collection[1].to_s
            t = collection[2].to_s
            RubySpeech::SSML.draw do
              audio :src => file
              say_as(:interpret_as => 'cardinal') { n }
              say_as(:interpret_as => 'time') { t }
            end
          end

          it "should create a composite SSML document" do
            subject.ssml_for_collection(collection).should be == ssml
          end
        end

        describe "#detect_type" do
          it "detects an HTTP path" do
            http_path = "http://adhearsion.com/sounds/hello.mp3"
            subject.detect_type(http_path).should be :audio
          end

          it "detects an HTTP path, even when it has a {profile}" do
            http_path = "{profile=s3}http://adhearsion.com/sounds/hello.mp3"
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

          ["Foo", "Foo bar", "The answer: foo", "The answer could be foo/bar"].each do |string|
            it "detects '#{string}' as text" do
              subject.detect_type(string).should be :text
            end
          end
        end
      end
    end
  end
end
