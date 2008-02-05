require File.dirname(__FILE__) + "/../../test_helper"  

context 'Asterisk VoIP Commands' do
  include DialplanCommandTestHelpers
  
  test "a call can write back to the PBX" do
    message = 'oh hai'
    mock_call.write message
    pbx_should_have_been_sent message
  end
end

context 'hangup command' do
  include DialplanCommandTestHelpers
  
  test "hanging up a call succesfully writes HANGUP back to the PBX and a success resopnse is returned" do
    pbx_should_respond_with_success
    response = mock_call.hangup
    pbx_should_have_been_sent 'HANGUP'
    response.should.equal pbx_success_response
  end
end

context 'execute' do
  include DialplanCommandTestHelpers
  
  test 'execute writes exec and app name to the PBX' do
    pbx_should_respond_with_success
    assert_success mock_call.execute(:foo)
    pbx_should_have_been_sent 'EXEC foo '
  end
  
  test 'execute returns false if the command was not executed successfully by the PBX' do
    pbx_should_respond_with_failure
    assert !mock_call.execute(:foo), "execute should have failed"
  end
  
  test 'execute can accept arguments after the app name which get translated into pipe-delimited arguments to the PBX' do
    pbx_should_respond_with_success
    mock_call.execute :foo, 'bar', 'baz', 'hi'
    pbx_should_have_been_sent 'EXEC foo bar|baz|hi'
  end
end

context 'play command' do
  include DialplanCommandTestHelpers
  
  test 'passing a single string to play results in the playback application being executed with that file name on the PBX' do
    pbx_should_respond_with_success
    audio_file = "cents-per-minute"
    mock_call.play audio_file
    pbx_was_asked_to_play audio_file
  end
  
  test 'multiple strings can be passed to play, causing multiple playback commands to be issued' do
    2.times do 
      pbx_should_respond_with_success
    end
    audio_files = ["cents-per-minute", 'o-hai']
    mock_call.play(*audio_files)
    pbx_was_asked_to_play(*audio_files)
  end
  
  test 'If a number is passed to play(), the saynumber application is executed with the number as an argument' do
    pbx_should_respond_with_success
    mock_call.play 123
    pbx_was_asked_to_play_number(123)
  end
  
  test 'if a string representation of a number is passed to play(), the saynumber application is executed with the number as an argument' do
    pbx_should_respond_with_success
    mock_call.play '123'
    pbx_was_asked_to_play_number(123)
  end
  
  test 'If a Time is passed to play(), the SayUnixTime application will be executed with the time since the UNIX epoch in seconds as an argument' do
    time = Time.parse("12/5/2000")
    pbx_should_respond_with_success
    mock_call.play time
    pbx_was_asked_to_play_time(time.to_i)
  end 
   
  disabled_test 'If a string matching dollars and (optionally) cents is passed to play(), a series of command will be executed to read the dollar amount' do
    #TODO: I think we should not have this be part of play().  Too much functionality in one method. Too much overloading.  When we want to support multiple
    # currencies, it'll be completely unwieldy.  I'd suggest play_currency as a separate method. - Chad
  end
end

context 'input command' do
  include DialplanCommandTestHelpers
  
  test 'Can ask user for a specified number of digits worth of input via buttons on their phone' do
    pbx_should_respond_with_digits('1234')
    mock_call.input(4)
    pbx_was_asked_for_input(4)
  end
  
  test 'Does properly convert timeouts from seconds to milliseconds when applicable' do
    timeout = 1.minute
    pbx_should_respond_with_digits('4321')
    mock_call.input(4, :timeout => timeout)
    pbx_was_asked_for_input(4, :timeout => 1.minute)
    
    default_timeout_which_asterisk_interprets_as_infinity = -1
    pbx_should_respond_with_digits('4321')
    mock_call.input(4)
    pbx_was_asked_for_input(4, :timeout => default_timeout_which_asterisk_interprets_as_infinity)
  end
  
  test 'Can optionally ask for a specific termination sound when calling input()' do
    pbx_should_respond_with_digits('54321')
    mock_call.input(5, :play => 'arkansas')
    pbx_was_asked_for_input(5, :play => 'arkansas')
  end
  
  test 'Input getting a failure response returns false' do
    pbx_should_respond_with_failure
    assert !mock_call.input(1), "the pbx did not respond with failure"
  end
  
  test 'Input timing out when no digits are pressed returns false' do
    timeout = 1.minute
    pbx_should_respond_to_timeout " (timeout)"
    assert !mock_call.input(2, :timeout => timeout), "the pbx did not respond with failure"
  end
  
  test "Input timing out when digits are pressed returns those digits" do
    timeout = 1.minute
    pbx_should_respond_with_digits_and_timeout 1
    mock_call.input(9, :timeout => timeout).should == '1'
  end
  
  test 'Both possible input timeout responses are recognized' do
    timeout_results = ['200 result=123 (timeout)', '200 result= (timeout)']
    timeout_results.each do |timeout_result|
      assert mock_call.send(:input_timed_out?, timeout_result), "'#{timeout_result}' should have been recognized as a timeout"
    end
  end
