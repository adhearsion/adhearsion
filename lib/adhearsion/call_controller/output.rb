# encoding: utf-8
require 'uri'
require 'i18n'

%w(
  abstract_player
  async_player
  formatter
  player
).each { |r| require "adhearsion/call_controller/output/#{r}" }

module Adhearsion
  class CallController
    module Output
      PlaybackError = Class.new Adhearsion::Error # Represents failure to play audio, such as when the sound file cannot be found
      NoDocError = Class.new Adhearsion::Error # Represents failure to provide documents to playback

      #
      # Speak output using text-to-speech (TTS)
      #
      # @param [String, #to_s] text The text to be rendered
      # @param [Hash] options A set of options for output. Includes everything in Punchblock::Component::Output.new.
      #
      # @raise [PlaybackError] if the given argument could not be played
      #
      def say(text, options = {})
        return unless text
        player.play_ssml(text, options) || player.output(output_formatter.ssml_for_text(text.to_s), options)
      end
      alias :speak :say

      #
      # Speak output using text-to-speech (TTS) and return as soon as it begins
      #
      # @param [String, #to_s] text The text to be rendered
      # @param [Hash] options A set of options for output. Includes everything in Punchblock::Component::Output.new.
      #
      # @raise [PlaybackError] if the given argument could not be played
      #
      def say!(text, options = {})
        return unless text
        async_player.play_ssml(text, options) || async_player.output(output_formatter.ssml_for_text(text.to_s), options)
      end
      alias :speak! :say!


      # Speak characters using text-to-speech (TTS)
      #
      # @example Speak 'abc123' as 'ay bee cee one two three'
      #   say_characters('abc123')
      #
      # @param [String, #to_s] characters The string of characters to be spoken
      # @param [Hash] options A set of options for output. Includes everything in Punchblock::Component::Output.new.
      #
      # @raise [PlaybackError] if the given argument could not be played
      #
      def say_characters(characters, options = {})
        player.play_ssml output_formatter.ssml_for_characters(characters), options
        true
      end

      # Speak characters using text-to-speech (TTS) and return as soon as it begins
      #
      # @example Speak 'abc123' as 'ay bee cee one two three'
      #   say_characters!('abc123')
      #
      # @param [String, #to_s] characters The string of characters to be spoken
      # @param [Hash] options A set of options for output. Includes everything in Punchblock::Component::Output.new.
      #
      # @raise [PlaybackError] if the given argument could not be played
      #
      def say_characters!(characters, options = {})
        async_player.play_ssml output_formatter.ssml_for_characters(characters), options
      end

      #
      # Plays the specified sound file names. This method will handle Time/DateTime objects (e.g. Time.now),
      # Fixnums (e.g. 1000), Strings which are valid Fixnums (e.g "123"), and direct sound files. To specify how the Date/Time objects are said
      # pass in as an array with the first parameter as the Date/Time/DateTime object along with a hash with the
      # additional options. See play_time for more information.
      #
      # @param [Array<String, Fixnum, Time, Date>, String, Fixnum, Time, Date] outputs A collection of outputs to render.
      # @param [Hash] options A set of options for output. Includes everything in Punchblock::Component::Output.new.
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
      # @raise [PlaybackError] if (one of) the given argument(s) could not be played
      #
      def play(*outputs, options)
        options = process_output_options outputs, options
        ssml = output_formatter.ssml_for_collection(outputs) || return
        player.play_ssml ssml, options
        true
      rescue NoDocError
        false
      end

      #
      # Plays the specified sound file names and returns as soon as it begins. This method will handle Time/DateTime objects (e.g. Time.now),
      # Fixnums (e.g. 1000), Strings which are valid Fixnums (e.g "123"), and direct sound files. To specify how the Date/Time objects are said
      # pass in as an array with the first parameter as the Date/Time/DateTime object along with a hash with the
      # additional options. See play_time for more information.
      #
      # @param [Array<String, Fixnum, Time, Date>, String, Fixnum, Time, Date] outputs A collection of outputs to render.
      # @param [Hash] options A set of options for output. Includes everything in Punchblock::Component::Output.new.
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
      # @raise [PlaybackError] if (one of) the given argument(s) could not be played
      # @return [Punchblock::Component::Output]
      #
      def play!(*outputs, options)
        options = process_output_options outputs, options
        ssml = output_formatter.ssml_for_collection(outputs) || return
        async_player.play_ssml ssml, options
      rescue NoDocError
        false
      end

      #
      # Plays the given audio file.
      # SSML supports http:// paths and full disk paths.
      # The Punchblock backend will have to handle cases like Asterisk where there is a fixed sounds directory.
      #
      # @param [String] file http:// URL or full disk path to the sound file
      # @param [Hash] options Additional options Includes everything in Punchblock::Component::Output.new.
      # @option options [String] :fallback The text to play if the file is not available
      #
      # @raise [PlaybackError] if (one of) the given argument(s) could not be played
      #
      def play_audio(file, options = {})
        player.play_ssml(output_formatter.ssml_for_audio(file, options), options)
        true
      end

      #
      # Plays the given audio file and returns as soon as it begins.
      # SSML supports http:// paths and full disk paths.
      # The Punchblock backend will have to handle cases like Asterisk where there is a fixed sounds directory.
      #
      # @param [String] file http:// URL or full disk path to the sound file
      # @param [Hash] options Additional options to specify how exactly to say time specified. Includes everything in Punchblock::Component::Output.new.
      # @option options [String] :fallback The text to play if the file is not available
      #
      # @raise [PlaybackError] if (one of) the given argument(s) could not be played
      # @return [Punchblock::Component::Output]
      #
      def play_audio!(file, options = {})
        async_player.play_ssml(output_formatter.ssml_for_audio(file, options), options)
      end

      #
      # Plays the given Date, Time, or Integer (seconds since epoch)
      # using the given timezone and format.
      #
      # @param [Date, Time, DateTime] time Time to be said.
      # @param [Hash] options Additional options to specify how exactly to say time specified. Includes everything in Punchblock::Component::Output.new.
      # @option options [String] :format This format is used only to disambiguate times that could be interpreted in different ways.
      #   For example, 01/06/2011 could mean either the 1st of June or the 6th of January.
      #   Please refer to the SSML specification.
      # @see http://www.w3.org/TR/ssml-sayas/#S3.1
      # @option options [String] :strftime This format is what defines the string that is sent to the Speech Synthesis Engine.
      #   It uses Time::strftime symbols.
      #
      # @raise [ArgumentError] if the given argument can not be played
      #
      def play_time(time, options = {})
        raise ArgumentError unless [Date, Time, DateTime].include?(time.class) && options.is_a?(Hash)
        player.play_ssml output_formatter.ssml_for_time(time, options), options
        true
      end

      #
      # Plays the given Date, Time, or Integer (seconds since epoch)
      # using the given timezone and format and returns as soon as it begins.
      #
      # @param [Date, Time, DateTime] time Time to be said.
      # @param [Hash] options Additional options to specify how exactly to say time specified. Includes everything in Punchblock::Component::Output.new.
      # @option options [String] :format This format is used only to disambiguate times that could be interpreted in different ways.
      #   For example, 01/06/2011 could mean either the 1st of June or the 6th of January.
      #   Please refer to the SSML specification.
      # @see http://www.w3.org/TR/ssml-sayas/#S3.1
      # @option options [String] :strftime This format is what defines the string that is sent to the Speech Synthesis Engine.
      #   It uses Time::strftime symbols.
      #
      # @raise [ArgumentError] if the given argument can not be played
      # @return [Punchblock::Component::Output]
      #
      def play_time!(time, options = {})
        raise ArgumentError unless [Date, Time, DateTime].include?(time.class) && options.is_a?(Hash)
        async_player.play_ssml output_formatter.ssml_for_time(time, options), options
      end

      #
      # Plays the given Numeric argument or string representing a decimal number.
      # When playing numbers, Adhearsion assumes you're saying the number, not the digits. For example, play("100")
      # is pronounced as "one hundred" instead of "one zero zero".
      #
      # @param [Numeric, String] number Numeric or String containing a valid Numeric, like "321".
      # @param [Hash] options A set of options for output. See Punchblock::Component::Output.new for details.
      #
      # @raise [ArgumentError] if the given argument can not be played
      #
      def play_numeric(number, options = {})
        raise ArgumentError unless number.kind_of?(Numeric) || number =~ /^\d+$/
        player.play_ssml output_formatter.ssml_for_numeric(number), options
        true
      end

      #
      # Plays the given Numeric argument or string representing a decimal number and returns as soon as it begins.
      # When playing numbers, Adhearsion assumes you're saying the number, not the digits. For example, play("100")
      # is pronounced as "one hundred" instead of "one zero zero".
      #
      # @param [Numeric, String] number Numeric or String containing a valid Numeric, like "321".
      # @param [Hash] options A set of options for output. See Punchblock::Component::Output.new for details.
      #
      # @raise [ArgumentError] if the given argument can not be played
      # @return [Punchblock::Component::Output]
      #
      def play_numeric!(number, options = {})
        raise ArgumentError unless number.kind_of?(Numeric) || number =~ /^\d+$/
        async_player.play_ssml output_formatter.ssml_for_numeric(number), options
      end

      #
      # Plays the given SSML document from a URL.
      #
      # @param [String] url String containing a valid URL, like "http://example.com/document.ssml".
      # @param [Hash] options A set of options for output. See Punchblock::Component::Output.new for details.
      #
      # @raise [ArgumentError] if the given argument can not be played
      #
      def play_document(url, options = {})
        raise ArgumentError unless url =~ URI::regexp
        player.play_url url, options
        true
      end

      #
      # Plays the given SSML document from a URL and returns as soon as it begins.
      #
      # @param [String] url String containing a valid URL, like "http://example.com/document.ssml".
      # @param [Hash] options A set of options for output. See Punchblock::Component::Output.new for details.
      #
      # @raise [ArgumentError] if the given argument can not be played
      # @return [Punchblock::Component::Output]
      #
      def play_document!(url, options = {})
        raise ArgumentError unless url =~ URI::regexp
        async_player.play_url url, options
      end

      def t(key, options = {})
        this_locale = options[:locale] || locale
        options = {default: '', locale: locale}.merge(options)
        prompt = ::I18n.t "#{key}.audio", options
        text   = ::I18n.t "#{key}.text", options

        if prompt.empty? && text.empty?
          # Look for a translation key that doesn't follow the Adhearsion-I18n structure
          text = ::I18n.t key, options
        end

        unless prompt.empty?
          prompt = "file://#{Adhearsion.root + "/" unless Adhearsion.config.platform.i18n.audio_path.start_with?("/")}#{Adhearsion.config.platform.i18n.audio_path}/#{this_locale}/#{prompt}"
        end

        RubySpeech::SSML.draw language: this_locale do
          if prompt.empty?
            string text
          else
            if Adhearsion.config.platform.i18n.fallback
              audio(src: prompt) { string text }
            else
              audio(src: prompt)
            end
          end
        end
      end

      def locale
        call[:locale] || I18n.default_locale
      end

      def locale=(l)
        call[:locale] = l
      end

      # @private
      def player
        Player.new(self)
      end

      # @private
      def async_player
        AsyncPlayer.new(self)
      end

      # @private
      def process_output_options(outputs, options)
        if options.is_a?(Hash) && outputs.count > 0
          options
        else
          outputs << options
          {}
        end
      end

      #
      # @return [Formatter] an output formatter for the preparation of SSML documents for submission to the engine
      #
      def output_formatter
        Formatter.new
      end
    end # Output
  end # CallController
end # Adhearsion
