require 'spec_helper'

module Adhearsion
  module Rayo
    describe Commands do
      include RayoCommandTestHelpers

      describe '#write' do
        it "writes a command to the call" do
          message = 'oh hai'
          flexmock(mock_execution_environment.call).should_receive(:write_command).once.with(message)
          mock_execution_environment.write message
        end
      end

      describe '#write_and_await_response' do
        let(:message) { Punchblock::Command::Accept.new }
        let(:response) { :foo }

        before do
          flexmock(message).should_receive(:execute!).and_return true
          message.response = response
        end

        it "writes a command to the call" do
          flexmock(mock_execution_environment).should_receive(:write).once.with(message)
          mock_execution_environment.write_and_await_response message
        end

        it "blocks until a response is received" do
          slow_command = Punchblock::Command::Dial.new
          Thread.new do
            sleep 0.5
            slow_command.response = response
          end
          starting_time = Time.now
          mock_execution_environment.write_and_await_response slow_command
          (Time.now - starting_time).should > 0.5
        end

        describe "with a successful response" do
          it "returns the executed command" do
            mock_execution_environment.write_and_await_response(message).should be message
          end
        end

        describe "with an error response" do
          let(:response) { Exception.new }

          it "raises the error" do
            lambda { mock_execution_environment.write_and_await_response message }.should raise_error(response)
          end
        end
      end

      describe "#execute_component_and_await_completion" do
        let(:component) { Punchblock::Component::Output.new }
        let(:response) { Punchblock::Event::Complete.new }

        before do
          expect_message_waiting_for_response component
          component.complete_event.resource = response
        end

        it "writes component to the server and waits on response" do
          mock_execution_environment.execute_component_and_await_completion component
        end

        describe "with a successful completion" do
          it "returns the executed component" do
            mock_execution_environment.execute_component_and_await_completion(component).should be component
          end
        end

        describe "with an error response" do
          let(:response) do
            Punchblock::Event::Complete.new.tap do |complete|
              complete << error
            end
          end

          let(:error) do |error|
            Punchblock::Event::Complete::Error.new.tap do |error|
              error << details
            end
          end

          let(:details) { "Oh noes, it's all borked" }

          it "raises the error" do
            lambda { mock_execution_environment.execute_component_and_await_completion component }.should raise_error(StandardError, details)
          end
        end

        it "blocks until the component receives a complete event" do
          slow_component = Punchblock::Component::Output.new
          Thread.new do
            sleep 0.5
            slow_component.complete_event.resource = response
          end
          starting_time = Time.now
          mock_execution_environment.execute_component_and_await_completion slow_component
          (Time.now - starting_time).should > 0.5
        end
      end

      def expect_message_waiting_for_response(message)
        mock_execution_environment.should_receive(:write_and_await_response).once.with(message).and_return(true)
      end

      def expect_component_execution(component)
        mock_execution_environment.should_receive(:execute_component_and_await_completion).once.with(component).and_return(true)
      end

      describe '#accept' do
        describe "with no headers" do
          it 'should send an Accept message' do
            expect_message_waiting_for_response Punchblock::Command::Accept.new
            mock_execution_environment.accept
          end
        end

        describe "with headers set" do
          it 'should send an Accept message with the correct headers' do
            headers = {:foo => 'bar'}
            expect_message_waiting_for_response Punchblock::Command::Accept.new(:headers => headers)
            mock_execution_environment.accept headers
          end
        end
      end

      describe '#answer' do
        describe "with no headers" do
          it 'should send an Answer message' do
            expect_message_waiting_for_response Punchblock::Command::Answer.new
            mock_execution_environment.answer
          end
        end

        describe "with headers set" do
          it 'should send an Answer message with the correct headers' do
            headers = {:foo => 'bar'}
            expect_message_waiting_for_response Punchblock::Command::Answer.new(:headers => headers)
            mock_execution_environment.answer headers
          end
        end
      end

      describe '#reject' do
        describe "with a reason given" do
          it 'should send a Reject message with the correct reason' do
            expect_message_waiting_for_response Punchblock::Command::Reject.new(:reason => :decline)
            mock_execution_environment.reject :decline
          end
        end

        describe "with no reason given" do
          it 'should send a Reject message with the reason busy' do
            expect_message_waiting_for_response Punchblock::Command::Reject.new(:reason => :busy)
            mock_execution_environment.reject
          end
        end

        describe "with no headers" do
          it 'should send a Reject message' do
            expect_message_waiting_for_response on { |c| c.is_a?(Punchblock::Command::Reject) && c.headers_hash == {} }
            mock_execution_environment.reject
          end
        end

        describe "with headers set" do
          it 'should send a Hangup message with the correct headers' do
            headers = {:foo => 'bar'}
            expect_message_waiting_for_response on { |c| c.is_a?(Punchblock::Command::Reject) && c.headers_hash == headers }
            mock_execution_environment.reject nil, headers
          end
        end
      end

      describe '#hangup' do
        describe "with no headers" do
          it 'should send a Hangup message' do
            expect_message_waiting_for_response Punchblock::Command::Hangup.new
            mock_execution_environment.hangup
          end
        end

        describe "with headers set" do
          it 'should send a Hangup message with the correct headers' do
            headers = {:foo => 'bar'}
            expect_message_waiting_for_response Punchblock::Command::Hangup.new(:headers => headers)
            mock_execution_environment.hangup headers
          end
        end
      end

      describe '#mute' do
        it 'should send a Mute message' do
          expect_message_waiting_for_response Punchblock::Command::Mute.new
          mock_execution_environment.mute
        end
      end

      describe '#unmute' do
        it 'should send an Unmute message' do
          expect_message_waiting_for_response Punchblock::Command::Unmute.new
          mock_execution_environment.unmute
        end
      end

      describe "#play_ssml" do
        let(:ssml) { RubySpeech::SSML.draw { string "BOO" } }

        it 'executes an Output with the correct ssml' do
          expect_component_execution Punchblock::Component::Output.new(:ssml => ssml)
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

      describe "#raw_output" do
        pending
      end

      describe "#raw_input" do
        pending
      end

      describe "#raw_record" do
        pending
      end
    end
  end
end
