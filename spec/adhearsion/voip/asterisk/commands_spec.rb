require 'spec_helper'
require 'adhearsion/voip/menu_state_machine/menu_class'
require 'adhearsion/voip/menu_state_machine/menu_builder'

module DialplanCommandTestHelpers
  def self.included(test_case)
    test_case.send(:attr_reader, :mock_call, :input, :output)

    test_case.before do
      Adhearsion::Configuration.configure { |config| config.enable_asterisk() }

      @input      = MockSocket.new
      @output     = MockSocket.new
      @mock_call  = Object.new
      @mock_call.metaclass.send(:attr_reader, :call)
      @mock_call.instance_variable_set(:@call, MockCall.new)
      mock_call.extend(Adhearsion::VoIP::Asterisk::Commands)
      flexmock(mock_call) do |call|
        call.should_receive(:from_pbx).and_return(input)
        call.should_receive(:to_pbx).and_return(output)
      end
    end

    test_case.after do
      pbx_output_should_be_empty
    end
  end

  class MockCall
    attr_accessor :variables

    def initialize 
      @variables = {}
    end

    def with_command_lock
      yield
    end
  end

  class MockSocket

    def empty?
      messages.empty?
    end

    def print(message)
      messages << message
    end

    def puts(message)
      messages << message.chomp + "\n"
    end

    def read
      messages.shift
    end

    def gets
      read
    end

    def messages
      @messages ||= []
    end
  end


  private

    def should_pass_control_to_a_context_that_throws(symbol, &block)
      did_the_rescue_block_get_executed = false
      begin
        yield
      rescue Adhearsion::VoIP::DSL::Dialplan::ControlPassingException => cpe
        did_the_rescue_block_get_executed = true
        cpe.target.should throw_symbol symbol
      rescue => e
        did_the_rescue_block_get_executed = true
        raise e
      ensure
        did_the_rescue_block_get_executed.should be true
      end
    end

    def should_throw(sym=nil,&block)
      block.should throw_symbol(*[sym].compact)
    end

    def mock_route_calculation_with(*definitions)
      flexmock(Adhearsion::VoIP::DSL::DialingDSL).should_receive(:calculate_routes_for).and_return(definitions)
    end

    def pbx_should_have_been_sent(message)
      output.gets.chomp.should == message
    end

    def pbx_should_respond_with(message)
      input.print message
    end

    def pbx_should_respond_with_digits(string_of_digits)
      pbx_should_respond_with "200 result=#{string_of_digits}"
    end

    def pbx_should_respond_with_digits_and_timeout(string_of_digits)
      pbx_should_respond_with "200 result=#{string_of_digits} (timeout)"
    end

    def pbx_should_respond_to_timeout(timeout)
      pbx_should_respond_with "200 result=#{timeout}"
    end

    def pbx_should_respond_with_value(value)
      pbx_should_respond_with pbx_value_response value
    end

    def pbx_should_respond_with_success(success_code = nil)
      pbx_should_respond_with pbx_success_response(success_code)
    end
    alias does_not_read_data_back pbx_should_respond_with_success

    def pbx_should_respond_with_failure(failure_code = nil)
      pbx_should_respond_with(pbx_failure_response(failure_code))
    end

    def pbx_should_respond_with_successful_background_response(digit=0)
      pbx_should_respond_with_success digit.kind_of?(String) ? digit[0] : digit
    end

    def pbx_should_respond_with_playback_success
      pbx_should_respond_with pbx_raw_response
      mock_call.should_receive(:get_variable).once.with('PLAYBACKSTATUS').and_return 'SUCCESS'
    end

    def pbx_should_respond_with_playback_failure
      pbx_should_respond_with pbx_raw_response
      mock_call.should_receive(:get_variable).once.with('PLAYBACKSTATUS').and_return 'FAILED'
    end

    def pbx_should_respond_with_stream_file_success(success_code = nil, endpos = '20000')
      pbx_should_respond_with pbx_raw_stream_file_response(success_code, endpos)
    end

    def pbx_should_respond_with_stream_file_failure_on_open(endpos = nil)
      pbx_should_respond_with pbx_raw_stream_file_response(nil, endpos)
    end

    def pbx_should_respond_with_a_wait_for_digit_timeout
      pbx_should_respond_with_successful_background_response 0
    end

    def pbx_success_response(success_code = nil)
      "200 result=#{success_code || default_success_code}"
    end

    def pbx_raw_response(code = nil)
      "200 result=#{code || default_code}\n"
    end

    def pbx_raw_stream_file_response(code = nil, endpos = nil)
      "200 result=#{code || default_code} endpos=#{endpos || default_code}\n"
    end

    def pbx_value_response(value)
      "200 result=1 (#{value})"
    end

    def pbx_result_response(value)
      "200 result=#{value.ord}"
    end

    def default_success_code
      '1'
    end

    def default_code
      '0'
    end

    def pbx_failure_response(failure_code = nil)
      "200 result=#{failure_code || default_failure_code}"
    end

    def default_failure_code
      '-1'
    end

    def output_stream_matches(pattern)
      output.gets.should match pattern
    end

    module OutputStreamMatchers
      def pbx_was_asked_to_play(*audio_files)
        audio_files.flatten.each do |audio_file|
          output_stream_matches(/playback "#{audio_file}"/)
        end
      end

      def pbx_was_asked_to_play_number(number)
        output_stream_matches(/saynumber "#{number}"/)
      end

      def pbx_was_asked_to_play_time(number)
        output_stream_matches(/sayunixtime "#{number}"/)
      end

      def pbx_was_asked_to_stream(*audio_files)
        audio_files.flatten.each do |audio_file|
          output_stream_matches /^STREAM FILE "#{audio_file}" "1234567890\*#"\n$/
        end
      end

      def pbx_was_asked_to_execute(application, *options)
        output_stream_matches(/exec saydigits "#{options.join('|')}"/i)
      end

      def pbx_output_should_be_empty
        output.messages.should be_empty, output.messages.inspect
      end
    end
    include OutputStreamMatchers

    def assert_success(response)
      response.should == pbx_success_response
    end

end


module MenuBuilderTestHelper
  def builder_should_match_with_these_quantities_of_calculated_matches(checks)
    checks.each do |check,hash|
      hash.each_pair do |method_name,intended_quantity|
        builder.calculate_matches_for(check).send(method_name).should == intended_quantity
      end
    end
  end
end

module MenuTestHelper

  def pbx_should_send_digits(*digits)
    digits.each do |digit|
      digit = nil if digit == :timeout
      mock_call.should_receive(:interruptible_play).once.and_return(digit)
    end
  end
end

module ConfirmationManagerTestHelper
  def encode_hash(hash)
    Adhearsion::DialPlan::ConfirmationManager.encode_hash_for_dial_macro_argument(hash)
  end
end

describe 'Asterisk VoIP Commands' do
  include DialplanCommandTestHelpers

  it "a call can write back to the PBX" do
    message = 'oh hai'
    mock_call.write message
    pbx_should_have_been_sent message
  end
end
describe 'hangup command' do
  include DialplanCommandTestHelpers

  it "hanging up a call succesfully writes HANGUP back to the PBX and a success resopnse is returned" do
    pbx_should_respond_with_success
    response = mock_call.hangup
    pbx_should_have_been_sent 'HANGUP'
    response.should == pbx_success_response
  end
end

describe 'receiving a hangup' do
  include DialplanCommandTestHelpers

  it "should treat a ECONNRESET as a hangup" do
    pbx_should_respond_with_success
    def input.gets()
      raise Errno::ECONNRESET
    end
    the_following_code {
      mock_call.read()
    }.should raise_error(Adhearsion::Hangup)   
  end
end

describe "writing a command" do
  include DialplanCommandTestHelpers

  it "should strip out excess whitespace" do
    pbx_should_respond_with_success
    mock_call.should_receive(:write).with "EXEC Ringing"
    mock_call.raw_response "EXEC   \nRinging\n\n"
  end
end

