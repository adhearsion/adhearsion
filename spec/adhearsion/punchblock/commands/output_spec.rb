require 'spec_helper'

module Punchblock
  module Component
    class Input
      def register_event_handler(method, &block)
        @input_handler = block 
      end
 
      def execute_handler
        possible_thread = @input_handler.call(Punchblock::Event::Complete.new)
        possible_thread.join if possible_thread.respond_to? :join
      end
    end
  end
end

module Adhearsion
  module Punchblock
    module Commands
      describe Output do
        include PunchblockCommandTestHelpers

        describe "#play_ssml" do
          let(:ssml) { RubySpeech::SSML.draw { string "BOO" } }

          it 'executes an Output with the correct ssml' do
            expect_component_execution Punchblock::Component::Output.new(:ssml => ssml.to_s)
            mock_execution_environment.play_ssml(ssml)
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

          describe "with a date and a say_as format" do
            let(:input) { Date.parse('2011-01-23') }
            let(:format) { "d-m-y" }
            let(:expected_say_as_options) { {:interpret_as => 'date', :format => format} }

            it 'plays the correct SSML' do
              mock_execution_environment.should_receive(:play_ssml).once.with(expected_doc).and_return true
              mock_execution_environment.play_time(input, :format => format).should be true
            end
          end

          describe "with a date and a strftime option" do
            let(:strftime) { "%d-%m-%Y" }
            let(:base_input) { Date.parse('2011-01-23') }
            let(:input) { base_input.strftime(strftime) }
            let(:expected_say_as_options) { {:interpret_as => 'date'} }

            it 'plays the correct SSML' do
              mock_execution_environment.should_receive(:play_ssml).once.with(expected_doc).and_return true
              mock_execution_environment.play_time(base_input, :strftime => strftime).should be true
            end
          end

          describe "with a date, a format option and a strftime option" do
            let(:strftime) { "%d-%m-%Y" }
            let(:format) { "d-m-y" }
            let(:base_input) { Date.parse('2011-01-23') }
            let(:input) { base_input.strftime(strftime) }
            let(:expected_say_as_options) { {:interpret_as => 'date', :format => format} }

            it 'plays the correct SSML' do
              mock_execution_environment.should_receive(:play_ssml).once.with(expected_doc).and_return true
              mock_execution_environment.play_time(base_input, :format => format, :strftime => strftime).should be true
            end
          end

          describe "with an object other than Time, DateTime, or Date" do
            let(:input) { "foo" }

            it 'returns false' do
              mock_execution_environment.play_time(input).should be false
            end
          end

        end

        describe '#play' do
          describe "with a single string" do
            let(:file) { "cents-per-minute" }

            it 'plays the audio file' do
              mock_execution_environment.should_receive(:play_ssml_for).once.with(file).and_return true
              mock_execution_environment.play(file).should be true
            end
          end

          describe "with multiple strings" do
            let(:args) { ['rock', 'paperz', 'scissors'] }

            it 'plays multiple files' do
              args.each do |file|
                mock_execution_environment.should_receive(:play_ssml_for).once.with(file).and_return true
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
              mock_execution_environment.should_receive(:play_ssml_for).with(123).and_return(true)
              mock_execution_environment.play(123).should be true
            end
          end

          describe "with a string representation of a number" do
            it 'plays the number' do
              mock_execution_environment.should_receive(:play_ssml_for).with('123').and_return(true)
              mock_execution_environment.play('123').should be true
            end
          end

          describe "with a time" do
            let(:time) { Time.parse("12/5/2000") }

            it 'plays the time' do
              mock_execution_environment.should_receive(:play_ssml_for).with(time).and_return(true)
              mock_execution_environment.play(time).should be true
            end
          end

          describe "with a date" do
            let(:date) { Date.parse('2011-01-23') }

            it 'plays the time' do
              mock_execution_environment.should_receive(:play_ssml_for).with(date).and_return(true)
              mock_execution_environment.play(date).should be true
            end
          end

          describe "with an array containing a Date/DateTime/Time object and a hash" do
            let(:date) { Date.parse('2011-01-23') }
            let(:format) { "d-m-y" }
            let(:strftime) { "%d-%m%Y" }

            it 'plays the time with the specified format and strftime' do
              mock_execution_environment.should_receive(:play_ssml_for).with(date, {:format => format, :strftime => strftime}).and_return(true)
              mock_execution_environment.play({:value => date, :format => format, :strftime => strftime}).should be true
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

        describe "#interruptible_play" do
          let(:ssml) { RubySpeech::SSML.draw {"press a button"} }
          let(:output_component) {
            Punchblock::Component::Output.new :ssml => ssml.to_s
          }
          let(:component) {
            Punchblock::Component::Input.new(
              {:mode => :dtmf,
               :grammar => {:value => '[1 DIGIT]', :content_type => 'application/grammar+voxeo'}
            })
          }
          let(:input_component) {
            Punchblock::Component::Input.new(
              {:mode => :dtmf,
               :initial_timeout => 2000,
               :inter_digit_timeout => 2000,
               :grammar => {:value => '[1 DIGIT]'}
            })
          }

          it "allows dtmf input to interrupt the playout and returns the value" do
            flexmock(Punchblock::Event::Complete).new_instances.should_receive(:reason => flexmock(:interpretation => '4', :name => :input))
            def mock_execution_environment.write_and_await_response(input_component)
              input_component.execute_handler
            end
            mock_execution_environment.should_receive(:execute_component_and_await_completion).once.with(output_component)
            mock_execution_environment.interruptible_play(ssml).should == '4'
          end

          it "allows dtmf input to interrupt the playout and return a multi digit value" do
            flexmock(Punchblock::Event::Complete).new_instances.should_receive(:reason => flexmock(:interpretation => '4', :name => :input))
            def mock_execution_environment.write_and_await_response(input_component)
              input_component.execute_handler
            end
            def mock_execution_environment.execute_component_and_await_completion(component)
              component.execute_handler if component.respond_to? :execute_handler 
            end
            mock_execution_environment.interruptible_play(ssml, :digits => 2).should == '44'
          end

          it "should not pause to try to read more digits if no input is received" do
            flexmock(Punchblock::Event::Complete).new_instances.should_receive(:reason => flexmock(:name => :noinput))
            def mock_execution_environment.write_and_await_response(input_component)
              input_component.execute_handler
            end
            mock_execution_environment.should_receive(:execute_component_and_await_completion).once.with(output_component)
            mock_execution_environment.interruptible_play(ssml, :digits => 2).should == nil
          end

          it "sends the correct input command" do
            pending
            #expect_message_waiting_for_response component
            #mock_execution_environment.interruptible_play(ssml)
          end
        end#describe #interruptible_play
        
        describe "#detect_type" do
          it "detects an HTTP path" do
            http_path = "http://adhearsion.com/sounds/hello.mp3"
            mock_execution_environment.detect_type(http_path).should be :file
          end
          it "detects a file path" do
            http_path = "/usr/shared/sounds/hello.mp3"
            mock_execution_environment.detect_type(http_path).should be :file
          end
          it "detects a Date object" do
            today = Date.today
            mock_execution_environment.detect_type(today).should be :time
          end
          it "detects a Time object" do
            now = Time.now
            mock_execution_environment.detect_type(now).should be :time
          end
          it "detects a DateTime object" do
            today = DateTime.now
            mock_execution_environment.detect_type(today).should be :time
          end
          it "detects a Numeric object" do
            number = 123
            mock_execution_environment.detect_type(number).should be :numeric
          end
          it "returns text as a fallback" do
            output = "Hello"
            mock_execution_environment.detect_type(output).should be :text
          end
        end
        
        describe "#raw_output" do
          pending
        end
      end
    end
  end
end
