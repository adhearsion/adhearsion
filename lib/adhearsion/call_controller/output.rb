# encoding: utf-8

module Adhearsion
  class CallController
    module Output
      extend ActiveSupport::Autoload

      autoload :AbstractPlayer
      autoload :AsyncPlayer
      autoload :Formatter
      autoload :Player

      PlaybackError = Class.new Adhearsion::Error # Represents failure to play audio, such as when the sound file cannot be found

      #
      # Speak output using text-to-speech (TTS)
      #
      # @param [String, #to_s] text The text to be rendered
      # @param [Hash] options A set of options for output
      #
      # @raises [PlaybackError] if the given argument could not be played
      #
      def say(text, options = {})
        player.play_ssml(text, options) || player.output(Formatter.ssml_for_text(text.to_s), options)
      end
      alias :speak :say

      #
      # Speak output using text-to-speech (TTS) and return as soon as it begins
      #
      # @param [String, #to_s] text The text to be rendered
      # @param [Hash] options A set of options for output
      #
      # @raises [PlaybackError] if the given argument could not be played
      #
      def say!(text, options = {})
        async_player.play_ssml(text, options) || async_player.output(Formatter.ssml_for_text(text.to_s), options)
      end
      alias :speak! :say!

      #
      # Plays the specified sound file names. This method will handle Time/DateTime objects (e.g. Time.now),
      # Fixnums (e.g. 1000), Strings which are valid Fixnums (e.g "123"), and direct sound files. To specify how the Date/Time objects are said
      # pass in as an array with the first parameter as the Date/Time/DateTime object along with a hash with the
      # additional options. See play_time for more information.
      #
      # @example Play file hello-world
      #   play 'http://www.example.com/hello-world.mp3'
      #   play '/path/on/disk/hello-world.wav'
      # @example Speak current time
      #   play Time.now
      # @example Speak today's date
      #   play Date.today
      # @example Speak today's date in a specific format
      #   play Date.today, :strftime => "%d/%m/%Y", :format => "dmy"
      # @example Play sound file, speak number, play two more sound files
      #   play %w"http://www.example.com/a-connect-charge-of.wav 22 /path/to/cents-per-minute.wav /path/to/will-apply.mp3"
      # @example Play two sound files
      #   play "/path/to/you-sound-cute.mp3", "/path/to/what-are-you-wearing.wav"
      #
      # @raises [PlaybackError] if (one of) the given argument(s) could not be played
      #
      def play(*arguments)
        player.play_ssml Formatter.ssml_for_collection(arguments)
        true
      end

      #
      # Plays the specified sound file names and returns as soon as it begins. This method will handle Time/DateTime objects (e.g. Time.now),
      # Fixnums (e.g. 1000), Strings which are valid Fixnums (e.g "123"), and direct sound files. To specify how the Date/Time objects are said
      # pass in as an array with the first parameter as the Date/Time/DateTime object along with a hash with the
      # additional options. See play_time for more information.
      #
      # @example Play file hello-world
      #   play 'http://www.example.com/hello-world.mp3'
      #   play '/path/on/disk/hello-world.wav'
      # @example Speak current time
      #   play Time.now
      # @example Speak today's date
      #   play Date.today
      # @example Speak today's date in a specific format
      #   play Date.today, :strftime => "%d/%m/%Y", :format => "dmy"
      # @example Play sound file, speak number, play two more sound files
      #   play %w"http://www.example.com/a-connect-charge-of.wav 22 /path/to/cents-per-minute.wav /path/to/will-apply.mp3"
      # @example Play two sound files
      #   play "/path/to/you-sound-cute.mp3", "/path/to/what-are-you-wearing.wav"
      #
      # @raises [PlaybackError] if (one of) the given argument(s) could not be played
      # @returns [Punchblock::Component::Output]
      #
      def play!(*arguments)
        async_player.play_ssml Formatter.ssml_for_collection(arguments)
      end

      #
      # Plays the given audio file.
      # SSML supports http:// paths and full disk paths.
      # The Punchblock backend will have to handle cases like Asterisk where there is a fixed sounds directory.
      #
      # @param [String] file http:// URL or full disk path to the sound file
      # @param [Hash] options Additional options to specify how exactly to say time specified.
      # @option options [String] :fallback The text to play if the file is not available
      #
      # @raises [PlaybackError] if (one of) the given argument(s) could not be played
      #
      def play_audio(file, options = nil)
        player.play_ssml Formatter.ssml_for_audio(file, options)
        true
      end

      #
      # Plays the given audio file and returns as soon as it begins.
      # SSML supports http:// paths and full disk paths.
      # The Punchblock backend will have to handle cases like Asterisk where there is a fixed sounds directory.
      #
      # @param [String] file http:// URL or full disk path to the sound file
      # @param [Hash] options Additional options to specify how exactly to say time specified.
      # @option options [String] :fallback The text to play if the file is not available
      #
      # @raises [PlaybackError] if (one of) the given argument(s) could not be played
      # @returns [Punchblock::Component::Output]
      #
      def play_audio!(file, options = nil)
        async_player.play_ssml Formatter.ssml_for_audio(file, options)
      end

      #
      # Plays the given Date, Time, or Integer (seconds since epoch)
      # using the given timezone and format.
      #
      # @param [Date, Time, DateTime] time Time to be said.
      # @param [Hash] options Additional options to specify how exactly to say time specified.
      # @option options [String] :format This format is used only to disambiguate times that could be interpreted in different ways.
      #   For example, 01/06/2011 could mean either the 1st of June or the 6th of January.
      #   Please refer to the SSML specification.
      # @see http://www.w3.org/TR/ssml-sayas/#S3.1
      # @option options [String] :strftime This format is what defines the string that is sent to the Speech Synthesis Engine.
      #   It uses Time::strftime symbols.
      #
      # @raises [ArgumentError] if the given argument can not be played
      #
      def play_time(time, options = {})
        raise ArgumentError unless [Date, Time, DateTime].include?(time.class) && options.is_a?(Hash)
        player.play_ssml Formatter.ssml_for_time(time, options)
        true
      end

      #
      # Plays the given Date, Time, or Integer (seconds since epoch)
      # using the given timezone and format and returns as soon as it begins.
      #
      # @param [Date, Time, DateTime] time Time to be said.
      # @param [Hash] options Additional options to specify how exactly to say time specified.
      # @option options [String] :format This format is used only to disambiguate times that could be interpreted in different ways.
      #   For example, 01/06/2011 could mean either the 1st of June or the 6th of January.
      #   Please refer to the SSML specification.
      # @see http://www.w3.org/TR/ssml-sayas/#S3.1
      # @option options [String] :strftime This format is what defines the string that is sent to the Speech Synthesis Engine.
      #   It uses Time::strftime symbols.
      #
      # @raises [ArgumentError] if the given argument can not be played
      # @returns [Punchblock::Component::Output]
      #
      def play_time!(time, options = {})
        raise ArgumentError unless [Date, Time, DateTime].include?(time.class) && options.is_a?(Hash)
        async_player.play_ssml Formatter.ssml_for_time(time, options)
      end

      #
      # Plays the given Numeric argument or string representing a decimal number.
      # When playing numbers, Adhearsion assumes you're saying the number, not the digits. For example, play("100")
      # is pronounced as "one hundred" instead of "one zero zero".
      #
      # @param [Numeric, String] Numeric or String containing a valid Numeric, like "321".
      #
      # @raises [ArgumentError] if the given argument can not be played
      #
      def play_numeric(number)
        raise ArgumentError unless number.kind_of?(Numeric) || number =~ /^\d+$/
        player.play_ssml Formatter.ssml_for_numeric(number)
        true
      end

      #
      # Plays the given Numeric argument or string representing a decimal number and returns as soon as it begins.
      # When playing numbers, Adhearsion assumes you're saying the number, not the digits. For example, play("100")
      # is pronounced as "one hundred" instead of "one zero zero".
      #
      # @param [Numeric, String] Numeric or String containing a valid Numeric, like "321".
      #
      # @raises [ArgumentError] if the given argument can not be played
      # @returns [Punchblock::Component::Output]
      #
      def play_numeric!(number)
        raise ArgumentError unless number.kind_of?(Numeric) || number =~ /^\d+$/
        async_player.play_ssml Formatter.ssml_for_numeric(number)
      end

      #
      # Plays the given output, allowing for DTMF input of a single digit from the user
      # At the end of the played file it returns nil
      #
      # @example Ask the user for a number, then play it back
      #   ssml = RubySpeech::SSML.draw do
      #     "Please press a button"
      #   end
      #   input = interruptible_play ssml
      #   play input unless input.nil?
      #
      # @param [String, Numeric, Date, Time, RubySpeech::SSML::Speak, Array, Hash] The argument to play to the user, or an array of arguments.
      # @param [Hash] Additional options.
      #
      # @return [String, nil] The single DTMF character entered by the user, or nil if nothing was entered
      # @raises [PlaybackError] if (one of) the given argument(s) could not be played
      #
      def interruptible_play(*outputs)
        outputs.find do |output|
          digit = stream_file output
          return digit if digit
        end
      end

      #
      # Plays a single output, not only files, accepting interruption by one of the digits specified
      #
      # @param [Object] String or Hash specifying output and options
      # @param [String] String with the digits that are allowed to interrupt output
      #
      # @return [String, nil] The pressed digit, or nil if nothing was pressed
      # @private
      #
      def stream_file(argument, digits = '0123456789#*')
        result = nil
        stopper = Punchblock::Component::Input.new :mode => :dtmf,
          :grammar => {
            :value => grammar_accept(digits)
          }

        player.output Formatter.ssml_for(argument) do |output_component|
          stopper.register_event_handler Punchblock::Event::Complete do |event|
            output_component.stop! unless output_component.complete?
          end
          write_and_await_response stopper
        end

        stopper.stop! if stopper.executing?
        reason = stopper.complete_event.reason
        result = reason.respond_to?(:utterance) ? reason.utterance : nil
        parse_dtmf result
      end

      # @private
      def player
        @player ||= Player.new(self)
      end

      # @private
      def async_player
        @async_player ||= AsyncPlayer.new(self)
      end
    end # Output
  end # CallController
end # Adhearsion