end

context 'menu command' do
  
  include DialplanCommandTestHelpers
  
  # Just here for reference
  lambda do
    menu sound_files, :tries => 3, :timeout => 10  do |link|
      link.sales 1
      link.tech_support 2
      link.finance 3
      link.employee? { |str| @search = Employee.with_extension_like str }
      link.conferences 1_000...10_000
      link.on :premature_timeout do |str|
        # Say: Are you still there? Please enter a digit.
      end
      link.on :invalid do |str|
      
      end
      link.on :failure do |str|
      
      end
    end
  end
  
  test "invoke on_timeout() when a timeout is encountered" do
    pbx_should_respond_with_successful_background_response
    pbx_should_respond_with_a_wait_for_digit_timeout
    should_throw :inside_timeout do
      mock_call.menu :timeout => 1 do |link|
        link.foobar?    { [1,2,3] }
        link.on(:timeout) { throw :inside_timeout }
      end
    end
  end
  
  test "should play the sound files in sequence" do
    3.times { pbx_should_respond_with_successful_background_response }
    pbx_should_respond_with_a_wait_for_digit_timeout
    mock_call.menu 'one', 'two', 'three' do |link|
      link.foobar? { [1,2,3] }
      
    end
  end
  test "should work with no arguments at all"
  test "should not play subsequent sound files after a digit is pressed"
  test "should default the timeout to five seconds"
  test "record arbitrary names given to the yielded object"
  test "invoke blocks given to methods with a question mark on the end of them"
  test "invoke the dialplan context when no other extensions could possibly match the string"
  test "not invoke a dialplan context when multiple potential matches exist"
  test "invoke a dialplan context that matches exactly, despite other potential matches, when a timeout is encountered"
  test "invoke the dialplan context given before a question mark if the block evaluates to true"
  test "should perform the IVR logic n times, where n is the value of the :tries Hash-key argument"
  test "on:invalid must be executed when the user enters a series of digits that don't match anything"
  test "on:failure must be executed when all tries have elapsed"
  test "on:invalid should be executed before on:failure"
  test "the 'extension' dialplan variable should be redefined when menu() jumps to a new context"
end

