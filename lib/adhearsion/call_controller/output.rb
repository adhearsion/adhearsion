# encoding: utf-8

module Adhearsion
  class CallController
    module Output
      extend ActiveSupport::Autoload

      autoload :Play

      PlaybackError = Class.new Adhearsion::Error # Represents failure to play audio, such as when the sound file cannot be found

      #
      # Speak output using text-to-speech (TTS)
      #
      # @param [String, #to_s] text The text to be rendered
      # @param [Hash] options A set of options for output
      #
      def say(*args)
        new_play.say *args
      end
      alias :speak :say

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
      # @return [Boolean] true is returned if everything was successful. Otherwise, false indicates that
      #   some sound file(s) could not be played.
      #
      # @see play_time
      # @see play_numeric
      # @see play_audio
      #
      def play(*args)
        new_play.play *args
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
      # @return [Boolean] true on correct play of the file, false on file missing or not playable
      #
      def play_audio(*args)
        new_play.play_audio *args
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
      # @return [Boolean] true if successful, false if the given argument could not be played.
      #
      def play_time(*args)
        new_play.play_time *args
      end

      #
      # Plays the given Numeric argument or string representing a decimal number.
      # When playing numbers, Adhearsion assumes you're saying the number, not the digits. For example, play("100")
      # is pronounced as "one hundred" instead of "one zero zero".
      #
      # @param [Numeric, String] Numeric or String containing a valid Numeric, like "321".
      #
      # @return [Boolean] true if successful, false if the given argument could not be played.
      #
      def play_numeric(*args)
        new_play.play_numeric *args
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
      #
      def interruptible_play(*args)
        new_play.interruptible_play *args
      end

      # @private
      def new_play
        Play.new self
      end
    end # Output
  end # CallController
end # Adhearsion