describe 'The #interruptible_play method' do

  include DialplanCommandTestHelpers

  it 'should return a string for the digit that was pressed' do
    digits = %w{0 1 # * 9}.map{|c| c.ord}
    file = "file_doesnt_matter"
    digits.each { |digit| pbx_should_respond_with_stream_file_success digit }
    digits.map  { |digit| mock_call.interruptible_play file }.should == digits.map(&:chr)
    digits.size.times { pbx_was_asked_to_stream file }
  end

  it "should return nil if no digit was pressed" do
    pbx_should_respond_with_stream_file_success 0
    file = 'foobar'
    mock_call.interruptible_play(file).should be nil
    pbx_was_asked_to_stream file
  end

  it 'should return nil if no digit was pressed, even if the sound file is not found' do
    pbx_should_respond_with_stream_file_failure_on_open
    file = 'foobar'
    mock_call.interruptible_play(file).should be nil
    pbx_was_asked_to_stream file
  end

  it "should play a series of files, stopping the series when a digit is played" do
    stubbed_keypad_input = [0, 0, ?3.ord]
    stubbed_keypad_input.each do |digit|
      pbx_should_respond_with_stream_file_success digit
    end

    play_files = (100..105).map &:to_s
    played_files = (100..102).map &:to_s
    mock_call.interruptible_play(*play_files).should == '3'
    pbx_was_asked_to_stream played_files
  end

  it 'should play a series of files, stopping the series when a digit is played, even if the sound files cannot be found' do
    pbx_should_respond_with_stream_file_success 0
    pbx_should_respond_with_stream_file_success 0
    pbx_should_respond_with_stream_file_failure_on_open
    pbx_should_respond_with_stream_file_success ?9.ord

    play_files = ('sound1'..'sound6').map &:to_s
    played_files = ('sound1'..'sound4').map &:to_s
    mock_call.interruptible_play(*play_files).should == '9'
    pbx_was_asked_to_stream played_files
  end
end

describe 'The #interruptible_play! method' do
  include DialplanCommandTestHelpers

  it 'should return a string for the digit that was pressed' do
    digits = %w{0 1 # * 9}.map{|c| c.ord}
    file = "file_doesnt_matter"
    digits.each { |digit| pbx_should_respond_with_stream_file_success digit }
    digits.map  { |digit| mock_call.interruptible_play! file }.should == digits.map(&:chr)
    digits.size.times { pbx_was_asked_to_stream file }
  end

  it "should return nil if no digit was pressed" do
    pbx_should_respond_with_stream_file_success 0
    file = 'foobar'
    mock_call.interruptible_play!(file).should be nil
    pbx_was_asked_to_stream file
  end

  it 'should raise an error when the sound file is not found' do
    pbx_should_respond_with_stream_file_failure_on_open
    file = 'foobar'
    the_following_code {
      mock_call.interruptible_play! file
    }.should raise_error Adhearsion::VoIP::PlaybackError
    pbx_was_asked_to_stream file
  end

  it "should play a series of files, stopping the series when a digit is played" do
    stubbed_keypad_input = [0, 0, ?3.ord]
    stubbed_keypad_input.each do |digit|
      pbx_should_respond_with_stream_file_success digit
    end

    play_files = (100..105).map &:to_s
    played_files = (100..102).map &:to_s
    mock_call.interruptible_play!(*play_files).should == '3'
    pbx_was_asked_to_stream played_files
  end

  it 'should play a series of files, raising an error if a sound file cannot be found' do
    pbx_should_respond_with_stream_file_success 0
    pbx_should_respond_with_stream_file_failure_on_open

    play_files = ('sound1'..'sound6').map &:to_s
    played_files = ('sound1'..'sound2').map &:to_s
    the_following_code {
      mock_call.interruptible_play! *play_files
    }.should raise_error Adhearsion::VoIP::PlaybackError
    pbx_was_asked_to_stream played_files
  end

  it 'should raise an error if an audio file cannot be found' do
    pbx_should_respond_with_stream_file_failure_on_open
    audio_file = 'nixon-tapes'
    the_following_code {
      mock_call.interruptible_play! audio_file
    }.should raise_error Adhearsion::VoIP::PlaybackError
    pbx_was_asked_to_stream audio_file
  end

  it 'should raise an error when audio files cannot be found' do
    pbx_should_respond_with_stream_file_success
    pbx_should_respond_with_stream_file_failure_on_open # 'paperz' is the only audio that is missing
    audio_files = ['rock', 'paperz', 'scissors']

    the_following_code {
      mock_call.interruptible_play! audio_files
    }.should raise_error Adhearsion::VoIP::PlaybackError
    pbx_was_asked_to_stream ['rock', 'paperz'] # stop short before playing with scissors!
  end
end

describe 'The #wait_for_digit method' do

  include DialplanCommandTestHelpers

  it 'should return a string for the digit that was pressed' do
    digits = %w{0 1 # * 9}.map{|c| c.ord}
    digits.each { |digit| pbx_should_respond_with_success digit }
    digits.map  { |digit| mock_call.send(:wait_for_digit) }.should == digits.map(&:chr)
    digits.size.times { pbx_should_have_been_sent 'WAIT FOR DIGIT "-1"' }
  end

  it "the timeout given must be converted to milliseconds" do
    pbx_should_respond_with_success 0
    mock_call.send(:wait_for_digit, 1)
    pbx_should_have_been_sent 'WAIT FOR DIGIT "1000"'
  end
end

describe 'The #answer method' do
  include DialplanCommandTestHelpers

  it 'should send ANSWER over the AGI socket' do
    does_not_read_data_back
    mock_call.answer
    pbx_should_have_been_sent 'ANSWER'
  end

end

describe 'The #execute method' do
  include DialplanCommandTestHelpers

  it 'execute writes exec and app name to the PBX' do
    pbx_should_respond_with_success
    assert_success mock_call.execute(:foo)
    pbx_should_have_been_sent 'EXEC foo'
  end

  it 'execute returns false if the command was not executed successfully by the PBX' do
    pbx_should_respond_with_failure
    mock_call.execute(:foo).should_not be true
    pbx_should_have_been_sent 'EXEC foo'
  end

  it 'execute can accept arguments after the app name which get translated into pipe-delimited arguments to the PBX' do
    pbx_should_respond_with_success
    mock_call.execute :foo, 'bar', 'baz', 'hi'
    pbx_should_have_been_sent 'EXEC foo "bar"|"baz"|"hi"'
  end

  it "should raise a Hangup exception when nil is returned when reading a command from Asterisk" do
    flexmock(input).should_receive(:gets).once.and_return nil
    the_following_code {
      mock_call.execute :foo, "bar"
    }.should raise_error Adhearsion::Hangup
    pbx_should_have_been_sent 'EXEC foo "bar"'
  end

  it "should raise a ArgumentError if given a null byte in the arguments" do
    the_following_code {
      mock_call.execute :foo, "bar\0"
    }.should raise_error ArgumentError
  end
end

describe 'The #inline_return_value method' do
  include DialplanCommandTestHelpers

  it 'should return nil when given false or nil' do
    mock_call.inline_return_value(false).should be nil
    mock_call.inline_return_value(nil).should be nil
  end

  it 'should return nil when given an empty AGI value (0)' do
    mock_call.inline_return_value(pbx_result_response(0)).should be nil
  end


  it 'should raise AGIProtocolError with an invalid response' do
    expect {
      mock_call.inline_return_value("500 result=foo\n")
    }.to raise_error Adhearsion::VoIP::Asterisk::AGIProtocolError

    expect {
      mock_call.inline_return_value('Hey man, not so loud!')
    }.to raise_error Adhearsion::VoIP::Asterisk::AGIProtocolError
  end

  it 'should parse the return value' do
    mock_call.inline_return_value(pbx_result_response(5)).should == '5'
  end
end

describe 'The #inline_result_with_return_value method' do
  include DialplanCommandTestHelpers

  it 'should return nil when given false or nil' do
    mock_call.inline_result_with_return_value(false).should be nil
    mock_call.inline_result_with_return_value(nil).should be nil
  end

  it 'should return nil when given an empty AGI value (0)' do
    mock_call.inline_result_with_return_value(pbx_result_response(0)).should be nil
  end

  it 'should raise AGIProtocolError with an invalid response' do
    expect {
      mock_call.inline_result_with_return_value("500 result=1 (foo)\n")
    }.to raise_error Adhearsion::VoIP::Asterisk::AGIProtocolError

    expect {
      mock_call.inline_result_with_return_value('Hey man, not so loud!')
    }.to raise_error Adhearsion::VoIP::Asterisk::AGIProtocolError
  end

  it 'should parse the return value' do
    mock_call.inline_result_with_return_value(pbx_value_response(5)).should == '5'
  end
end

describe 'The #play_or_speak method' do
  include DialplanCommandTestHelpers

  it 'should play a sound file if one exists' do
    pbx_should_respond_with_playback_success
    audio_file = "cents-per-minute"
    mock_call.play_or_speak({audio_file => {}}).should be nil
    pbx_was_asked_to_play audio_file
  end

  it 'should play a sound file via interruptible_play if file exists and interrupbible set and return key pressed and return the key press value' do
    audio_file = "cents-per-minute"
    mock_call.should_receive(:interruptible_play!).with(audio_file).once.and_return '#'
    mock_call.play_or_speak({audio_file => {:interruptible => true}}).should == '#'
  end

  it 'should play a sound file via interruptible_play if file exists and interrupbible set' do
    audio_file = "cents-per-minute"
    mock_call.should_receive(:interruptible_play!).with(audio_file).once.and_return nil
    mock_call.play_or_speak({audio_file => {:interruptible => true}}).should == nil
  end

  it 'should raise and error if a sound file does not exist and there is not text specified to fall back to' do
    audio_file = "nixon tapes"
    mock_call.should_receive(:play!).with(audio_file).and_raise Adhearsion::VoIP::PlaybackError
    the_following_code {
          mock_call.play_or_speak({audio_file => { :engine => :unimrcp}})
    }.should raise_error ArgumentError
  end

  it 'should not send the command to play if the audio file is blank' do
    mock_call.should_receive(:speak).with('hello', {:engine=>:unimrcp}).once.and_return nil
    mock_call.play_or_speak({'' => { :text => 'hello', :engine => :unimrcp }}).should be nil
  end

  it 'should not send the command to play if the audio file is nil' do
    mock_call.should_receive(:speak).with('hello', {:engine=>:unimrcp}).once.and_return nil
    mock_call.play_or_speak({nil => { :text => 'hello', :engine => :unimrcp }}).should be nil
  end

  it 'should speak the text if a sound file does not exist' do
    audio_file = "nixon tapes"
    mock_call.should_receive(:play!).with(audio_file).and_raise Adhearsion::VoIP::PlaybackError
    mock_call.should_receive(:speak).with('hello', {:engine=>:unimrcp}).once.and_return nil
    mock_call.play_or_speak({audio_file => { :text => 'hello', :engine => :unimrcp }}).should be nil
  end

  it 'should speak the text if a sound file does not exist and pass back the entered text if a key is pressed' do
    audio_file = "nixon tapes"
    mock_call.should_receive(:interruptible_play!).with(audio_file).and_raise Adhearsion::VoIP::PlaybackError
    mock_call.should_receive(:speak).with('hello', {:engine=>:unimrcp, :interruptible => true}).once.and_return '5'
    mock_call.play_or_speak({audio_file => { :text => 'hello', :engine => :unimrcp, :interruptible => true
}}).should == '5'
  end

end

describe 'The #play method' do
  include DialplanCommandTestHelpers

  it 'passing a single string to play results in the playback application being executed with that file name on the PBX' do
    pbx_should_respond_with_playback_success
    audio_file = "cents-per-minute"
    mock_call.play(audio_file).should be true
    pbx_was_asked_to_play audio_file
  end

  it 'multiple strings can be passed to play, causing multiple playback commands to be issued' do
    2.times do
      pbx_should_respond_with_playback_success
    end
    audio_files = ["cents-per-minute", 'o-hai']
    mock_call.play(audio_files).should be true
    pbx_was_asked_to_play audio_files
  end

  it 'should return false if an audio file cannot be found' do
    pbx_should_respond_with_playback_failure
    audio_file = 'nixon-tapes'
    mock_call.play(audio_file).should be false
    pbx_was_asked_to_play audio_file
  end

  it 'should return false when audio files cannot be found' do
    pbx_should_respond_with_playback_success
    pbx_should_respond_with_playback_failure # 'paperz' is the only audio that is missing
    pbx_should_respond_with_playback_success
    audio_files = ['rock', 'paperz', 'scissors']

    mock_call.play(audio_files).should be false
    pbx_was_asked_to_play audio_files
  end

  it 'If a number is passed to play(), the saynumber application is executed with the number as an argument' do
    pbx_should_respond_with_success
    mock_call.play(123).should be true
    pbx_was_asked_to_play_number(123)
  end

  it 'if a string representation of a number is passed to play(), the saynumber application is executed with the number as an argument' do
    pbx_should_respond_with_success
    mock_call.play('123').should be true
    pbx_was_asked_to_play_number(123)
  end

  it 'If a Time is passed to play(), the SayUnixTime application will be executed with the time since the UNIX epoch in seconds as an argument' do
    time = Time.parse("12/5/2000")
    pbx_should_respond_with_success
    mock_call.play(time).should be true
    pbx_was_asked_to_play_time(time.to_i)
  end

  it 'If a Date is passed to play(), the SayUnixTime application will be executed with the date passed in' do
    date = Date.parse('2011-01-23')
    mock_call.should_receive(:execute).once.with(:sayunixtime, date.to_time.to_i, "",'BdY').and_return pbx_raw_response
    mock_call.play(date).should be true
  end

  it 'If a Date or Time is passed to play_time(), the SayUnixTime application will be executed with the date and format passed in' do
    date, format = Date.parse('2011-01-23'), 'ABdY'
    mock_call.should_receive(:execute).once.with(:sayunixtime, date.to_time.to_i, "",format).and_return "200 result=0\n"
    mock_call.play_time(date, :format => format).should == pbx_raw_response

    time, format = Time.at(875121313), 'BdY \'digits/at\' IMp'
    mock_call.should_receive(:execute).once.with(:sayunixtime, time.to_i, "",format).and_return pbx_raw_response
    mock_call.play_time(time, :format => format).should == pbx_raw_response
  end

  it 'If a Time object is passed to play_time, the SayUnixTime application will be executed with the default parameters' do
    time = Time.at(875121313)
    mock_call.should_receive(:execute).once.with(:sayunixtime, time.to_i, "",'').and_return pbx_raw_response
    mock_call.play_time(time).should == pbx_raw_response
  end

  it 'If an object other than Time, DateTime, or Date is passed to play_time false will be returned' do
    non_time = 'blah'
    mock_call.play_time(non_time).should be false
  end

  it 'If an array containing a Date/DateTime/Time object and a hash is passed to play(), the SayUnixTime application will be executed with the object passed in with the specified format and timezone' do
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

   it 'If a string matching dollars and (optionally) cents is passed to play(), a series of command will be executed to read the dollar amount', :ignore => true do
    #TODO: I think we should not have this be part of play().  Too much functionality in one method. Too much overloading.  When we want to support multiple
    # currencies, it'll be completely unwieldy.  I'd suggest play_currency as a separate method. - Chad
  end
end

describe 'The #play! method' do
  include DialplanCommandTestHelpers

  it 'should accept multiple strings to play, causing multiple playback commands to be issued' do
    2.times do
      pbx_should_respond_with_playback_success
    end
    audio_files = ["cents-per-minute", 'o-hai']
    mock_call.play!(audio_files).should be true
    pbx_was_asked_to_play audio_files
  end

  it 'should raise an error if an audio file cannot be found' do
    pbx_should_respond_with_playback_failure
    audio_file = 'nixon-tapes'
    the_following_code {
      mock_call.play! audio_file
    }.should raise_error Adhearsion::VoIP::PlaybackError
    pbx_was_asked_to_play audio_file
  end

  it 'should raise an error when audio files cannot be found' do
    pbx_should_respond_with_playback_success
    pbx_should_respond_with_playback_failure # 'paperz' is the only audio that is missing
    audio_files = ['rock', 'paperz', 'scissors']

    the_following_code {
      mock_call.play! audio_files
    }.should raise_error Adhearsion::VoIP::PlaybackError
    pbx_was_asked_to_play ['rock', 'paperz'] # stop short before playing with scissors!
  end
end

describe 'the #record method' do
  include DialplanCommandTestHelpers

  it 'should return the recorded file name if the user hangs up during the recording' do
    mock_call.should_receive(:response).once.with('RECORD FILE', 'foo', 'gsm', '#', -1, 0, 'BEEP').and_return("200 result=-1 (hangup) endpos=167840\n")
    mock_call.record('foo').should == 'foo.gsm'
  end

  it 'create a default filename if no file is specifed and icrement it on subsequent calls' do
    mock_call.call.variables.delete :recording_counter
    mock_call.should_receive(:new_guid).once.and_return('2345')
    mock_call.should_receive(:new_guid).once.and_return('4322')
    mock_call.should_receive(:response).once.with('RECORD FILE', '/tmp/recording_2345_0', 'gsm', '26', -1, 0).and_return("200 result=0 (timeout) endpos=21600\n")
    mock_call.should_receive(:response).once.with('RECORD FILE', '/tmp/recording_4322_1', 'gsm', '26', -1, 0).and_return("200 result=0 (timeout) endpos=21600\n")
    mock_call.record(:beep => nil, :escapedigits => '26').should == '/tmp/recording_0.gsm'
    mock_call.record(:beep => nil, :escapedigits => '26').should == '/tmp/recording_1.gsm'
  end  

  it 'determine the format from the filename' do
    mock_call.should_receive(:response).once.with('RECORD FILE', 'foo', 'wav', '26', -1, 0).and_return("200 result=0 (timeout) endpos=21600\n")
    mock_call.record('foo.wav', :beep => nil, :escapedigits => '26').should == 'foo.wav'
  end  

  it 'set the format of a file via the :format option' do
    mock_call.should_receive(:response).once.with("RECORD FILE", "foo", "wav", "#", 2000, 0).and_return("200 result=0 (timeout) endpos=21600\n")
    mock_call.record('foo', :beep => nil, :maxduration => 2, :format => 'wav').should == 'foo.wav'
  end  

  it 'set the format of a file via the :format option over-riding a implicit format' do
    mock_call.should_receive(:response).once.with("RECORD FILE", "foo.wav", "mpeg", "#", 2000, 0).and_return("200 result=0 (timeout) endpos=21600\n")
    mock_call.record('foo.wav', :beep => nil, :maxduration => 2, :format => 'mpeg').should == 'foo.wav.mpeg'
  end  
end

describe 'the #record_to_file method' do
  include DialplanCommandTestHelpers

  it 'should return :hangup if the user hangs up during the recording' do
    mock_call.should_receive(:response).once.with("RECORD FILE", "foo", "gsm", "#", -1, 0, "BEEP").and_return("200 result=-1 (hangup) endpos=167840\n")
    mock_call.record_to_file('foo')[:status].should == :hangup
  end

  it 'should return :write error if the recording had a problem writing the file' do
    mock_call.should_receive(:response).once.with("RECORD FILE", "foo", "gsm", "#", -1, 0, "BEEP").and_return("200 result=-1 (writefile) endpos=167840\n")
    mock_call.record_to_file('foo')[:status].should == :write_error
  end  

  it 'should return :success_dtmf if the recording was completed successfully with a dtmf tone to end' do
    mock_call.should_receive(:response).once.with("RECORD FILE", "foo", "gsm", "#", -1, 0, "BEEP").and_return("200 result=35 (dtmf) endpos=29120\n")
    mock_call.record_to_file('foo')[:status].should == :success_dtmf
  end  

  it 'should return the dtmf tone if the recording was completed successfully with a dtmf tone to end' do
    mock_call.should_receive(:response).once.with("RECORD FILE", "foo", "gsm", "#", -1, 0, "BEEP").and_return("200 result=35 (dtmf) endpos=29120\n")
    mock_call.record_to_file('foo')[:dtmf].should == '#'
  end  

  it 'should return :success_timeout if the recording was completed successfully by timing out with silence' do
    mock_call.should_receive(:response).once.with("RECORD FILE", "foo", "gsm", "#", -1, 0, "BEEP").and_return("200 result=0 (timeout) endpos=21600\n")
    mock_call.record_to_file('foo')[:status].should == :success_timeout
  end  

  it 'not send a beep if a :beep=>nil is passed in' do
    mock_call.should_receive(:response).once.with("RECORD FILE", "foo", "gsm", "#", -1, 0).and_return("200 result=0 (timeout) endpos=21600\n")
    mock_call.record_to_file('foo', :beep => nil)[:status].should == :success_timeout
  end  

  it 'set the silence if it is passed in' do
    mock_call.should_receive(:response).once.with("RECORD FILE", "foo", "gsm", "#", -1, 0, 's=2').and_return("200 result=0 (timeout) endpos=21600\n")
    mock_call.record_to_file('foo', :beep => nil, :silence => 2)[:status].should == :success_timeout
  end  

  it 'set the maxduration if it is passed in' do
    mock_call.should_receive(:response).once.with("RECORD FILE", "foo", "gsm", "#", 2000, 0).and_return("200 result=0 (timeout) endpos=21600\n")
    mock_call.record_to_file('foo', :beep => nil, :maxduration => 2)[:status].should == :success_timeout
  end  

  it 'set the format of a file via the :format option' do
    mock_call.should_receive(:response).once.with("RECORD FILE", "foo", "wav", "#", 2000, 0).and_return("200 result=0 (timeout) endpos=21600\n")
    mock_call.record_to_file('foo', :beep => nil, :maxduration => 2, :format => 'wav')[:status].should == :success_timeout
  end  

  it 'set the format of a file via the :format option over-riding a implicit format' do
    mock_call.should_receive(:response).once.with("RECORD FILE", "foo.wav", "mpeg", "#", 2000, 0).and_return("200 result=0 (timeout) endpos=21600\n")
    mock_call.record_to_file('foo.wav', :beep => nil, :maxduration => 2, :format => 'mpeg')[:status].should == :success_timeout
  end  

  it 'set the escapedigits if it is passed in' do
    mock_call.should_receive(:response).once.with("RECORD FILE", "foo", "gsm", "26", -1, 0).and_return("200 result=0 (timeout) endpos=21600\n")
    mock_call.record_to_file('foo', :beep => nil, :escapedigits => '26')[:status].should == :success_timeout
  end  

  it 'play a passed in beep file if it is passed in' do
    mock_call.should_receive(:execute).once.with(:playback, 'my_awesome_beep.wav').and_return(true)
    pbx_should_respond_with_playback_success
    pbx_should_respond_with_playback_success
    mock_call.should_receive(:response).once.with("RECORD FILE", "foo", "gsm", "26", -1, 0).and_return("200 result=0 (timeout) endpos=21600\n")
    mock_call.record_to_file('foo', :beep => 'my_awesome_beep.wav', :escapedigits => '26')[:status].should == :success_timeout
  end  

  it "should silently fail if the beep file passed in can't be played" do
    mock_call.should_receive(:execute).once.with(:playback, 'my_awesome_beep.wav').and_return(true)
    pbx_should_respond_with_playback_failure
    pbx_should_respond_with_playback_failure
    mock_call.should_receive(:response).once.with("RECORD FILE", "foo", "gsm", "26", -1, 0).and_return("200 result=0 (timeout) endpos=21600\n")
    mock_call.record_to_file('foo', :beep => 'my_awesome_beep.wav', :escapedigits => '26')[:status].should == :success_timeout
  end  

  it 'determine the format from the filename' do
    mock_call.should_receive(:response).once.with("RECORD FILE", "foo", "wav", "26", -1, 0).and_return("200 result=0 (timeout) endpos=21600\n")
    mock_call.record_to_file('foo.wav', :beep => nil, :escapedigits => '26')[:status].should == :success_timeout
  end  

  it 'create a default filename if no file is specifed and icrement it on subsequent calls' do
    mock_call.should_receive(:new_guid).once.and_return('2345')
    mock_call.should_receive(:new_guid).once.and_return('4322')
    mock_call.should_receive(:response).once.with("RECORD FILE", "/tmp/recording_2345_0", "gsm", "26", -1, 0).and_return("200 result=0 (timeout) endpos=21600\n")
    mock_call.should_receive(:response).once.with("RECORD FILE", "/tmp/recording_4322_1", "gsm", "26", -1, 0).and_return("200 result=0 (timeout) endpos=21600\n")
    mock_call.record_to_file(:beep => nil, :escapedigits => '26')[:status].should == :success_timeout
    mock_call.record_to_file(:beep => nil, :escapedigits => '26')[:status].should == :success_timeout
  end  
end

describe 'The #record_to_file! method' do
  include DialplanCommandTestHelpers

  it "should throw an exception the beep file passed in can't be played" do
    mock_call.should_receive(:execute).once.with(:playback, 'my_awesome_beep.wav').and_return(false)
    pbx_should_respond_with_playback_failure
    pbx_should_respond_with_playback_failure
    mock_call.should_receive(:response).once.with("RECORD FILE", "foo", "gsm", "26", -1, 0).and_return("200 result=0 (timeout) endpos=21600\n")
    the_following_code {
      mock_call.record_to_file!('foo', :beep => 'my_awesome_beep.wav', :escapedigits => '26')[:status].should == :success_timeout
    }.should raise_error Adhearsion::VoIP::PlaybackError
  end  

  it 'should throw RecordError if the recording had a problem writing the file' do
    mock_call.should_receive(:response).once.with("RECORD FILE", "foo", "gsm", "#", -1, 0, "BEEP").and_return("200 result=-1 (writefile) endpos=167840\n")
    the_following_code {
      mock_call.record_to_file!('foo')[:status].should == :write_error
    }.should raise_error Adhearsion::VoIP::RecordError
  end  

  it 'should be able get a response from a successfull call' do
    mock_call.should_receive(:response).once.with("RECORD FILE", "foo", "wav", "26", -1, 0).and_return("200 result=0 (timeout) endpos=21600\n")
    mock_call.record_to_file!('foo.wav', :beep => nil, :escapedigits => '26')[:status].should == :success_timeout
  end  
end

describe 'The #input method' do

  include DialplanCommandTestHelpers

  it 'should raise an error when the number of digits expected is -1 (this is deprecated behavior)' do
    the_following_code {
      mock_call.input(-1)
    }.should raise_error ArgumentError
  end

  it 'input() calls wait_for_digit the specified number of times (when no sound files are given)' do
    mock_call.should_receive(:interruptible_play!).never
    mock_call.should_receive(:wait_for_digit).times(4).and_return('1', '2', '3', '4')
    mock_call.input(4).should == '1234'
  end

  it 'should execute wait_for_digit if no digit is pressed during interruptible_play!' do
    sound_files = %w[one two three]
    mock_call.should_receive(:interruptible_play!).once.with('one').and_return nil
    mock_call.should_receive(:interruptible_play!).once.with('two').and_return nil
    mock_call.should_receive(:interruptible_play!).once.with('three').and_return nil
    mock_call.should_receive(:wait_for_digit).once.and_throw :digit_request
    should_throw(:digit_request) { mock_call.input(10, :play => sound_files) }
  end

  it 'should default the :accept_key to "#" when unlimited digits are to be collected' do
    mock_call.should_receive(:wait_for_digit).times(2).and_return '*', '#'
    mock_call.input.should == '*'
  end

  it 'should raise an exception when unlimited digits are to be collected and :accept_key => false' do
    flexstub(mock_call).should_receive(:read).and_return
    the_following_code {
      mock_call.input(:accept_key => false)
    }.should raise_error ArgumentError
    pbx_should_have_been_sent 'WAIT FOR DIGIT "-1"'
  end

  it 'when :accept_key is false and input() is collecting a finite number of digits, it should allow all DTMFs' do
    all_digits = %w[0 1 2 3 # * 4 5 6 7 8 9]
    mock_call.should_receive(:wait_for_digit).times(all_digits.size).and_return(*all_digits)
    the_following_code {
      mock_call.input(all_digits.size, :accept_key => false)
    }.should_not raise_error ArgumentError
  end

  it 'should terminate early when the passed block returns something truthy' do
    three_digits = %w[9 3 0]
    mock_call.should_receive(:wait_for_digit).times(2).and_return(*three_digits)
    mock_call.input(3, :accept_key => false) { |buffer| buffer.size == 2 }.should == '93'
  end

  it "Input timing out when digits are pressed returns only the collected digits" do
    timeout = 1.day
    mock_call.should_receive(:wait_for_digit).twice.with(timeout).and_return '5', nil
    mock_call.input(9, :timeout => timeout).should == '5'
  end

  it 'passes wait_for_digit the :timeout option when one is given' do
    mock_call.should_receive(:interruptible_play!).never
    mock_call.should_receive(:wait_for_digit).twice.and_return '1', '2'
    mock_call.input(2, :timeout => 1.minute).should == '12'
  end

  it 'executes interruptible_play!() with all of the files given to :play' do
    sound_files = %w[foo bar qaz]
    mock_call.should_receive(:interruptible_play!).once.with('foo').and_return nil
    mock_call.should_receive(:interruptible_play!).once.with('bar').and_return nil
    mock_call.should_receive(:interruptible_play!).once.with('qaz').and_return '#'
    mock_call.should_receive(:wait_for_digit).once.and_return '*'
    mock_call.input(2, :play => sound_files).should == '#*'
  end

  it 'executes #play! when :interruptible is set to false' do
    sound_files = %w[foo bar qaz]
    mock_call.should_receive(:play!).once.with('foo').and_return true
    mock_call.should_receive(:play!).once.with('bar').and_return true
    mock_call.should_receive(:play!).once.with('qaz').and_return true
    mock_call.should_receive(:wait_for_digit).once.and_return '*'
    mock_call.input(1, :play => sound_files, :interruptible => false).should == '*'
  end

  it 'pressing the terminating key before any other digits returns an empty string' do
    mock_call.should_receive(:wait_for_digit).once.and_return '*'
    mock_call.input(:accept_key => '*').should == ''
  end

  it 'should execute wait_for_digit first if no sound files are given' do
    mock_call.should_receive(:interruptible_play!).never
    mock_call.should_receive(:wait_for_digit).once.and_throw :digit_request
    should_throw(:digit_request) { mock_call.input(1) }
  end

  it "Input timing out when digits are pressed returns only the collected digits" do
    timeout = 1.day
    mock_call.should_receive(:wait_for_digit).twice.with(timeout).and_return '5', nil
    mock_call.input(9, :timeout => timeout).should == '5'
  end

  it 'should execute wait_for_digit, even if some interruptible sound files are not found' do
    pbx_should_respond_with_stream_file_failure_on_open
    file = 'foobar'
    timeout = 1.hour
    mock_call.should_receive(:wait_for_digit).twice.with(timeout).and_return '8', '9'
    mock_call.input(2, :timeout => timeout, :play => file).should == '89'
    pbx_was_asked_to_stream file
  end

  it 'should execute wait_for_digit with, even if some uninterruptible sound files are not found' do
    pbx_should_respond_with_playback_failure
    file = 'foobar'
    timeout = 1.hour
    mock_call.should_receive(:wait_for_digit).twice.with(timeout).and_return '8', '9'
    mock_call.input(2, :timeout => timeout, :play => file, :interruptible => false).should == '89'
    pbx_was_asked_to_play file
  end

  it 'should return an empty string if no keys are pressed, even if the sound file is not found' do
    pbx_should_respond_with_stream_file_failure_on_open
    file = 'foobar'
    timeout = 1.second
    mock_call.should_receive(:wait_for_digit).once.with(timeout).and_return nil
    mock_call.input(5, :timeout => timeout, :play => file).should == ''
    pbx_was_asked_to_stream file
  end

  it 'should play a series of files, collecting digits even if some of the sound files cannot be found' do
    pbx_should_respond_with_stream_file_success 0
    pbx_should_respond_with_stream_file_success 0
    pbx_should_respond_with_stream_file_failure_on_open
    pbx_should_respond_with_stream_file_success ?1.ord

    play_files = ('sound1'..'sound6').map &:to_s
    played_files = ('sound1'..'sound4').map &:to_s
    timeout = 1.minute
    mock_call.should_receive(:wait_for_digit).twice.with(timeout).and_return '2', '3'
    mock_call.input(3, :timeout => timeout, :play => play_files).should == '123'
    pbx_was_asked_to_stream played_files
  end

  it 'should play a series of 4 interruptible sounds, collecting digits even if some of the sound files cannot be found' do
    pbx_should_respond_with_stream_file_success 0
    pbx_should_respond_with_stream_file_success 0
    pbx_should_respond_with_stream_file_failure_on_open
    pbx_should_respond_with_stream_file_success 0
    pbx_should_respond_with_stream_file_success ?1.ord

    play_files = ('sound1'..'sound8').map &:to_s
    played_files = ('sound1'..'sound5').map &:to_s
    timeout = 1.second
    mock_call.should_receive(:wait_for_digit).times(3).with(timeout).and_return '2', '3', '4'
    mock_call.input(4, :timeout => timeout, :play => play_files).should == '1234'
    pbx_was_asked_to_stream played_files
  end

  it 'should not raise an exception if the sound file is unplayable' do
    pbx_should_respond_with_stream_file_failure_on_open
    file = 'foobar'
    mock_call.should_receive(:wait_for_digit).once
    the_following_code {
      mock_call.input 1, :play => file
    }.should_not raise_error
    pbx_was_asked_to_stream file
  end

  it 'should default to playing interruptible prompts' do
    mock_call.should_receive(:interruptible_play!).once.with('does_not_matter')
    mock_call.should_receive(:wait_for_digit).once
    mock_call.input(1, :play => 'does_not_matter')
  end

  it 'should render uninterruptible prompts' do
    mock_call.should_receive(:play!).once.with('does_not_matter')
    mock_call.should_receive(:wait_for_digit).once
    mock_call.input(1, :play => 'does_not_matter', :interruptible => false)
  end

  it 'should fall back to speaking TTS if sound file is unplayable' do
    pbx_should_respond_with_stream_file_failure_on_open
    mock_call.should_receive(:speak).once.with("The sound file was not available", :interruptible => true)
    mock_call.should_receive(:wait_for_digit).once
    mock_call.input(1, :play => 'unavailable sound file', :speak => {:text => "The sound file was not available"})
    @output.read.should == "STREAM FILE \"unavailable sound file\" \"1234567890*#\"\n"
  end

  it 'should allow uninterruptible TTS prompts' do
    mock_call.should_receive(:speak).once.with("The sound file was not available", :interruptible => false)
    mock_call.should_receive(:wait_for_digit).once
    mock_call.input(1, :speak => {:text => "The sound file was not available"}, :interruptible => false)
  end

  it 'should play a series of 4 uninterruptible sounds, collecting digits even if some of the sound files cannot be found' do
    pbx_should_respond_with_playback_success
    pbx_should_respond_with_playback_failure
    pbx_should_respond_with_playback_success

    files = ('sound1'..'sound3').map &:to_s
    timeout = 1.second
    mock_call.should_receive(:wait_for_digit).twice.with(timeout).and_return '6', '7'
    mock_call.input(2, :timeout => timeout, :play => files, :interruptible => false).should == '67'
    pbx_was_asked_to_play files
  end

end

describe 'The #input! method' do

  include DialplanCommandTestHelpers

  it 'should raise an error when the number of digits expected is -1 (this is deprecated behavior)' do
    the_following_code {
      mock_call.input! -1
    }.should raise_error ArgumentError
  end

  it 'should execute wait_for_digit if no digit is pressed during interruptible_play!' do
    sound_files = %w[one two three]
    mock_call.should_receive(:interruptible_play!).once.with('one').and_return nil
    mock_call.should_receive(:interruptible_play!).once.with('two').and_return nil
    mock_call.should_receive(:interruptible_play!).once.with('three').and_return nil
    mock_call.should_receive(:wait_for_digit).once.and_throw :digit_request
    should_throw(:digit_request) { mock_call.input! 10, :play => sound_files }
  end

  it 'executes interruptible_play!() with all of the files given to :play' do
    sound_files = %w[foo bar qaz]
    mock_call.should_receive(:interruptible_play!).once.with('foo').and_return nil
    mock_call.should_receive(:interruptible_play!).once.with('bar').and_return nil
    mock_call.should_receive(:interruptible_play!).once.with('qaz').and_return '#'
    mock_call.should_receive(:wait_for_digit).once.and_return '*'
    mock_call.input!(2, :play => sound_files).should == '#*'
  end

  it 'executes play!() with all of the files given to :play' do
    sound_files = %w[foo bar qaz]
    mock_call.should_receive(:play!).once.with('foo').and_return true
    mock_call.should_receive(:play!).once.with('bar').and_return true
    mock_call.should_receive(:play!).once.with('qaz').and_return true
    mock_call.should_receive(:wait_for_digit).once.and_return '*'
    mock_call.input!(1, :play => sound_files, :interruptible => false).should == '*'
  end

  it 'should execute wait_for_digit first if no sound files are given' do
    mock_call.should_receive(:interruptible_play!).never
    mock_call.should_receive(:wait_for_digit).once.and_throw :digit_request
    should_throw(:digit_request) { mock_call.input! 1 }
  end

  it 'should raise an error when the sound file is not found' do
    pbx_should_respond_with_stream_file_failure_on_open
    file = 'foobar'
    mock_call.should_receive(:wait_for_digit).never
    the_following_code {
      mock_call.input! 1, :play => file
    }.should raise_error Adhearsion::VoIP::PlaybackError
    pbx_was_asked_to_stream file
  end

  it 'should play a series of interruptible files, raising an error if a sound file cannot be found' do
    pbx_should_respond_with_stream_file_success 0
    pbx_should_respond_with_stream_file_failure_on_open
    mock_call.should_receive(:wait_for_digit).never

    play_files = ('sound1'..'sound6').map &:to_s
    played_files = ('sound1'..'sound2').map &:to_s
    the_following_code {
      mock_call.input! 10, :play => play_files, :timeout => 5.seconds
    }.should raise_error Adhearsion::VoIP::PlaybackError
    pbx_was_asked_to_stream played_files
  end

  it 'should play a series of uninterruptible files, raising an error if a sound file cannot be found' do
    pbx_should_respond_with_playback_success
    pbx_should_respond_with_playback_failure

    play_files = ('sound1'..'sound6').map &:to_s
    played_files = ('sound1'..'sound2').map &:to_s
    the_following_code {
      mock_call.input! 10, :play => play_files, :timeout => 5.seconds, :interruptible => false
    }.should raise_error Adhearsion::VoIP::PlaybackError
    pbx_was_asked_to_play played_files
  end

end

describe "The #variable method" do

  include DialplanCommandTestHelpers

  it "should call set_variable for every Hash-key argument given" do
    args = [:ohai, "ur_home_erly"]
    mock_call.should_receive(:set_variable).once.with(*args)
    mock_call.variable Hash[*args]
  end

  it "should call set_variable for every Hash-key argument given" do
    many_args = { :a => :b, :c => :d, :e => :f, :g => :h}
    mock_call.should_receive(:set_variable).times(many_args.size)
    mock_call.variable many_args
  end

  it "should call get_variable for every String given" do
    variables = ["foo", "bar", :qaz, :qwerty, :baz]
    variables.each do |var|
      mock_call.should_receive(:get_variable).once.with(var).and_return("X")
    end
    mock_call.variable(*variables)
  end

  it "should NOT return an Array when just one arg is given" do
    mock_call.should_receive(:get_variable).once.and_return "lol"
    mock_call.variable(:foo).should_not be_a_kind_of Array
  end

  it "should raise an ArgumentError when a Hash and normal args are given" do
    the_following_code {
      mock_call.variable 5,4,3,2,1, :foo => :bar
    }.should raise_error ArgumentError
  end

end

describe "The #set_variable method" do

  include DialplanCommandTestHelpers

  it "variables and values are properly quoted" do
    mock_call.should_receive(:raw_response).once.with 'SET VARIABLE "foo" "i can \\" has ruby?"'
    mock_call.set_variable 'foo', 'i can " has ruby?'
  end

  it "to_s() is effectively called on both the key and the value" do
    mock_call.should_receive(:raw_response).once.with 'SET VARIABLE "QAZ" "QWERTY"'
    mock_call.set_variable :QAZ, :QWERTY
  end

end

describe "The #sip_add_header method" do
  include DialplanCommandTestHelpers

  it "values are properly quoted" do
    mock_call.should_receive(:raw_response).once.with 'EXEC SIPAddHeader "x-ahn-header: rubyrox"'
    mock_call.sip_add_header "x-ahn-header", "rubyrox"
  end
end

describe "The #sip_get_header method" do
  include DialplanCommandTestHelpers

  it "properly formats the AGI request" do
    value = 'jason-was-here'
    mock_call.should_receive(:raw_response).once.with('GET VARIABLE "SIP_HEADER(x-ahn-header)"').and_return "200 result=1 (#{value})"
    mock_call.sip_get_header("x-ahn-header").should == value
  end

  it "properly formats the AGI request using the method alias" do
    value = 'jason-was-here'
    mock_call.should_receive(:raw_response).once.with('GET VARIABLE "SIP_HEADER(x-ahn-header)"').and_return "200 result=1 (#{value})"
    mock_call.sip_header("x-ahn-header").should == value
  end
end

describe 'The #voicemail command' do

  include DialplanCommandTestHelpers

  it 'should not send the context name when none is given' do
    mailbox_number = 123
    mock_call.should_receive(:execute).once.with('voicemail', 123, '').and_throw :sent_voicemail!
    should_throw(:sent_voicemail!) { mock_call.voicemail 123 }
  end

  it 'should send the context name when one is given' do
    mailbox_number, context_name = 333, 'doesntmatter'
    mock_call.should_receive(:execute).once.with('voicemail', "#{mailbox_number}@#{context_name}", '').and_throw :sent_voicemail!
    should_throw(:sent_voicemail!) { mock_call.voicemail(context_name => mailbox_number) }
  end

  it 'should pass in the s option if :skip => true' do
    mailbox_number = '012'
    mock_call.should_receive(:execute).once.with('voicemail', mailbox_number, 's').and_throw :sent_voicemail!
    should_throw(:sent_voicemail!) { mock_call.voicemail(mailbox_number, :skip => true) }
  end

  it 'should combine mailbox numbers with the context name given when both are given' do
    pbx_should_respond_with_value 'SUCCESS'
    context   = "lolcats"
    mailboxes = [1,2,3,4,5]
    mailboxes_with_context = mailboxes.map { |mailbox| "#{mailbox}@#{context}"}
    mock_call.should_receive(:execute).once.with('voicemail', mailboxes_with_context.join('&'), '')
    mock_call.voicemail context => mailboxes
    pbx_should_have_been_sent 'GET VARIABLE "VMSTATUS"'
  end

  it 'should raise an argument error if the mailbox number is not numerical' do
    the_following_code {
      mock_call.voicemail :foo => "bar"
    }.should raise_error ArgumentError
  end

  it 'should raise an argument error if too many arguments are supplied' do
    the_following_code {
      mock_call.voicemail "wtfisthisargument", :context_name => 123, :greeting => :busy
    }.should raise_error ArgumentError
  end

  it 'should raise an ArgumentError if multiple context names are given' do
    the_following_code {
      mock_call.voicemail :one => [1,2,3], :two => [11,22,33]
    }.should raise_error ArgumentError
  end

  it "should raise an ArgumentError when the :greeting value isn't recognized" do
    the_following_code {
      mock_call.voicemail :context_name => 123, :greeting => :zomgz
    }.should raise_error ArgumentError
  end

  it 'should pass in the u option if :greeting => :unavailable' do
    mailbox_number = '776'
    mock_call.should_receive(:execute).once.with('voicemail', mailbox_number, 'u').and_throw :sent_voicemail!
    should_throw(:sent_voicemail!) { mock_call.voicemail(mailbox_number, :greeting => :unavailable) }
  end

  it 'should pass in both the skip and greeting options if both are supplied' do
    mailbox_number = '4'
    mock_call.should_receive(:execute).once.with('voicemail', mailbox_number, 'u').and_throw :sent_voicemail!
    should_throw(:sent_voicemail!) { mock_call.voicemail(mailbox_number, :greeting => :unavailable) }
  end

  it 'should raise an ArgumentError if mailbox_number is blank?()' do
    the_following_code {
      mock_call.voicemail ''
    }.should raise_error ArgumentError

    the_following_code {
      mock_call.voicemail nil
    }.should raise_error ArgumentError
  end

  it 'should pass in the b option if :gretting => :busy' do
    mailbox_number = '1'
    mock_call.should_receive(:execute).once.with('voicemail', mailbox_number, 'b').and_throw :sent_voicemail!
    should_throw(:sent_voicemail!) { mock_call.voicemail(mailbox_number, :greeting => :busy) }
  end

  it 'should return true if VMSTATUS == "SUCCESS"' do
    mock_call.should_receive(:execute).once
    mock_call.should_receive(:variable).once.with('VMSTATUS').and_return "SUCCESS"
    mock_call.voicemail(3).should be true
  end

  it 'should return false if VMSTATUS == "USEREXIT"' do
    mock_call.should_receive(:execute).once
    mock_call.should_receive(:variable).once.with('VMSTATUS').and_return "USEREXIT"
    mock_call.voicemail(2).should be false
  end

  it 'should return nil if VMSTATUS == "FAILED"' do
    mock_call.should_receive(:execute).once
    mock_call.should_receive(:variable).once.with('VMSTATUS').and_return "FAILED"
    mock_call.voicemail(2).should be nil
  end

end

describe 'The voicemail_main command' do

  include DialplanCommandTestHelpers

  #it "should not pass in the context or the delimiting @ sign if you don't supply one"

  it "the :folder Hash key argument should wrap the value in a()" do
    folder = "foobar"
    mailbox = 81
    mock_call.should_receive(:execute).once.with("VoiceMailMain", "#{mailbox}","a(#{folder})")
    mock_call.voicemail_main :mailbox => mailbox, :folder => folder
  end

  it ':authenticate should pass in the "s" option if given false' do
    mailbox = 333
    mock_call.should_receive(:execute).once.with("VoiceMailMain", "#{mailbox}","s")
    mock_call.voicemail_main :mailbox => mailbox, :authenticate => false
  end

  it ':authenticate should pass in the s option if given false' do
    mailbox = 55
    mock_call.should_receive(:execute).once.with("VoiceMailMain", "#{mailbox}")
    mock_call.voicemail_main :mailbox => mailbox, :authenticate => true
  end

  it 'should not pass any flags only a mailbox is given' do
    mailbox = "1"
    mock_call.should_receive(:execute).once.with("VoiceMailMain", "#{mailbox}")
    mock_call.voicemail_main :mailbox => mailbox
  end

  it 'when given no mailbox or context an empty string should be passed to execute as the first argument' do
    mock_call.should_receive(:execute).once.with("VoiceMailMain", "", "s")
    mock_call.voicemail_main :authenticate => false
  end

  it 'should properly concatenate the options when given multiple ones' do
    folder = "ohai"
    mailbox = 9999
    mock_call.should_receive(:execute).once.with("VoiceMailMain", "#{mailbox}", "sa(#{folder})")
    mock_call.voicemail_main :mailbox => mailbox, :authenticate => false, :folder => folder
  end

  it 'should not require any arguments' do
    mock_call.should_receive(:execute).once.with("VoiceMailMain")
    mock_call.voicemail_main
  end

  it 'should pass in the "@context_name" part in if a :context is given and no mailbox is given' do
    context_name = "icanhascheezburger"
    mock_call.should_receive(:execute).once.with("VoiceMailMain", "@#{context_name}")
    mock_call.voicemail_main :context => context_name
  end

  it "should raise an exception if the folder has a space or malformed characters in it" do
    ["i has a space", "exclaim!", ",", ""].each do |bad_folder_name|
      the_following_code {
        mock_call.voicemail_main :mailbox => 123, :folder => bad_folder_name
      }.should raise_error ArgumentError
    end
  end

end

describe 'the check_voicemail command' do

  include DialplanCommandTestHelpers

  it "should simply execute voicemail_main with no arguments after warning" do
    flexmock(ahn_log.agi).should_receive(:warn).once.with(String)
    mock_call.should_receive(:voicemail_main).once.and_return :mocked_out
    mock_call.check_voicemail.should be :mocked_out
  end

end


describe "The queue management abstractions" do

  include DialplanCommandTestHelpers

  it 'should not create separate objects for queues with basically the same name' do
    mock_call.queue('foo').should be mock_call.queue('foo')
    mock_call.queue('bar').should be mock_call.queue(:bar)
  end

  it "queue() should return an instance of QueueProxy" do
    mock_call.queue("foobar").should be_a_kind_of Adhearsion::VoIP::Asterisk::Commands::QueueProxy
  end

  it "a QueueProxy should respond to join!(), members()" do
    %w[join! agents].each do |method|
      mock_call.queue('foobar').should respond_to(method)
    end
  end

  it 'a QueueProxy should return a QueueAgentsListProxy when members() is called' do
    mock_call.queue('foobar').agents.should be_a_kind_of(Adhearsion::VoIP::Asterisk::Commands::QueueProxy::QueueAgentsListProxy)
  end

  it 'join! should properly join a queue' do
    mock_call.should_receive(:execute).once.with("queue", "foobaz", "", '', '', '', '')
    mock_call.should_receive(:get_variable).once.with("QUEUESTATUS").and_return "FULL"
    mock_call.queue("foobaz").join!
  end

  it 'should return a symbol representing the result of joining the queue' do
    does_not_read_data_back
    mock_call.should_receive(:get_variable).once.with("QUEUESTATUS").and_return "TIMEOUT"
    mock_call.queue('monkey').join!.should be :timeout
    pbx_should_have_been_sent 'EXEC queue "monkey"|""|""|""|""|""'
  end

  it 'should return :completed after joining the queue and being connected' do
    does_not_read_data_back
    mock_call.should_receive(:get_variable).once.with("QUEUESTATUS").and_return nil
    mock_call.queue('monkey').join!.should be :completed
    pbx_should_have_been_sent 'EXEC queue "monkey"|""|""|""|""|""'
  end

  it 'should join a queue with a timeout properly' do
    mock_call.should_receive(:execute).once.with("queue", "foobaz", "", '', '', '60', '')
    mock_call.should_receive(:get_variable).once.with("QUEUESTATUS").and_return "JOINEMPTY"
    mock_call.queue("foobaz").join! :timeout => 1.minute
  end

  it 'should join a queue with an announcement file properly' do
    mock_call.should_receive(:execute).once.with("queue", "roflcopter", "", '', 'custom_announcement_file_here', '', '')
    mock_call.should_receive(:get_variable).once.with("QUEUESTATUS").and_return "JOINEMPTY"
    mock_call.queue("roflcopter").join! :announce => 'custom_announcement_file_here'
  end

  it 'should join a queue with an agi script properly' do
    mock_call.should_receive(:execute).once.with("queue", 'support', '', '', '', '','agi://localhost/queue_agi_test')
    mock_call.should_receive(:get_variable).once.with("QUEUESTATUS").and_return "JOINUNAVAIL"
    mock_call.queue("support").join! :agi => 'agi://localhost/queue_agi_test'
  end

  it 'should join a queue with allow_transfer properly' do
    mock_call.should_receive(:execute).once.with("queue", "roflcopter", "Tt", '', '', '', '')
    mock_call.should_receive(:get_variable).once.with("QUEUESTATUS").and_return "JOINEMPTY"
    mock_call.queue("roflcopter").join! :allow_transfer => :everyone

    mock_call.should_receive(:execute).once.with("queue", "roflcopter", "T", '', '', '', '')
    mock_call.should_receive(:get_variable).once.with("QUEUESTATUS").and_return "JOINEMPTY"
    mock_call.queue("roflcopter").join! :allow_transfer => :caller

    mock_call.should_receive(:execute).once.with("queue", "roflcopter", "t", '', '', '', '')
    mock_call.should_receive(:get_variable).once.with("QUEUESTATUS").and_return "JOINEMPTY"
    mock_call.queue("roflcopter").join! :allow_transfer => :agent
  end

  it 'should join a queue with allow_hangup properly' do
    mock_call.should_receive(:execute).once.with("queue", "roflcopter", "Hh", '', '', '', '')
    mock_call.should_receive(:get_variable).once.with("QUEUESTATUS").and_return "JOINEMPTY"
    mock_call.queue("roflcopter").join! :allow_hangup => :everyone

    mock_call.should_receive(:execute).once.with("queue", "roflcopter", "H", '', '', '', '')
    mock_call.should_receive(:get_variable).once.with("QUEUESTATUS").and_return "JOINEMPTY"
    mock_call.queue("roflcopter").join! :allow_hangup => :caller

    mock_call.should_receive(:execute).once.with("queue", "roflcopter", "h", '', '', '', '')
    mock_call.should_receive(:get_variable).once.with("QUEUESTATUS").and_return "JOINEMPTY"
    mock_call.queue("roflcopter").join! :allow_hangup => :agent
  end

  it 'should join a queue properly with the :play argument' do
    mock_call.should_receive(:execute).once.with("queue", "roflcopter", "r", '', '', '', '')
    mock_call.should_receive(:get_variable).once.with("QUEUESTATUS").and_return "JOINEMPTY"
    mock_call.queue("roflcopter").join! :play => :ringing

    mock_call.should_receive(:execute).once.with("queue", "roflcopter", "", '', '', '', '')
    mock_call.should_receive(:get_variable).once.with("QUEUESTATUS").and_return "JOINEMPTY"
    mock_call.queue("roflcopter").join! :play => :music
  end

  it 'joining a queue with many options specified' do
    mock_call.should_receive(:execute).once.with("queue", "q", "rtHh", '', '', '120', '')
    mock_call.should_receive(:get_variable).once.with("QUEUESTATUS").and_return "JOINEMPTY"
    mock_call.queue('q').join! :allow_transfer => :agent, :timeout => 2.minutes,
                               :play => :ringing, :allow_hangup => :everyone
  end

  it 'join!() should raise an ArgumentError when unrecognized Hash key arguments are given' do
    the_following_code {
      mock_call.queue('iwearmysunglassesatnight').join! :misspelled => true
    }.should raise_error ArgumentError
  end

  it 'should fetch the members with the name given to queue()' do
    mock_call.should_receive(:variable).once.with("QUEUE_MEMBER_COUNT(jay)").and_return 5
    mock_call.queue('jay').agents.size.should == 5
  end

  it 'should not fetch a QUEUE_MEMBER_COUNT each time count() is called when caching is enabled' do
    mock_call.should_receive(:variable).once.with("QUEUE_MEMBER_COUNT(sales)").and_return 0
    10.times do
      mock_call.queue('sales').agents(:cache => true).size
    end
  end

  it 'should raise an argument error if the members() method receives an unrecognized symbol' do
    the_following_code {
      mock_call.queue('foobarz').agents(:cached => true) # common typo
    }.should raise_error ArgumentError
  end

  it 'when fetching agents, it should properly split by the supported delimiters' do
    queue_name = "doesnt_matter"
    mock_call.should_receive(:get_variable).with("QUEUE_MEMBER_LIST(#{queue_name})").and_return('Agent/007,Agent/003,Zap/2')
    mock_call.queue(queue_name).agents(:cache => true).to_a.size.should == 3
  end

  it 'when fetching agents, each array index should be an instance of AgentProxy' do
    queue_name = 'doesnt_matter'
    mock_call.should_receive(:get_variable).with("QUEUE_MEMBER_LIST(#{queue_name})").and_return('Agent/007,Agent/003,Zap/2')
    agents = mock_call.queue(queue_name).agents(:cache => true).to_a
    agents.size.should > 0
    agents.each do |agent|
      agent.should be_a_kind_of Adhearsion::VoIP::Asterisk::Commands::QueueProxy::AgentProxy
    end
  end

  it 'should properly retrieve metadata for an AgentProxy instance' do
    agent_id, metadata_name = '22', 'status'
    mock_env   = flexmock "a mock ExecutionEnvironment"
    mock_queue = flexmock "a queue that references our mock ExecutionEnvironment", :environment => mock_env, :name => "doesntmatter"
    mock_env.should_receive(:variable).once.with("AGENT(#{agent_id}:#{metadata_name})")
    agent = Adhearsion::VoIP::Asterisk::Commands::QueueProxy::AgentProxy.new("Agent/#{agent_id}", mock_queue)
    agent.send(:agent_metadata, metadata_name)
  end

  it 'AgentProxy#logged_in? should return true if the "state" of an agent == LOGGEDIN' do
    mock_env   = flexmock "a mock ExecutionEnvironment"
    mock_queue = flexmock "a queue that references our mock ExecutionEnvironment", :environment => mock_env, :name => "doesntmatter"

    agent = Adhearsion::VoIP::Asterisk::Commands::QueueProxy::AgentProxy.new('Agent/123', mock_queue)
    flexmock(agent).should_receive(:agent_metadata).once.with('status').and_return 'LOGGEDIN'
    agent.logged_in?.should be true

    flexmock(agent).should_receive(:agent_metadata).once.with('status').and_return 'LOGGEDOUT'
    agent.logged_in?.should_not be true
  end

  it 'the AgentProxy should populate its own "id" property to the numerical ID of the "interface" with which it was constructed' do
    mock_queue = flexmock :name => "doesntmatter"
    id = '123'

    agent = Adhearsion::VoIP::Asterisk::Commands::QueueProxy::AgentProxy.new("Agent/#{id}", mock_queue)
    agent.id.should == id

    agent = Adhearsion::VoIP::Asterisk::Commands::QueueProxy::AgentProxy.new(id, mock_queue)
    agent.id.should == id
  end

  it 'QueueAgentsListProxy#<<() should new the channel driver given as the argument to the system' do
    queue_name, agent_channel = "metasyntacticvariablesftw", "Agent/123"
    mock_call.should_receive('execute').once.with("AddQueueMember", queue_name, agent_channel, "", "", "", "")
    mock_call.should_receive(:get_variable).once.with('AQMSTATUS').and_return('ADDED')
    mock_call.should_receive(:get_variable).once.with("QUEUE_MEMBER_LIST(#{queue_name})").and_return "Agent/007,SIP/2302,Local/2510@from-internal"
    mock_call.queue(queue_name).agents.new agent_channel
  end

  it 'when a queue agent is dynamically added and the queue does not exist, a QueueDoesNotExistError should be raised' do
    does_not_read_data_back
    mock_call.should_receive(:get_variable).once.with('AQMSTATUS').and_return('NOSUCHQUEUE')
    the_following_code {
      mock_call.queue('this_should_not_exist').agents.new 'Agent/911'
    }.should raise_error Adhearsion::VoIP::Asterisk::Commands::QueueProxy::QueueDoesNotExistError
    pbx_should_have_been_sent 'EXEC AddQueueMember "this_should_not_exist"|"Agent/911"|""|""|""|""'
  end

  it 'when a queue agent is dynamiaclly added and the adding was successful, an AgentProxy should be returned' do
    mock_call.should_receive(:get_variable).once.with("AQMSTATUS").and_return("ADDED")
    mock_call.should_receive(:execute).once.with("AddQueueMember", "lalala", "Agent/007", "", "", "", "")
    mock_call.should_receive(:get_variable).once.with("QUEUE_MEMBER_LIST(lalala)").and_return "Agent/007,SIP/2302,Local/2510@from-internal"
    return_value = mock_call.queue('lalala').agents.new "Agent/007"
    return_value.kind_of?(Adhearsion::VoIP::Asterisk::Commands::QueueProxy::AgentProxy).should be true
  end

  it 'when a queue agent is dynamiaclly added and the adding was unsuccessful, a false should be returned' do
    mock_call.should_receive(:get_variable).once.with("AQMSTATUS").and_return("MEMBERALREADY")
    mock_call.should_receive(:execute).once.with("AddQueueMember", "lalala", "Agent/007", "", "", "", "")
    return_value = mock_call.queue('lalala').agents.new "Agent/007"
    return_value.should be false
  end

  it 'should raise an argument when an unrecognized key is given to add()' do
    the_following_code {
      mock_call.queue('q').agents.new :foo => "bar"
    }.should raise_error ArgumentError
  end

  it 'should execute AddQueueMember with the penalty properly' do
    queue_name = 'name_does_not_matter'
    mock_call.should_receive(:execute).once.with('AddQueueMember', queue_name, 'Agent/007', 10, '', '','')
    mock_call.should_receive(:get_variable).once.with('AQMSTATUS').and_return('ADDED')
    mock_call.should_receive(:get_variable).once.with("QUEUE_MEMBER_LIST(#{queue_name})").and_return "Agent/007,SIP/2302,Local/2510@from-internal"
    mock_call.queue(queue_name).agents.new 'Agent/007', :penalty => 10
  end

  it 'should execute AddQueueMember with the state_interface properly' do
    queue_name = 'name_does_not_matter'
    mock_call.should_receive(:execute).once.with('AddQueueMember', queue_name, 'Agent/007', '', '', '','SIP/2302')
    mock_call.should_receive(:get_variable).once.with('AQMSTATUS').and_return('ADDED')
    mock_call.should_receive(:get_variable).once.with("QUEUE_MEMBER_LIST(#{queue_name})").and_return "Agent/007,SIP/2302,Local/2510@from-internal"
    mock_call.queue(queue_name).agents.new 'Agent/007', :state_interface => 'SIP/2302'
  end

  it 'should execute AddQueueMember properly when the name is given' do
    queue_name, agent_name = 'name_does_not_matter', 'Jay Phillips'
    mock_call.should_receive(:execute).once.with('AddQueueMember', queue_name, 'Agents/007', '', '', agent_name,'')
    mock_call.should_receive(:get_variable).once.with('AQMSTATUS').and_return('ADDED')
    mock_call.should_receive(:get_variable).once.with("QUEUE_MEMBER_LIST(#{queue_name})").and_return "Agent/007,SIP/2302,Local/2510@from-internal"
    mock_call.queue(queue_name).agents.new 'Agents/007', :name => agent_name
  end

  it 'should execute AddQueueMember properly when the name, penalty, and interface is given' do
    queue_name, agent_name, interface, penalty = 'name_does_not_matter', 'Jay Phillips', 'Agent/007', 4
    mock_call.should_receive(:execute).once.with('AddQueueMember', queue_name, interface, penalty, '', agent_name,'')
    mock_call.should_receive(:get_variable).once.with('AQMSTATUS').and_return('ADDED')
    mock_call.should_receive(:get_variable).once.with("QUEUE_MEMBER_LIST(#{queue_name})").and_return "Agent/007,SIP/2302,Local/2510@from-internal"
    mock_call.queue(queue_name).agents.new interface, :name => agent_name, :penalty => penalty
  end

  it 'should execute AddQueueMember properly when the name, penalty, interface, and state_interface is given' do
    queue_name, agent_name, interface, penalty, state_interface = 'name_does_not_matter', 'Jay Phillips', 'Agent/007', 4, 'SIP/2302'
    mock_call.should_receive(:execute).once.with('AddQueueMember', queue_name, interface, penalty, '', agent_name, state_interface)
    mock_call.should_receive(:get_variable).once.with('AQMSTATUS').and_return('ADDED')
    mock_call.should_receive(:get_variable).once.with("QUEUE_MEMBER_LIST(#{queue_name})").and_return "Agent/007,SIP/2302,Local/2510@from-internal"
    mock_call.queue(queue_name).agents.new interface, :name => agent_name, :penalty => penalty, :state_interface => state_interface
  end

  it 'should return a correct boolean for exists?()' do
    mock_call.should_receive(:execute).once.with("RemoveQueueMember", "kablamm", "SIP/AdhearsionQueueExistenceCheck")
    mock_call.should_receive(:get_variable).once.with("RQMSTATUS").and_return "NOTINQUEUE"
    mock_call.queue("kablamm").exists?.should be true

    mock_call.should_receive(:execute).once.with("RemoveQueueMember", "monkey", "SIP/AdhearsionQueueExistenceCheck")
    mock_call.should_receive(:get_variable).once.with("RQMSTATUS").and_return "NOSUCHQUEUE"
    mock_call.queue("monkey").exists?.should be false
  end

  it 'should pause an agent properly from a certain queue' do
    does_not_read_data_back
    mock_call.should_receive(:get_variable).once.with("QUEUE_MEMBER_LIST(lolcats)").and_return "Agent/007,Agent/008"
    mock_call.should_receive(:get_variable).once.with("PQMSTATUS").and_return "PAUSED"

    agents = mock_call.queue('lolcats').agents :cache => true
    agents.last.pause!.should be true
    pbx_should_have_been_sent 'EXEC PauseQueueMember "lolcats"|"Agent/008"'
  end

  it 'should pause an agent properly from a certain queue and return false when the agent did not exist' do
    mock_call.should_receive(:get_variable).once.with("QUEUE_MEMBER_LIST(lolcats)").and_return "Agent/007,Agent/008"
    mock_call.should_receive(:get_variable).once.with("PQMSTATUS").and_return "NOTFOUND"
    mock_call.should_receive(:execute).once.with("PauseQueueMember", 'lolcats', "Agent/008")

    agents = mock_call.queue('lolcats').agents :cache => true
    agents.last.pause!.should be false
  end

  it 'should pause an agent globally properly' do
    mock_call.should_receive(:get_variable).once.with("QUEUE_MEMBER_LIST(family)").and_return "Agent/Jay"
    mock_call.should_receive(:get_variable).once.with("PQMSTATUS").and_return "PAUSED"
    mock_call.should_receive(:execute).once.with("PauseQueueMember", nil, "Agent/Jay")

    mock_call.queue('family').agents.first.pause! :everywhere => true
  end

  it 'should unpause an agent properly' do
    queue_name = "name with spaces"
    mock_call.should_receive(:get_variable).once.with("QUEUE_MEMBER_LIST(#{queue_name})").and_return "Agent/Jay"
    mock_call.should_receive(:get_variable).once.with("UPQMSTATUS").and_return "UNPAUSED"
    mock_call.should_receive(:execute).once.with("UnpauseQueueMember", queue_name, "Agent/Jay")

    mock_call.queue(queue_name).agents.first.unpause!.should be true
  end

  it 'should unpause an agent globally properly' do
    mock_call.should_receive(:get_variable).once.with("QUEUE_MEMBER_LIST(FOO)").and_return "Agent/Tom"
    mock_call.should_receive(:get_variable).once.with("UPQMSTATUS").and_return "UNPAUSED"
    mock_call.should_receive(:execute).once.with("UnpauseQueueMember", nil, "Agent/Tom")

    mock_call.queue('FOO').agents.first.unpause!(:everywhere => true).should be true
  end

  it 'waiting_count for a queue that does exist' do
    mock_call.should_receive(:get_variable).once.with("QUEUE_WAITING_COUNT(q)").and_return "50"
    flexmock(mock_call.queue('q')).should_receive(:exists?).once.and_return true
    mock_call.queue('q').waiting_count.should == 50
  end

  it 'waiting_count for a queue that does not exist' do
    the_following_code {
      flexmock(mock_call.queue('q')).should_receive(:exists?).once.and_return false
      mock_call.queue('q').waiting_count
    }.should raise_error Adhearsion::VoIP::Asterisk::Commands::QueueProxy::QueueDoesNotExistError
  end

  it 'empty? should call waiting_count' do
    queue = mock_call.queue 'testing_empty'
    flexmock(queue).should_receive(:waiting_count).once.and_return 0
    queue.empty?.should be true

    queue = mock_call.queue 'testing_empty'
    flexmock(queue).should_receive(:waiting_count).once.and_return 99
    queue.empty?.should_not be true
  end

  it 'any? should call waiting_count' do
    queue = mock_call.queue 'testing_empty'
    flexmock(queue).should_receive(:waiting_count).once.and_return 0
    queue.any?.should be false

    queue = mock_call.queue 'testing_empty'
    flexmock(queue).should_receive(:waiting_count).once.and_return 99
    queue.any?.should be true
  end

  it 'should remove an agent properly' do
    mock_call.should_receive(:get_variable).once.with("QUEUE_MEMBER_LIST(FOO)").and_return "Agent/Tom"
    mock_call.should_receive(:execute).once.with('RemoveQueueMember', 'FOO', 'Agent/Tom')
    mock_call.should_receive(:get_variable).once.with("RQMSTATUS").and_return "REMOVED"
    mock_call.queue('FOO').agents.first.remove!.should be true
  end

  it 'should remove an agent properly' do
    mock_call.should_receive(:get_variable).once.with("QUEUE_MEMBER_LIST(FOO)").and_return "Agent/Tom"
    mock_call.should_receive(:execute).once.with('RemoveQueueMember', 'FOO', 'Agent/Tom')
    mock_call.should_receive(:get_variable).once.with("RQMSTATUS").and_return "NOTINQUEUE"
    mock_call.queue('FOO').agents.first.remove!.should be false
  end

  it "should raise a QueueDoesNotExistError when removing an agent from a queue that doesn't exist" do
    mock_call.should_receive(:get_variable).once.with("QUEUE_MEMBER_LIST(cool_people)").and_return "Agent/ZeroCool"
    mock_call.should_receive(:execute).once.with("RemoveQueueMember", "cool_people", "Agent/ZeroCool")
    mock_call.should_receive(:get_variable).once.with("RQMSTATUS").and_return "NOSUCHQUEUE"
    the_following_code {
      mock_call.queue("cool_people").agents.first.remove!
    }.should raise_error Adhearsion::VoIP::Asterisk::Commands::QueueProxy::QueueDoesNotExistError
  end

  it "should log an agent in properly with no agent id given" do
    mock_call.should_receive(:execute).once.with('AgentLogin', nil, 's')
    mock_call.queue('barrel_o_agents').agents.login!
  end

  it 'should remove "Agent/" before the agent ID given if necessary when logging an agent in' do
    mock_call.should_receive(:execute).once.with('AgentLogin', '007', 's')
    mock_call.queue('barrel_o_agents').agents.login! 'Agent/007'

    mock_call.should_receive(:execute).once.with('AgentLogin', '007', 's')
    mock_call.queue('barrel_o_agents').agents.login! '007'
  end

  it 'should add an agent silently properly' do
    mock_call.should_receive(:execute).once.with('AgentLogin', '007', '')
    mock_call.queue('barrel_o_agents').agents.login! 'Agent/007', :silent => false

    mock_call.should_receive(:execute).once.with('AgentLogin', '008', 's')
    mock_call.queue('barrel_o_agents').agents.login! 'Agent/008', :silent => true
  end

  it 'logging an agent in should raise an ArgumentError is unrecognized arguments are given' do
    the_following_code {
      mock_call.queue('ohai').agents.login! 1,2,3,4,5
    }.should raise_error ArgumentError

    the_following_code {
      mock_call.queue('lols').agents.login! 1337, :sssssilent => false
    }.should raise_error ArgumentError

    the_following_code {
      mock_call.queue('qwerty').agents.login! 777, 6,5,4,3,2,1, :wee => :wee
    }.should raise_error ArgumentError
  end

end

describe 'the menu() method' do

  include DialplanCommandTestHelpers

  it "should instantiate a new Menu object with only the Hash given as menu() options" do
    args = [1,2,3,4,5, {:timeout => 1.year, :tries => (1.0/0.0)}]

    flexmock(Adhearsion::VoIP::Menu).should_receive(:new).once.
        with(args.last).and_throw(:instantiating_menu!)

    should_throw(:instantiating_menu!) { mock_call.menu(*args) }
  end

  it "should jump to a context when a timeout is encountered and there is at least one exact match" do
    pbx_should_respond_with_successful_background_response ?5.ord
    pbx_should_respond_with_successful_background_response ?4.ord
    pbx_should_respond_with_a_wait_for_digit_timeout

    context_named_main  = Adhearsion::DialPlan::DialplanContextProc.new(:main)  { throw :inside_main!  }
    context_named_other = Adhearsion::DialPlan::DialplanContextProc.new(:other) { throw :inside_other! }
    flexmock(mock_call).should_receive(:main).once.and_return(context_named_main)
    flexmock(mock_call).should_receive(:other).never

    should_pass_control_to_a_context_that_throws :inside_main! do
      mock_call.menu do |link|
        link.main  54
        link.other 543
      end
    end
    3.times { pbx_should_have_been_sent 'WAIT FOR DIGIT "5000"' }
  end

  it "when the 'extension' variable is changed, it should be an instance of PhoneNumber" do
    pbx_should_respond_with_successful_background_response ?5.ord
    foobar_context = Adhearsion::DialPlan::DialplanContextProc.new(:foobar) { throw :foobar! }
    mock_call.should_receive(:foobar).once.and_return foobar_context
    should_pass_control_to_a_context_that_throws :foobar! do
      mock_call.menu do |link|
        link.foobar 5
      end
    end
    5.should === mock_call.extension
    mock_call.extension.__real_string.should == "5"
    pbx_should_have_been_sent 'WAIT FOR DIGIT "5000"'
  end

end

describe 'the Menu class' do

  include DialplanCommandTestHelpers

  it "should yield a MenuBuilder when instantiated" do
    lambda {
      Adhearsion::VoIP::Menu.new do |block_argument|
        block_argument.should be_a_kind_of Adhearsion::VoIP::MenuBuilder
        throw :inside_block
      end
    }.should throw_symbol :inside_block
  end

  it "should invoke wait_for_digit instead of interruptible_play when no sound files are given" do
    mock_call.should_receive(:wait_for_digit).once.with(5).and_return '#'
    mock_call.menu { |link| link.does_not_match 3 }
  end

  it 'should invoke interruptible_play when sound files are given only for the first digit' do
    sound_files = %w[i like big butts and i cannot lie]
    timeout = 1337

    mock_call.should_receive(:interruptible_play).once.with(*sound_files).and_return nil
    mock_call.should_receive(:wait_for_digit).once.with(timeout).and_return nil

    mock_call.menu(sound_files, :timeout => timeout) { |link| link.qwerty 12345 }
  end

  it 'if the call to interruptible_play receives a timeout, it should execute wait_for_digit with the timeout given' do
      sound_files = %w[i like big butts and i cannot lie]
      timeout = 987

      mock_call.should_receive(:interruptible_play).once.with(*sound_files).and_return nil
      mock_call.should_receive(:wait_for_digit).with(timeout).and_return

      mock_call.menu(sound_files, :timeout => timeout) { |link| link.foobar 911 }
  end

  it "should work when no files are given to be played and a timeout is reached on the first digit" do
    timeout = 12
    [:on_premature_timeout, :on_failure].each do |usage_case|
      should_throw :got_here! do
        mock_call.should_receive(:wait_for_digit).once.with(timeout).and_return nil # Simulates timeout
        mock_call.menu :timeout => timeout do |link|
          link.foobar 0
          link.__send__(usage_case) { throw :got_here! }
        end
      end
    end
  end

  it "should default the timeout to five seconds" do
    mock_call.should_receive(:wait_for_digit).once.with(5).and_return nil
    mock_call.menu { |link| link.foobar 22 }
  end

  it "when matches fail due to timeouts, the menu should repeat :tries times" do
    tries, times_timed_out = 10, 0

    tries.times do
      pbx_should_respond_with_successful_background_response ?4.ord
      pbx_should_respond_with_successful_background_response ?0.ord
      pbx_should_respond_with_a_wait_for_digit_timeout
    end

    should_throw :inside_failure_callback do
      mock_call.menu :tries => tries do |link|
        link.pattern_longer_than_our_test_input 400
        link.on_premature_timeout { times_timed_out += 1 }
        link.on_invalid { raise "should never get here!" }
        link.on_failure { throw :inside_failure_callback }
      end
    end
    times_timed_out.should be tries
    30.times { pbx_should_have_been_sent 'WAIT FOR DIGIT "5000"' }
  end

  it "when matches fail due to invalid input, the menu should repeat :tries times" do
    tries = 10
    times_invalid = 0

    tries.times do
      pbx_should_respond_with_successful_background_response ?0.ord
    end

    should_throw :inside_failure_callback do
      mock_call.menu :tries => tries do |link|
        link.be_leet 1337
        link.on_premature_timeout { raise "should never get here!" }
        link.on_invalid { times_invalid += 1 }
        link.on_failure { throw :inside_failure_callback }
      end
    end
    times_invalid.should be tries
    10.times { pbx_should_have_been_sent 'WAIT FOR DIGIT "5000"' }
  end

  it "invoke on_invalid callback when an invalid extension was entered" do
    pbx_should_respond_with_successful_background_response ?5.ord
    pbx_should_respond_with_successful_background_response ?5.ord
    pbx_should_respond_with_successful_background_response ?5.ord
    should_throw :inside_invalid_callback do
      mock_call.menu do |link|
        link.onetwothree 123
        link.on_invalid { throw :inside_invalid_callback }
      end
    end
    pbx_should_have_been_sent 'WAIT FOR DIGIT "5000"'
  end

  it "invoke on_premature_timeout when a timeout is encountered" do
    pbx_should_respond_with_successful_background_response ?9.ord
    pbx_should_respond_with_a_wait_for_digit_timeout

    should_throw :inside_timeout do
      mock_call.menu :timeout => 1 do |link|
        link.something 999
        link.on_premature_timeout { throw :inside_timeout }
      end
    end
    2.times { pbx_should_have_been_sent 'WAIT FOR DIGIT "1000"' }
  end

end

describe "the Menu class's high-level judgment" do

  include DialplanCommandTestHelpers

  it "should match things in ambiguous ranges properly" do
    pbx_should_respond_with_successful_background_response ?1.ord
    pbx_should_respond_with_successful_background_response ?1.ord
    pbx_should_respond_with_successful_background_response ?1.ord
    pbx_should_respond_with_a_wait_for_digit_timeout

    main_context = Adhearsion::DialPlan::DialplanContextProc.new(:main) { throw :got_here! }
    mock_call.should_receive(:main).and_return main_context

    should_pass_control_to_a_context_that_throws :got_here! do
      mock_call.menu do |link|
        link.blah 1
        link.main 11..11111
      end
    end
    111.should === mock_call.extension
    4.times { pbx_should_have_been_sent 'WAIT FOR DIGIT "5000"' }
  end

  it 'should match things in a range when there are many other non-matching patterns' do
    pbx_should_respond_with_successful_background_response ?9.ord
    pbx_should_respond_with_successful_background_response ?9.ord
    pbx_should_respond_with_successful_background_response ?5.ord

    conferences_context = Adhearsion::DialPlan::DialplanContextProc.new(:conferences) { throw :got_here! }
    mock_call.should_receive(:conferences).and_return conferences_context

    should_pass_control_to_a_context_that_throws :got_here! do
      mock_call.menu do |link|
        link.sales        1
        link.tech_support 2
        link.finance      3
        link.conferences  900..999
      end
    end
    3.times { pbx_should_have_been_sent 'WAIT FOR DIGIT "5000"' }
  end

end

describe 'the MenuBuilder' do

  include MenuBuilderTestHelper

  attr_reader :builder
  before(:each) do
    @builder = Adhearsion::VoIP::MenuBuilder.new
  end

  it "should convert each pattern given to it into a MatchCalculator instance" do
    builder.tap do |link|
      link.foo 1,2,3
      link.bar "4", "5", 6
    end

    builder.weighted_match_calculators.size.should == 6
    builder.weighted_match_calculators.each do |match_calculator|
      match_calculator.should be_a_kind_of Adhearsion::VoIP::MatchCalculator
    end
  end

  it "conflicting ranges" do
    builder.tap do |link|
      link.hundreds     100...200
      link.thousands    1_000...2_000
      link.tenthousands 10_000...20_000
    end

    builder_should_match_with_these_quantities_of_calculated_matches \
      1       => {  :exact_match_count => 0, :potential_match_count => 11100 },
      10      => {  :exact_match_count => 0, :potential_match_count => 1110  },
      100     => {  :exact_match_count => 1, :potential_match_count => 110   },
      1_000   => {  :exact_match_count => 1, :potential_match_count => 10    },
      10_000  => {  :exact_match_count => 1, :potential_match_count => 0     },
      100_000 => {  :exact_match_count => 0, :potential_match_count => 0     }

  end

  it 'a String query ran against multiple Numeric patterns and a range' do
    builder.tap do |link|
      link.sales        1
      link.tech_support 2
      link.finance      3
      link.conferences  900..999
    end
    match = builder.calculate_matches_for "995"
    require 'pp'
    # pp match
    match.potential_match?.should_not be true
    match.exact_match?.should be true
    match.actual_exact_matches.should == ["995"]
  end

  it "multiple patterns given at once" do
    builder.tap do |link|
      link.multiple_patterns 1,2,3,4,5,6,7,8,9
      link.multiple_patterns 100..199, 200..299, 300..399, 400..499, 500..599,
                             600..699, 700..799, 800..899, 900..999
    end
    1.upto 9 do |num|
      builder.calculate_matches_for(num).tap do |matches_of_num|
        matches_of_num.potential_match_count.should == 100
        matches_of_num.exact_match_count.should == 1
      end
      builder.calculate_matches_for((num * 100) + 5).tap do |matches_of_num|
        matches_of_num.potential_match_count.should == 0
        matches_of_num.exact_match_count.should == 1
      end
    end
  end

  it "numeric literals that don't match but ultimately would" do
    builder.tap do |link|
      link.nineninenine 999
      link.shouldnt_match 4444
    end
    builder.calculate_matches_for(9).potential_match_count.should == 1
  end

  it "three fixnums that obviously don't conflict" do
    builder.tap do |link|
      link.one   1
      link.two   2
      link.three 3
    end
    [[1,2,3,4,'#'], [1,1,1,0,0]].transpose.each do |(input,expected_matches)|
      matches = builder.calculate_matches_for input
      matches.exact_match_count.should be expected_matches
    end
  end

  it "numerical digits mixed with special digits" do
    builder.tap do |link|
      link.one   '5*11#3'
      link.two   '5***'
      link.three '###'
    end

    builder_should_match_with_these_quantities_of_calculated_matches \
      '5'      => { :potential_match_count => 2, :exact_match_count => 0 },
      '*'      => { :potential_match_count => 0, :exact_match_count => 0 },
      '5**'    => { :potential_match_count => 1, :exact_match_count => 0 },
      '5*1'    => { :potential_match_count => 1, :exact_match_count => 0 },
      '5*11#3' => { :potential_match_count => 0, :exact_match_count => 1 },
      '5*11#4' => { :potential_match_count => 0, :exact_match_count => 0 },
      '5***'   => { :potential_match_count => 0, :exact_match_count => 1 },
      '###'    => { :potential_match_count => 0, :exact_match_count => 1 },
      '##*'    => { :potential_match_count => 0, :exact_match_count => 0 }

  end

  it 'a Fixnum exact match conflicting with a Range that would ultimately match' do
    builder.tap do |link|
      link.single_digit 1
      link.range 100..200
    end
    matches = builder.calculate_matches_for 1
    matches.potential_match_count.should == 100
  end

end

describe 'say_digits command' do
  include DialplanCommandTestHelpers
  it 'Can execute the saydigits application using say_digits' do
    digits = "12345"
    pbx_should_respond_with_success
    mock_call.say_digits digits
    pbx_was_asked_to_execute "saydigits", digits
  end

  it 'Digits that include pound, star, and minus are considered valid' do
    digits = "1#2*3-4"
    mock_call.should_receive(:execute).once.with("saydigits", digits)
    mock_call.say_digits digits
  end

  it 'Cannot pass non-integers into say_digits.  Will raise an ArgumentError' do
    the_following_code {
      mock_call.say_digits 'abc'
    }.should raise_error(ArgumentError)

    the_following_code {
      mock_call.say_digits '1.20'
    }.should raise_error(ArgumentError)
  end

  it 'Digits that start with a 0 are considered valid and parsed properly' do
    digits = "0123"
    mock_call.should_receive(:execute).once.with("saydigits", digits)
    mock_call.say_digits digits
  end

end

describe 'the enable_feature command' do

  include DialplanCommandTestHelpers

  it 'it should fetch the variable for DYNAMIC_FEATURES at first' do
    mock_call.should_receive(:variable).once.with("DYNAMIC_FEATURES").and_throw :got_variable
    should_throw :got_variable do
      mock_call.enable_feature :foobar
    end
  end

  it 'should check Adhearsion::VoIP::Asterisk::Commands::DYNAMIC_FEATURE_EXTENSIONS mapping for configuration setters' do
    feature_name = :attended_transfer

    assertion = lambda do |arg|
      arg.should == :this_is_the_right_arg
      throw :inside_assertion!
    end

    # I had to do this ugly hack because of a bug in Flexmock which prevented me from mocking out Hash#[]  :(
    old_hash_feature_extension = Adhearsion::VoIP::Asterisk::Commands::DYNAMIC_FEATURE_EXTENSIONS[feature_name]
    begin
      Adhearsion::VoIP::Asterisk::Commands::DYNAMIC_FEATURE_EXTENSIONS[feature_name] = assertion
      # </uglyhack>
      should_throw :inside_assertion! do
        mock_call.enable_feature(feature_name, :this_is_the_right_arg)
      end
    ensure
      Adhearsion::VoIP::Asterisk::Commands::DYNAMIC_FEATURE_EXTENSIONS[feature_name] = old_hash_feature_extension
    end
  end

  it 'should separate enabled features with a "#"' do
    mock_call.should_receive(:variable).once.with("DYNAMIC_FEATURES").and_return("one")
    mock_call.should_receive(:variable).once.with("DYNAMIC_FEATURES" => 'one#bar')
    mock_call.enable_feature "bar"
  end

  it 'should not add duplicate enabled dynamic features' do
    mock_call.should_receive(:variable).once.and_return('eins#zwei')
    mock_call.enable_feature "eins"
  end

  it 'should raise an ArgumentError if optional options are given when DYNAMIC_FEATURE_EXTENSIONS does not have a key for the feature name' do
    the_following_code {
      mock_call.enable_feature :this_is_not_recognized, :these_features => "are not going to be recognized"
    }.should raise_error ArgumentError
  end

  it 'enabling :attended_transfer should actually enable the atxfer feature' do
    mock_call.should_receive(:variable).once.with("DYNAMIC_FEATURES").and_return ''
    mock_call.should_receive(:variable).once.with("DYNAMIC_FEATURES" => 'atxfer')
    mock_call.enable_feature :attended_transfer
  end

  it 'the :context optional option when enabling :attended_transfer should set the TRANSFER_CONTEXT variable to the String supplied as a Hash value' do
    context_name = "direct_dial"
    mock_call.should_receive(:variable).once.with("DYNAMIC_FEATURES").and_return ''
    mock_call.should_receive(:variable).once.with("DYNAMIC_FEATURES" => 'atxfer')
    mock_call.should_receive(:variable).once.with("TRANSFER_CONTEXT" => context_name)
    mock_call.enable_feature :attended_transfer, :context => context_name
  end

  it 'enabling :attended_transfer should not add a duplicate if atxfer has been enabled, but it should still set the TRANSFER_CONTEXT variable' do
    context_name = 'blah'
    mock_call.should_receive(:variable).once.with('DYNAMIC_FEATURES').and_return 'atxfer'
    mock_call.should_receive(:variable).once.with('TRANSFER_CONTEXT' => context_name)
    mock_call.enable_feature :attended_transfer, :context => context_name
  end

end

describe 'the disable_feature command' do

  include DialplanCommandTestHelpers

  it "should properly remove the feature from the DYNAMIC_FEATURES variable" do
    mock_call.should_receive(:variable).once.with('DYNAMIC_FEATURES').and_return 'foobar#qaz'
    mock_call.should_receive(:variable).once.with('DYNAMIC_FEATURES' => 'qaz')
    mock_call.disable_feature "foobar"
  end

  it "should not re-set the variable if the feature wasn't enabled in the first place" do
    mock_call.should_receive(:variable).once.with('DYNAMIC_FEATURES').and_return 'atxfer'
    mock_call.should_receive(:variable).never
    mock_call.disable_feature "jay"
  end

end

describe 'jump_to command' do

  include DialplanCommandTestHelpers

  it 'when given a DialplanContextProc as the only argument, it should raise a ControlPassingException with that as the target' do
    # Having to do this ugly hack because I can't do anything with the exception once I set up an expectation with it normally.
    dialplan_context = Adhearsion::DialPlan::DialplanContextProc.new("my_context") {}
    should_throw :finishing_the_rescue_block do
      begin
        mock_call.jump_to dialplan_context
      rescue Adhearsion::VoIP::DSL::Dialplan::ControlPassingException => cpe
        cpe.target.should be dialplan_context
        throw :finishing_the_rescue_block
      end
    end
  end

  it 'when given a String, it should perform a lookup of the context name' do
    context_name = 'cool_context'
    mock_call.should_receive(context_name).once.and_throw :found_context!
    should_throw :found_context! do
      mock_call.jump_to context_name
    end
  end

  it 'when given a Symbol, it should perform a lookup of the context name' do
    context_name = :cool_context
    mock_call.should_receive(context_name).once.and_throw :found_context!
    should_throw :found_context! do
      mock_call.jump_to context_name
    end
  end

  it "a clearly invalid context name should raise a ContextNotFoundException" do
    bad_context_name = ' ZOMGS this is A REALLY! STUPID context name . wtf were you thinking?!'
    the_following_code {
      mock_call.jump_to bad_context_name
    }.should raise_error Adhearsion::VoIP::DSL::Dialplan::ContextNotFoundException
  end

  it 'when given an :extension override, the new value should be boxed in a PhoneNumber' do
    my_context = Adhearsion::DialPlan::DialplanContextProc.new("my_context") {}
    begin
      mock_call.jump_to my_context, :extension => 1337
    rescue Adhearsion::VoIP::DSL::Dialplan::ControlPassingException
      # Eating this exception
    end
    mock_call.extension.__real_num.should == 1337
  end

  it 'other overrides should be simply metadef()d' do
    test_context = Adhearsion::DialPlan::DialplanContextProc.new("test_context") {}
    begin
      mock_call.jump_to test_context, :caller_id => 1_444_555_6666
    rescue Adhearsion::VoIP::DSL::Dialplan::ControlPassingException
      # Eating this exception
    end
    mock_call.caller_id.should == 1_444_555_6666
  end

end

describe "get variable command" do
  include DialplanCommandTestHelpers

  it "Getting a variable that isn't set returns nothing" do
    pbx_should_respond_with "200 result=0"
    mock_call.get_variable('OMGURFACE').should be nil
    pbx_should_have_been_sent 'GET VARIABLE "OMGURFACE"'
  end

  it 'An empty variable should return an empty String' do
    pbx_should_respond_with_value ""
    mock_call.get_variable('kablamm').should == ""
    pbx_should_have_been_sent 'GET VARIABLE "kablamm"'
  end

  it "Getting a variable that is set returns its value" do
    unique_id = "1192470850.1"
    pbx_should_respond_with_value unique_id
    variable_value_returned = mock_call.get_variable('UNIQUEID')
    variable_value_returned.should == unique_id
    pbx_should_have_been_sent 'GET VARIABLE "UNIQUEID"'
  end
end

describe "duration_of command" do
  include DialplanCommandTestHelpers

  it "Duration of must take a block" do
    the_following_code {
      mock_call.duration_of
    }.should raise_error(LocalJumpError)
  end

  it "Passed block to duration of is actually executed" do
    the_following_code {
      mock_call.duration_of {
        throw :inside_duration_of
      }
    }.should throw_symbol :inside_duration_of
  end

  it "Duration of block is returned" do
    start_time = Time.parse('9:25:00')
    end_time   = Time.parse('9:25:05')
    expected_duration = end_time - start_time

    flexmock(Time).should_receive(:now).twice.and_return(start_time, end_time)
    duration = mock_call.duration_of {
      # This doesn't matter
    }

    duration.should == expected_duration
  end
end

describe "Dial command" do
  include DialplanCommandTestHelpers

  it "should set the caller id if the caller_id option is specified" do
    does_not_read_data_back
    mock_call.should_receive(:set_caller_id_number).once
    mock_call.dial 123, :caller_id => "1234678901"
    pbx_should_have_been_sent 'EXEC Dial "123"|""|""'
  end

  it 'should raise an exception when unknown hash key arguments are given to it' do
    the_following_code {
      mock_call.dial 123, :asjndfhasndfahsbdfbhasbdfhabsd => "asbdfhabshdfbajhshfbajsf"
    }.should raise_error ArgumentError
  end

  it 'should set the caller ID name when given the :name hash key argument' do
    does_not_read_data_back
    name = "Jay Phillips"
    mock_call.should_receive(:set_caller_id_name).once.with(name)
    mock_call.dial "BlahBlahBlah", :name => name
    pbx_should_have_been_sent 'EXEC Dial "BlahBlahBlah"|""|""'
  end

  it "should raise an exception when a non-numerical caller_id is specified" do
    the_following_code {
      mock_call.dial 911, :caller_id => "zomgz"
    }.should raise_error ArgumentError
  end

  it "should not raise an exception when a caller_id is specified in E.164 format (with '+' sign)" do
    the_following_code {
      mock_call.dial 911, :caller_id => "+123456789"
    }.should_not raise_error ArgumentError
    pbx_should_have_been_sent 'SET VARIABLE "CALLERID(num)" "+123456789"'
  end

  it 'should pass the value of the :confirm key to dial_macro_option_compiler()' do
    does_not_read_data_back
    value_of_confirm_key = {:play => "ohai", :timeout => 30}
    mock_call.should_receive(:dial_macro_option_compiler).once.with value_of_confirm_key
    mock_call.dial 123, :confirm => value_of_confirm_key
    pbx_should_have_been_sent 'EXEC Dial "123"|""|""'
  end

  it "should add the return value of dial_macro_option_compiler to the :options key's value given to the dial command" do
    channel   = "SIP/1337"
    macro_arg = "THISSHOULDGETPASSEDTOASTERISK"
    timeout   = 10
    options   = 'hH'

    mock_call.should_receive(:dial_macro_option_compiler).once.and_return macro_arg
    mock_call.should_receive(:execute).with('Dial', channel, timeout, options + macro_arg)
    mock_call.dial channel, :for => timeout, :confirm => true, :options => options
  end

  it 'should add the return value of dial_macro_option_compiler to the options field when NO :options are given' do
    channel   = "SIP/1337"
    macro_arg = "THISSHOULDGETPASSEDTOASTERISK"
    timeout   = 10
    options   = 'hH'

    mock_call.should_receive(:dial_macro_option_compiler).once.and_return macro_arg
    mock_call.should_receive(:execute).with('Dial', channel, timeout, options + macro_arg)
    mock_call.dial channel, :for => timeout, :confirm => true, :options => options
  end

end

describe "The Dial command's :confirm option setting builder" do

  include DialplanCommandTestHelpers

  attr_reader :formatter
  before :each do
    @formatter = mock_call.method :dial_macro_option_compiler
  end

  it 'should allow passing in the :confirm named argument with true' do
    the_following_code {
      formatter.call true
    }.should_not raise_error ArgumentError
  end

  it 'should separate :play options with "++"' do
    sound_files = *1..10
    formatter.call(:play => sound_files).should include sound_files.join('++')
  end

  it 'should raise an ArgumentError if an invalid Hash key is given' do
    the_following_code {
      formatter.call :this_symbol_is_not_valid => 123
    }.should raise_error ArgumentError
  end

  it "should raise an ArgumentError if the argument's class is not recognized" do
    the_following_code {
      formatter.call Time.now # Time is an example strange case
    }.should raise_error ArgumentError
  end

  it 'should return the contents within a M() Dial argument' do
    formatter.call(true).should =~ /^M\(.+\)$/
  end

  it 'should replace the default macro name when given the :macro options' do
    macro_name = "ivegotalovelybunchofcoconuts"
    formatter.call(:macro => macro_name).starts_with?("M(#{macro_name}").should be true
  end

  it 'should allow a symbol macro name' do
    the_following_code {
      formatter.call(:macro => :foo)
    }.should_not raise_error ArgumentError
  end

  it 'should only allow alphanumeric and underscores in the macro name' do
    bad_options = ["this has a space", "foo,bar", 'exists?', 'x^z', '', "!&@&*^!@"]
    bad_options.each do |bad_option|
      the_following_code {
        formatter.call(:macro => bad_option)
      }.should raise_error ArgumentError
    end
  end

  it 'should confirm :timeout => :none to 0' do
    formatter.call(:timeout => :none).should include "timeout:0"
  end

  it 'should separate the macro name and the arguments with a caret (^)' do
    formatter.call(:macro => "jay").should =~ /M\(jay\^.+/
  end

  it 'should raise an ArgumentError if a caret existed anywhere in the resulting String' do
    # FIXME: Duplicate hash key
    bad_options = [{:play => "foo^bar", :key => "^", :play => ["hello-world", 'lol^cats']}]
    bad_options.each do |bad_option|
      the_following_code {
        formatter.call(bad_option)
      }.should raise_error ArgumentError
    end
  end

  it 'should raise an ArgumentError if the :key is not [0-9#*]' do
    bad_options = %w[& A $ @ . )]
    bad_options.each do |bad_option|
      the_following_code {
        formatter.call :key => bad_option
      }.should raise_error ArgumentError
    end
  end

  it 'should raise an ArgumentError if the key is longer than one digit' do
    the_following_code {
      formatter.call :key => "55"
    }.should raise_error ArgumentError
  end

  it 'should raise an ArgumentError if the timeout is not numeric and not :none' do
    bad_options = [:nonee, Time.now, method(:inspect)]
    bad_options.each do |bad_option|
      the_following_code {
        formatter.call bad_option
      }.should raise_error ArgumentError
    end
  end

  it 'should support passing a String argument as a timeout' do
    the_following_code {
      formatter.call :timeout => "123"
    }.should_not raise_error ArgumentError
  end

  it 'should raise an ArgumentError if given a Float' do
    the_following_code {
      formatter.call :timeout => 100.0012
    }.should raise_error ArgumentError
  end

  it 'should allow passing a ActiveSupport::Duration to :timeout' do
    the_following_code {
      formatter.call :timeout => 3.minutes
    }.should_not raise_error ArgumentError
  end

end

describe 'the dtmf command' do

  include DialplanCommandTestHelpers

  it 'should send the proper AGI command' do
    does_not_read_data_back
    digits = '8404#4*'
    mock_call.dtmf digits
    pbx_should_have_been_sent "EXEC SendDTMF \"#{digits}\""
  end
end

describe "the last_dial_status command and family" do

  include DialplanCommandTestHelpers

  it 'should convert common DIALSTATUS variables to their appropriate symbols' do
    mock_call.should_receive(:variable).with("DIALSTATUS").once.and_return('ANSWER')
    mock_call.last_dial_status.should be :answered

    mock_call.should_receive(:variable).with("DIALSTATUS").once.and_return('CONGESTION')
    mock_call.last_dial_status.should be :congested

    mock_call.should_receive(:variable).once.with("DIALSTATUS").and_return("BUSY")
    mock_call.last_dial_status.should be :busy

    mock_call.should_receive(:variable).once.with("DIALSTATUS").and_return("CANCEL")
    mock_call.last_dial_status.should be :cancelled

    mock_call.should_receive(:variable).once.with("DIALSTATUS").and_return("NOANSWER")
    mock_call.last_dial_status.should be :unanswered

    mock_call.should_receive(:variable).once.with("DIALSTATUS").and_return("CHANUNAVAIL")
    mock_call.last_dial_status.should be :channel_unavailable

    mock_call.should_receive(:variable).once.with("DIALSTATUS").and_return("THISISNOTVALID")
    mock_call.last_dial_status.should be :unknown
  end

  it 'last_dial_successful? should return true if last_dial_status == :answered' do
    mock_call.should_receive(:variable).with("DIALSTATUS").once.and_return('ANSWER')
    mock_call.last_dial_successful?.should be true

    mock_call.should_receive(:variable).with("DIALSTATUS").once.and_return('CHANUNAVAIL')
    mock_call.last_dial_successful?.should be false
  end

  it 'last_dial_unsuccessful? should be the opposite of last_dial_successful?' do
    mock_call.should_receive(:variable).with("DIALSTATUS").once.and_return('ANSWER')
    mock_call.last_dial_unsuccessful?.should be false

    mock_call.should_receive(:variable).with("DIALSTATUS").once.and_return('CHANUNAVAIL')
    mock_call.last_dial_unsuccessful?.should be true
  end

  it 'last_dial_status should not blow up if variable() returns nil. it should return :cancelled' do
    the_following_code {
      mock_call.should_receive(:variable).once.with("DIALSTATUS").and_return nil
      mock_call.last_dial_status.should be :cancelled

      mock_call.should_receive(:variable).once.with("DIALSTATUS").and_return nil
      mock_call.last_dial_successful?.should be false
    }.should_not raise_error
  end

end

describe "set_caller_id_number command" do
  include DialplanCommandTestHelpers

  it "should encapsulate the number with quotes" do
    caller_id = "14445556666"
    mock_call.should_receive(:raw_response).once.with(%(SET VARIABLE "CALLERID(num)" "#{caller_id}")).and_return true
    mock_call.send(:set_caller_id_number, caller_id)
  end
end

describe 'set_caller_id_name command' do
  include DialplanCommandTestHelpers

  it "should wrap the name in quotes" do
    name = "Jay Phillips"
    mock_call.should_receive(:raw_response).once.with(%(SET VARIABLE "CALLERID(name)" "#{name}")).and_return true
    mock_call.send(:set_caller_id_name, name)
  end
end

describe "speak command" do
  include DialplanCommandTestHelpers

  before :all do
    @speech_engines = Adhearsion::VoIP::Asterisk::Commands::SpeechEngines
  end

  it "executes the command SpeechEngine gives it based on the engine name" do
    pbx_should_respond_with_success
    flexmock(@speech_engines).should_receive(:cepstral).once
    mock_call.speak "Spoken text doesn't matter", :engine => :cepstral
  end

  it "raises an InvalidSpeechEngine exception when the engine is 'none'" do
    the_following_code {
      mock_call.speak("o hai!", :engine => :none)
    }.should raise_error @speech_engines::InvalidSpeechEngine
  end

  it "should default its engine to :none" do
    the_following_code {
      flexmock(@speech_engines).should_receive(:none).once.
        and_raise(@speech_engines::InvalidSpeechEngine)
      mock_call.speak "ruby ruby ruby ruby!"
    }.should raise_error @speech_engines::InvalidSpeechEngine
  end

  it 'should default to a configured TTS engine' do
    Adhearsion::Configuration.configure {|c| c.asterisk.speech_engine = :unimrcp }
    flexmock(@speech_engines).should_receive(:unimrcp).once
    mock_call.speak 'What say you, sir?'
  end

  it 'should allow the caller to override the default configured TTS engine' do
    Adhearsion::Configuration.configure {|c| c.asterisk.speech_engine = :unimrcp }
    flexmock(@speech_engines).should_receive(:cepstral).once
    mock_call.speak 'What say you now, sir?', :engine => :cepstral
  end

  it 'should default to uninterruptible TTS rendering' do
    flexmock(@speech_engines).should_receive(:cepstral).once.with(mock_call, 'hello', {:interruptible => false})
    mock_call.speak 'hello', :engine => :cepstral
  end

  it 'should allow setting TTS rendering interruptible' do
    flexmock(@speech_engines).should_receive(:cepstral).once.with(mock_call, 'hello', {:interruptible => true})
    mock_call.speak 'hello', :engine => :cepstral, :interruptible => true
  end

  it "should stringify the text" do
    flexmock(@speech_engines).should_receive(:cepstral).once.with(mock_call, 'hello', {:interruptible => false})
    mock_call.speak :hello, :engine => :cepstral
  end

  context "with the engine :cepstral" do
    it "should execute Swift"do
      pbx_should_respond_with_value 0
      mock_call.should_receive(:execute).with('Swift', 'hello')
      @speech_engines.cepstral(mock_call, 'hello')
      @output.read.should == "GET VARIABLE \"SWIFT_DTMF\"\n"
    end

    it "should properly escape commas in the TTS string" do
      pbx_should_respond_with_value 0
      mock_call.should_receive(:execute).with('Swift', 'Once\, a long\, long time ago\, ...')
      @speech_engines.cepstral(mock_call, 'Once, a long, long time ago, ...')
      @output.read.should == "GET VARIABLE \"SWIFT_DTMF\"\n"
    end

    it "should properly escape double-quotes (for XML) in the TTS string" do
      mock_call.should_receive(:raw_response).once.with('EXEC MRCPSynth "<speak xmlns=\\\\\"http://www.w3.org/2001/10/synthesis\\\\\" version=\\\\\"1.0\\\\\" xml:lang=\\\\\"en-US\\\\\"> <voice name=\\\\\"Paul\\\\\"> <prosody rate=\\\\\"1.0\\\\\">Howdy, stranger. How are you today?</prosody> </voice> </speak>"').and_return pbx_success_response
      @speech_engines.unimrcp(mock_call, '<speak xmlns="http://www.w3.org/2001/10/synthesis" version="1.0" xml:lang="en-US"> <voice name="Paul"> <prosody rate="1.0">Howdy, stranger. How are you today?</prosody> </voice> </speak>')
    end

    context "with barge in digits set" do
      it "should return the digit when :interruptible = true" do
        mock_call.should_receive(:execute).once.with('Swift', 'hello', 1, 1).and_return pbx_success_response
        mock_call.should_receive(:get_variable).once.with('SWIFT_DTMF').and_return ?1
        @speech_engines.cepstral(mock_call, 'hello', :interruptible => true).should == ?1
      end
    end
  end

  context "with the engine :unimrcp" do
    it "should execute MRCPSynth" do
      pbx_should_respond_with_success
      mock_call.should_receive(:execute).with('MRCPSynth', 'hello').once.and_return pbx_success_response
      @speech_engines.unimrcp(mock_call, 'hello')
    end

    context "with barge in digits set" do
      it "should pass the i option for MRCPSynth" do
        mock_call.should_receive(:execute).with('MRCPSynth', 'hello', 'i=any').once.and_return pbx_result_response 0
        @speech_engines.unimrcp(mock_call, 'hello', :interrupt_digits => 'any')
      end
    end
  end

  context "with the engine :tropo" do
    it "should execute tropo" do
      pbx_should_respond_with_success
      response = '200 result=' + {:interpretation => '1'}.to_json
      mock_call.should_receive(:raw_response).with(/Ask/i, 'hello').once.and_return response
      @speech_engines.tropo(mock_call, 'hello').should == "1"
    end

    context "with :interruptible set to false"do
      it "should pass the :bargein => false option for Tropo Ask" do
        response = '200 result=' + {:interpretation => '1'}.to_json
        mock_call.should_receive(:raw_response).with(/Ask/i, 'hello', {:bargein => false}.to_json).once.and_return response
        @speech_engines.tropo(mock_call, 'hello', :interruptible => false)
      end
    end
  end

  it "properly escapes spoken text" do
    pending 'What are the escaping needs?'
  end
end

describe 'The join command' do

  include DialplanCommandTestHelpers

  it "should pass the 'd' flag when no options are given" do
    conference_id = "123"
    mock_call.should_receive(:execute).once.with("MeetMe", conference_id, "d", nil)
    mock_call.join conference_id
  end

  it "should pass through any given flags with 'd' appended to it if necessary" do
    conference_id, flags = "1000", "zomgs"
    mock_call.should_receive(:execute).once.with("MeetMe", conference_id, flags + "d", nil)
    mock_call.join conference_id, :options => flags
  end

  it "should NOT pass the 'd' flag when requiring static conferences" do
    conference_id, options = "1000", {:use_static_conf => true}
    mock_call.should_receive(:execute).once.with("MeetMe", conference_id, "", nil)
    mock_call.join conference_id, options
  end

  it "should raise an ArgumentError when the pin is not numerical" do
    the_following_code {
      mock_call.should_receive(:execute).never
      mock_call.join 3333, :pin => "letters are bad, mkay?!1"
    }.should raise_error ArgumentError
  end

  it "should strip out illegal characters from a conference name" do
    bizarre_conference_name = "a-    bc!d&&e--`"
    normal_conference_name = "abcde"
    mock_call.should_receive(:execute).twice.with("MeetMe", normal_conference_name, "d", nil)

    mock_call.join bizarre_conference_name
    mock_call.join normal_conference_name
  end

  it "should allow textual conference names" do
    the_following_code {
      mock_call.should_receive(:execute).once.with_any_args
      mock_call.join "david bowie's pants"
    }.should_not raise_error
  end

end


describe 'the DialPlan::ConfirmationManager' do

  include ConfirmationManagerTestHelper
  include DialplanCommandTestHelpers

  attr_reader :example_encoded_hash, :example_encoded_hash_without_macro_name
  before :each do
    @example_encoded_hash_without_macro_name = 'timeout:20!play:foo-bar++qaz_qwerty.gsm!key:#'
    @example_encoded_hash = 'confirm!' + @example_encoded_hash_without_macro_name
  end

  it '::decode_hash() should convert the String of key/value escaped pairs into a Hash with Symbol keys when the macro name is not given' do
    Adhearsion::DialPlan::ConfirmationManager.decode_hash(example_encoded_hash).should ==
      {:timeout => 20, :play => ['foo-bar', 'qaz_qwerty.gsm'], :key => '#'}
  end

  it '::decode_hash() should convert the String of key/value escaped pairs into a Hash with Symbol keys when the macro name is not given' do
    Adhearsion::DialPlan::ConfirmationManager.decode_hash(example_encoded_hash_without_macro_name).should ==
      {:timeout => 20, :play => ['foo-bar', 'qaz_qwerty.gsm'], :key => '#'}
  end

  it '::decode_hash() should split the sound files in the :play key to an array by splitting by "++"' do
    decoded_sound_files = Adhearsion::DialPlan::ConfirmationManager.decode_hash(example_encoded_hash)[:play]
    decoded_sound_files.should be_a_kind_of Array
    decoded_sound_files.size.should == 2
  end

  it 'a call to a party which is acknowledged with the proper key during the call to interruptible_play' do
    variables         = {:timeout => 20, :play => ['foo-bar', 'qaz_qwerty.gsm'], :key => '#', :macro => 'confirmer'}
    encoded_variables = {:network_script => encode_hash(variables)}
    io_mock           = StringIO.new

    mock_call.should_receive(:originating_voip_platform).once.and_return :asterisk
    mock_call.should_receive(:variables).once.and_return encoded_variables

    sound_files = variables[:play]

    manager = Adhearsion::DialPlan::ConfirmationManager.new(mock_call)

    flexstub(manager).should_receive(:result_digit_from).and_return ?0.ord
    flexstub(manager).should_receive(:raw_response).and_return nil

    flexmock(manager).should_receive(:answer).once
    flexmock(manager).should_receive(:interruptible_play).once.with(*sound_files).and_return '#'

    manager.handle
  end

  it 'when an timeout is encountered, it should set the MACRO_RESULT variable to CONTINUE' do
    variables = {:timeout => 20, :play => ['foo-bar', 'qaz_qwerty.gsm'], :key => '#', :macro => 'confirmer'}
    encoded_variables = {:network_script => encode_hash(variables)}
    io_mock           = StringIO.new

    mock_call.should_receive(:originating_voip_platform).once.and_return :asterisk
    mock_call.should_receive(:variables).once.and_return encoded_variables

    sound_files = variables[:play]

    manager = Adhearsion::DialPlan::ConfirmationManager.new(mock_call)

    flexstub(manager).should_receive(:result_digit_from).and_return ?0.ord
    flexstub(manager).should_receive(:raw_response).and_return nil

    flexmock(manager).should_receive(:answer).once
    flexmock(manager).should_receive(:interruptible_play).once.with(*sound_files).and_return nil
    flexmock(manager).should_receive(:wait_for_digit).once.with(20).and_return nil

    flexmock(manager).should_receive(:variable).once.with("MACRO_RESULT" => 'CONTINUE')

    manager.handle
  end

  it 'should wait the :timeout number of seconds if no digit was received when playing the files and continue when the right key is pressed' do
    variables         = {:timeout => 20, :play => ['foo-bar', 'qaz_qwerty.gsm'], :key => '#', :macro => 'confirmer'}
    encoded_variables = {:network_script => encode_hash(variables)}
    io_mock           = StringIO.new

    mock_call.should_receive(:originating_voip_platform).once.and_return :asterisk
    mock_call.should_receive(:variables).once.and_return encoded_variables

    sound_files = variables[:play]

    manager = Adhearsion::DialPlan::ConfirmationManager.new(mock_call)

    flexstub(manager).should_receive(:result_digit_from).and_return ?0.ord
    flexstub(manager).should_receive(:raw_response).and_return nil

    flexmock(manager).should_receive(:answer).once
    flexmock(manager).should_receive(:interruptible_play).once.with(*sound_files).and_return nil
    flexmock(manager).should_receive(:wait_for_digit).once.with(20).and_return '#'

    manager.handle
  end

  it 'should restart playback if the key received was not recognized' do
    variables = {:timeout => 20, :play => ['foo-bar', 'qaz_qwerty.gsm'], :key => '2', :macro => 'confirmer'}
    encoded_variables = {:network_script => encode_hash(variables)}
    io_mock           = StringIO.new

    mock_call.should_receive(:originating_voip_platform).once.and_return :asterisk
    mock_call.should_receive(:variables).once.and_return encoded_variables

    sound_files = variables[:play]

    manager = Adhearsion::DialPlan::ConfirmationManager.new(mock_call)

    flexstub(manager).should_receive(:result_digit_from).and_return ?0.ord
    flexstub(manager).should_receive(:raw_response).and_return nil

    flexmock(manager).should_receive(:answer).once
    flexmock(manager).should_receive(:interruptible_play).once.with(*sound_files).and_return '3' # not :key
    flexmock(manager).should_receive(:interruptible_play).once.with(*sound_files).and_return '#' # not :key
    flexmock(manager).should_receive(:interruptible_play).once.with(*sound_files).and_return '1' # not :key
    flexmock(manager).should_receive(:interruptible_play).once.with(*sound_files).and_return '2' # matches :key

    flexmock(manager).should_receive(:wait_for_digit).never # We never let it get to the point where it may timeout
    flexmock(manager).should_receive(:variable).never # We succeed by not setting the MACRO_RESULT variable

    manager.handle
  end

end

describe 'say_phonetic command' do
  include DialplanCommandTestHelpers
  it 'Can execute the sayphonetic application using say_phonetic' do
    text = 'Say This'
    mock_call.should_receive(:execute).once.with("sayphonetic", text)
    mock_call.say_phonetic text
  end

  it 'Can use special characters with say_phonetic' do
    text = '*Say This!*'
    mock_call.should_receive(:execute).once.with("sayphonetic", text)
    mock_call.say_phonetic text
  end
end

describe 'say_chars command' do
  include DialplanCommandTestHelpers
  it 'Can execute the sayalpha application using say_chars' do
    text = 'ha124d9'
    mock_call.should_receive(:execute).once.with("sayalpha", text)
    mock_call.say_chars text
  end

  it 'Can use special characters with say_chars' do
    text = "1a2.#"
    mock_call.should_receive(:execute).once.with("sayalpha", text)
    mock_call.say_chars text
  end
end