context 'interruptable_play command' do
  
  include DialplanCommandTestHelpers
  
  test 'should return a string for the digit that was pressed' do
    digits = [?0, ?1, ?#, ?*, ?9]
    file = "file_doesnt_matter"
    digits.each { |digit| pbx_should_respond_with_success digit }
    digits.map  { |digit| mock_call.send(:interruptable_play, file) }.should == digits.map(&:chr)
  end
  
  test "should return nil if no digit was pressed" do
    pbx_should_respond_with_success 0
    mock_call.send(:interruptable_play, 'foobar').should.equal nil
  end
  
  test "should play a series of files, stopping the series when a digit is played" do
    stubbed_keypad_input = [0, 0, ?3]
    stubbed_keypad_input.each do |digit|
      pbx_should_respond_with_success digit
    end
    
    files = (100..105).map &:to_s
    mock_call.send(:interruptable_play, *files).should == '3'
  end
  
end

context 'wait_for_digit command' do
  
  include DialplanCommandTestHelpers
  
  test 'should return a string for the digit that was pressed' do
    digits = [?0, ?1, ?#, ?*, ?9]
    digits.each { |digit| pbx_should_respond_with_success digit }
    digits.map  { |digit| mock_call.send(:wait_for_digit) }.should == digits.map(&:chr)
  end
  
  test "the timeout given must be converted to milliseconds" do
    pbx_should_respond_with_success 0
    mock_call.send(:wait_for_digit, 1)
    output.messages.first.ends_with?('1000').should.equal true
  end
end

context 'say_digits command' do
  include DialplanCommandTestHelpers
  test 'Can execute the saydigits application using say_digits' do
    digits = "12345"
    pbx_should_respond_with_success
    mock_call.say_digits digits
    pbx_was_asked_to_execute "saydigits", digits
  end
  
  test 'Cannot pass non-integers into say_digits.  Will raise an ArgumentError' do
    the_following_code {
      mock_call.say_digits 'abc'
    }.should.raise(ArgumentError)
    
    the_following_code {
      mock_call.say_digits '1.20'
    }.should.raise(ArgumentError)
  end
  
end

context 'tone command' do
  include DialplanCommandTestHelpers
  
  test 'Supported tone codes are available in a look up table' do
    predefined_tones.keys.map(&:to_s).sort.should.equal(%w(busy dial info record).sort)
  end
  
  test 'Requesting to play a predefined tone plays the correct tone' do
    name, tone = predefined_tones.to_a.first
    pbx_should_respond_with_success
    mock_call.tone name
    pbx_was_asked_to_play_tone tone
  end
  
  test 'Requesting to play a custom tone by passing a raw tone code plays that raw custom tone directly' do
    custom_tone = "3333/33,0/15000"
    pbx_should_respond_with_success
    mock_call.tone custom_tone
    pbx_was_asked_to_play_tone custom_tone
  end
  
  test 'Requesting to play a custom tone by passing in its name plays it by name' do
    custome_tone_name = :constipated
    pbx_should_respond_with_success
    mock_call.tone custome_tone_name
    pbx_was_asked_to_play_tone custome_tone_name
  end
end

context 'get variable command' do
  include DialplanCommandTestHelpers
  
  test "Getting a variable that isn't set returns nothing" do
    pbx_should_respond_with "200 result=0"
    assert !mock_call.get_variable('OMGURFACE')
  end
  
  test "Getting a variable that is set returns its value" do
    unique_id = "1192470850.1"
    pbx_should_respond_with_value unique_id
    variable_value_returned = mock_call.get_variable('UNIQUEID')
    variable_value_returned.should.equal unique_id
  end
end

context "duration_of command" do
  include DialplanCommandTestHelpers
  
  test "Duration of must take a block" do
    the_following_code {
      mock_call.duration_of
    }.should.raise(LocalJumpError)
  end
  
  test "Passed block to duration of is actually executed" do
    the_following_code {
      mock_call.duration_of {
        throw :inside_duration_of
      }
    }.should.throw :inside_duration_of
  end
  
  test "Duration of block is returned" do
    start_time = Time.parse('9:25:00')
    end_time   = Time.parse('9:25:05')
    expected_duration = end_time - start_time
    
    flexmock(Time).should_receive(:now).twice.and_return(start_time, end_time)
    duration = mock_call.duration_of {
      # This doesn't matter
    }
    
    duration.should.equal expected_duration
  end
end

context "Dial command" do
  include DialplanCommandTestHelpers
  
  test "should set the caller id if the callerid option is specified" do
    mock_call.should_receive(:set_caller_id).once
    mock_call.dial 123, :caller_id => "1234678901"
  end
  
  test "should raise an exception when a non-numerical callerid is specified" do
    the_following_code {
      mock_call.dial 911, :caller_id => "zomgz"
    }.should.raise ArgumentError
  end
end

context "set_caller_id command" do
  include DialplanCommandTestHelpers

  test "should encapsulate the number with quotes" do
    caller_id = "14445556666"
    mock_call.should_receive(:raw_response).once.with(%(SET CALLERID "#{caller_id}")).and_return true
    mock_call.send(:set_caller_id, caller_id)
  end
end

context "record command" do
  include DialplanCommandTestHelpers
  
  test "executes the command SpeechEngine gives it based on the engine name" do
    mock_speak_command = "returned command doesn't matter"
    flexmock(Adhearsion::VoIP::Asterisk::Commands::SpeechEngines).should_receive(:cepstral).
      once.and_return(mock_speak_command)
    mock_call.should_receive(:execute).once.with(mock_speak_command)
    mock_call.speak "Spoken text doesn't matter", :cepstral
  end
  
  test "raises an InvalidSpeechEngine exception when the engine is 'none'" do
    the_following_code {
      mock_call.speak("o hai!", :none)
    }.should.raise Adhearsion::VoIP::Asterisk::Commands::SpeechEngines::InvalidSpeechEngine
  end
  
  test "should default its engine to :none" do
    the_following_code {
      flexmock(Adhearsion::VoIP::Asterisk::Commands::SpeechEngines).should_receive(:none).once.
        and_raise(Adhearsion::VoIP::Asterisk::Commands::SpeechEngines::InvalidSpeechEngine)
      mock_call.speak "ruby ruby ruby ruby!"
    }.should.raise Adhearsion::VoIP::Asterisk::Commands::SpeechEngines::InvalidSpeechEngine
  end
  
  test "Properly escapes spoken text" # TODO: What are the escaping needs?
  
end

context 'The join command' do
  
  include DialplanCommandTestHelpers
  
  test "should pass the 'd' flag when no options are given" do
    conference_id = "123"
    mock_call.should_receive(:execute).once.with("MeetMe", conference_id, "d", nil)
    mock_call.join conference_id
  end
  
  test "should pass through any given flags with 'd' appended to it if necessary" do
    conference_id, flags = "1000", "zomgs"
    mock_call.should_receive(:execute).once.with("MeetMe", conference_id, flags + "d", nil)
    mock_call.join conference_id, :options => flags
  end
  
  test "should raise an ArgumentError when the pin is not numerical" do
    the_following_code {
      mock_call.should_receive(:execute).never
      mock_call.join 3333, :pin => "letters are bad, mkay?!1"
    }.should.raise ArgumentError
  end
  
  test "should strip out illegal characters from a conference name" do
    bizarre_conference_name = "a-    bc!d&&e--`"
    normal_conference_name = "abcde"
    mock_call.should_receive(:execute).twice.with("MeetMe", normal_conference_name, "d", nil)
    
    mock_call.join bizarre_conference_name
    mock_call.join normal_conference_name
  end
  
  test "should allow textual conference names" do
    the_following_code {
      mock_call.should_receive(:execute).once.with_any_args
      mock_call.join "david bowie's pants"
    }.should.not.raise
  end
  
end

BEGIN {
  module DialplanCommandTestHelpers
    def self.included(test_case)
      test_case.send(:attr_reader, :mock_call, :input, :output)
      
      test_case.before do
        @input      = MockSocket.new
        @output     = MockSocket.new
        @mock_call  = Object.new
        mock_call.extend(Adhearsion::VoIP::Asterisk::Commands)
        flexmock(mock_call) do |call|
          call.should_receive(:from_pbx).and_return(input)
          call.should_receive(:to_pbx).and_return(output)
        end
      end
    end
    
    class MockSocket

      def print(message)
        messages << message
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

      def should_throw(sym=nil,&block)
        block.should.throw *[sym].compact
      end

      def mock_route_calculation_with(*definitions)
        flexmock(Adhearsion::VoIP::DSL::DialingDSL).should_receive(:calculate_routes_for).and_return(definitions)
      end

      def pbx_should_have_been_sent(message)
        output.gets.should.equal message
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
        pbx_should_respond_with "200 result=1 (#{value})"
      end
      
      def pbx_should_respond_with_success(success_code = nil)
        pbx_should_respond_with pbx_success_response(success_code)
      end

      def pbx_should_respond_with_failure(failure_code = nil)
        pbx_should_respond_with(pbx_failure_response(failure_code))
      end

      def pbx_should_respond_with_successful_background_response(digit=0)
        pbx_should_respond_with_success digit.kind_of?(String) ? digit[0] : digit
      end
      alias pbx_should_respond_with_a_wait_for_digit_timeout pbx_should_respond_with_successful_background_response
      
      def pbx_success_response(success_code = nil)
        "200 result=#{success_code || default_success_code}"
      end

      def default_success_code
        '1'
      end

      def pbx_failure_response(failure_code = nil)
        "200 result=#{failure_code || default_failure_code}"
      end

      def default_failure_code
        '0'
      end

      def output_stream_matches(pattern)
        assert_match(pattern, output.gets)
      end

      module OutputStreamMatchers
        def pbx_was_asked_to_play(*audio_files)
          audio_files.each do |audio_file|
            output_stream_matches(/playback #{audio_file}/)
          end
        end

        def pbx_was_asked_for_input(number_of_digits, options={})
          timeout = options[:timeout]
          timeout = (timeout && timeout != -1) ? (timeout * 1000).to_i : -1
          play    = options[:play] || 'beep'
          output_stream_matches(/GET DATA #{play} #{timeout} #{number_of_digits}/)
        end

        def pbx_was_asked_to_play_number(number)
          output_stream_matches(/saynumber #{number}/)
        end    

        def pbx_was_asked_to_play_time(number)
          output_stream_matches(/sayunixtime #{number}/)
        end

        def pbx_was_asked_to_play_tone(tone)
          output_stream_matches(/PlayTones #{Regexp.escape(tone.to_s)}/)
        end
        
        def pbx_was_asked_to_execute(application, *options)
          output_stream_matches(/exec saydigits #{options.join('|')}/i)
        end
      end
      include OutputStreamMatchers

      def assert_success(response)
        response.should.equal pbx_success_response
      end

      def predefined_tones
        Adhearsion::VoIP::Asterisk::Commands::TONES
      end
  end
}