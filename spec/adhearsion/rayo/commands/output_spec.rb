require 'spec_helper'

module Adhearsion
  module Rayo
    module Commands
      describe Output do
        include RayoCommandTestHelpers

        describe "#play_ssml" do
          let(:ssml) { RubySpeech::SSML.draw { string "BOO" } }

          it 'executes an Output with the correct ssml' do
            expect_component_execution Punchblock::Component::Output.new(:ssml => ssml.to_s)
            mock_execution_environment.play_ssml(ssml).should be true
          end

          describe "if an error is returned" do
            before do
              mock_execution_environment.should_receive(:execute_component_and_await_completion).once.and_raise(StandardError)
            end

            it 'should return false' do
              mock_execution_environment.play_ssml(ssml).should be false
            end
          end
        end

        describe "#play_audio" do
          let(:audio_file) { "boo.wav" }
          let(:ssml) do
            file = audio_file
            RubySpeech::SSML.draw { audio :src => file }
          end

          it 'plays the correct ssml' do
            mock_execution_environment.should_receive(:play_ssml).once.with(ssml).and_return true
            mock_execution_environment.play_audio(audio_file).should be true
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
              mock_execution_environment.should_receive(:play_ssml).once.with(expected_doc).and_return true
              mock_execution_environment.play_numeric(input).should be true
            end
          end

          describe "with a string representation of a number" do
            let(:input) { "123" }

            it 'plays the correct ssml' do
              mock_execution_environment.should_receive(:play_ssml).once.with(expected_doc).and_return true
              mock_execution_environment.play_numeric(input).should be true
            end
          end

          describe "with something that's not a number" do
            let(:input) { 'foo' }

            it 'returns nil' do
              mock_execution_environment.play_numeric(input).should be nil
            end
          end
        end

        describe "#play_time" do
          let :expected_doc do
            content = input.to_s
            opts = expected_say_as_options
            RubySpeech::SSML.draw do
              say_as(opts) { content }
            end
          end

          describe "with a time" do
            let(:input) { Time.parse("12/5/2000") }
            let(:expected_say_as_options) { {:interpret_as => 'time'} }

            it 'plays the correct SSML' do
              mock_execution_environment.should_receive(:play_ssml).once.with(expected_doc).and_return true
              mock_execution_environment.play_time(input).should be true
            end
          end

          describe "with a date" do
            let(:input) { Date.parse('2011-01-23') }
            let(:expected_say_as_options) { {:interpret_as => 'date'} }

            it 'plays the correct SSML' do
              mock_execution_environment.should_receive(:play_ssml).once.with(expected_doc).and_return true
              mock_execution_environment.play_time(input).should be true
            end
          end

          # describe "with a Date or Time" do
          #   it 'the SayUnixTime application will be executed with the date and format passed in' do
          #     pending
          #     date, format = Date.parse('2011-01-23'), 'ABdY'
          #     mock_call.should_receive(:execute).once.with(:sayunixtime, date.to_time.to_i, "",format).and_return "200 result=0\n"
          #     mock_call.play_time(date, :format => format).should == pbx_raw_response
          #
          #     time, format = Time.at(875121313), 'BdY \'digits/at\' IMp'
          #     mock_call.should_receive(:execute).once.with(:sayunixtime, time.to_i, "",format).and_return pbx_raw_response
          #     mock_call.play_time(time, :format => format).should == pbx_raw_response
          #   end
          # end
          #
          # describe "with a Time" do
          #   it 'If a Time object is passed to play_time, the SayUnixTime application will be executed with the default parameters' do
          #     pending
          #     time = Time.at(875121313)
          #     mock_call.should_receive(:execute).once.with(:sayunixtime, time.to_i, "",'').and_return pbx_raw_response
          #     mock_call.play_time(time).should == pbx_raw_response
          #   end
          # end

          describe "with an object other than Time, DateTime, or Date" do
            let(:input) { "foo" }

            it 'returns false' do
              mock_execution_environment.play_time(input).should be false
            end
          end

          describe "with an array containing a Date/DateTime/Time object and a hash" do
            it 'the SayUnixTime application will be executed with the object passed in with the specified format and timezone' do
              pending
              date, format = Date.parse('2011-01-23'), 'ABdY'
              mock_call.should_receive(:execute).once.with(:sayunixtime, date.to_time.to_i, "",format).and_return pbx_raw_response
              mock_call.play([date, {:format => format}]).should be true

              time, timezone = Time.at(1295843084), 'US/Eastern'
              mock_call.should_receive(:execute).once.with(:sayunixtime, time.to_i, timezone,'').and_return pbx_raw_response
              mock_call.play([time, {:timezone => timezone}]).should be true

              time, timezone, format = Time.at(1295843084), 'US/Eastern', 'ABdY \'digits/at\' IMp'
              mock_call.should_receive(:execute).once.with(:sayunixtime, time.to_i, timezone,format).and_return pbx_raw_response
              mock_call.play([time, {:timezone => timezone, :format => format}]).should be true
            end
          end
        end

        describe '#play' do
          describe "with a single string" do
            let(:file) { "cents-per-minute" }

            it 'plays the audio file' do
              mock_execution_environment.should_receive(:play_audio).once.with(file).and_return true
              mock_execution_environment.play(file).should be true
            end
          end

          describe "with multiple strings" do
            let(:args) { ['rock', 'paperz', 'scissors'] }

            it 'plays multiple files' do
              args.each do |file|
                mock_execution_environment.should_receive(:play_audio).once.with(file).and_return true
              end
              mock_execution_environment.play(*args).should be true
            end

            describe "if an audio file cannot be found" do
              before do
                mock_execution_environment.should_receive(:play_audio).with(args[0]).and_return(true).ordered
                mock_execution_environment.should_receive(:play_audio).with(args[1]).and_return(false).ordered
                mock_execution_environment.should_receive(:play_audio).with(args[2]).and_return(true).ordered
              end

              it 'should return false' do
                mock_execution_environment.play(*args).should be false
              end
            end
          end

          describe "with a number" do
            it 'plays the number' do
              mock_execution_environment.should_receive(:play_numeric).with(123).and_return(true)
              mock_execution_environment.play(123).should be true
            end
          end

          describe "with a string representation of a number" do
            it 'plays the number' do
              mock_execution_environment.should_receive(:play_numeric).with('123').and_return(true)
              mock_execution_environment.play('123').should be true
            end
          end

          describe "with a time" do
            let(:time) { Time.parse("12/5/2000") }

            it 'plays the time' do
              mock_execution_environment.should_receive(:play_time).with([time]).and_return(true)
              mock_execution_environment.play(time).should be true
            end
          end

          describe "with a date" do
            let(:date) { Date.parse('2011-01-23') }

            it 'plays the time' do
              mock_execution_environment.should_receive(:play_time).with([date]).and_return(true)
              mock_execution_environment.play(date).should be true
            end
          end

          describe "with an array containing a Date/DateTime/Time object and a hash" do
            it 'the SayUnixTime application will be executed with the object passed in with the specified format and timezone' do
              pending
              date, format = Date.parse('2011-01-23'), 'ABdY'
              mock_call.should_receive(:execute).once.with(:sayunixtime, date.to_time.to_i, "",format).and_return pbx_raw_response
              mock_call.play([date, {:format => format}]).should be true

              time, timezone = Time.at(1295843084), 'US/Eastern'
              mock_call.should_receive(:execute).once.with(:sayunixtime, time.to_i, timezone,'').and_return pbx_raw_response
              mock_call.play([time, {:timezone => timezone}]).should be true

              time, timezone, format = Time.at(1295843084), 'US/Eastern', 'ABdY \'digits/at\' IMp'
              mock_call.should_receive(:execute).once.with(:sayunixtime, time.to_i, timezone,format).and_return pbx_raw_response
              mock_call.play([time, {:timezone => timezone, :format => format}]).should be true
            end
          end

          it 'If a string matching dollars and (optionally) cents is passed to play(), a series of command will be executed to read the dollar amount', :ignore => true do
            pending "I think we should not have this be part of #play. Too much functionality in one method. Too much overloading. When we want to support multiple currencies, it'll be completely unwieldy. I'd suggest play_currency as a separate method. - Chad"
          end
        end

        describe "#speak" do
          describe "with a RubySpeech document" do
            it 'plays the correct SSML' do
              doc = RubySpeech::SSML.draw { "Hello world" }
              mock_execution_environment.should_receive(:play_ssml).once.with(doc, {}).and_return true
              mock_execution_environment.should_receive(:output).never
              mock_execution_environment.speak(doc).should be true
            end
          end

          describe "with a string" do
            it 'outputs the correct text' do
              string = "Hello world"
              mock_execution_environment.should_receive(:play_ssml).once.with(string, {})
              mock_execution_environment.should_receive(:output).once.with(:text, string, {}).and_return true
              mock_execution_environment.speak(string).should be true
            end
          end
        end

        describe "#raw_output" do
          pending
        end
      end
    end
  end
end
