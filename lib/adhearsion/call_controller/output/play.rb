# encoding: utf-8

module Adhearsion
  class CallController
    module Output
      class Play

        attr_accessor :controller

        def initialize(controller)
          @controller = controller
        end

        #
        # Speak output using text-to-speech (TTS)
        #
        # @param [String, #to_s] text The text to be rendered
        # @param [Hash] options A set of options for output
        #
        def say(text, options = {})
          play_ssml(text, options) || output(ssml_for_text(text.to_s), options)
        end

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
        def play(*arguments)
          arguments.inject(true) do |value, argument|
            value = case argument
            when Hash
              play_ssml_for argument.delete(:value), argument
            when RubySpeech::SSML::Speak
              play_ssml argument
            else
              play_ssml_for argument
            end
          end
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
        def play_audio(file, options = nil)
          play_ssml ssml_for_audio(file, options)
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
        def play_time(time, options = {})
          return false unless [Date, Time, DateTime].include? time.class

          return false unless options.is_a? Hash
          play_ssml ssml_for_time(time, options)
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
        def play_numeric(number, options = nil)
          if number.kind_of?(Numeric) || number =~ /^\d+$/
            play_ssml ssml_for_numeric(number, options)
          end
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
        def interruptible_play(*outputs)
          result = nil
          outputs.each do |output|
            begin
              result = interruptible_play! output
            rescue PlaybackError => e
              # Ignore this exception and play the next output
              logger.error "Error playing back the prompt: #{e.message}"
            ensure
              break if result
            end
          end
          result
        end

        #
        # Plays the specified input arguments, raising an exception if any can't be played.
        # @see play
        #
        # @private
        #
        def play!(*arguments)
          play(*arguments) or raise PlaybackError, "One of the passed outputs is invalid"
        end

        #
        # Plays a single output, not only files, accepting interruption by one of the digits specified
        # Currently still stops execution, will be fixed soon in Punchblock
        #
        # @param [Object] String or Hash specifying output and options
        # @param [String] String with the digits that are allowed to interrupt output
        #
        # @return [String, nil] The pressed digit, or nil if nothing was pressed
        #
        # @private
        #
        def stream_file(argument, digits = '0123456789#*')
          result = nil
          ssml = ssml_for argument
          output_component = ::Punchblock::Component::Output.new :ssml => ssml.to_s
          input_stopper_component = ::Punchblock::Component::Input.new :mode => :dtmf,
            :grammar => {
              :value => controller.grammar_accept(digits)
            }
          input_stopper_component.register_event_handler ::Punchblock::Event::Complete do |event|
            output_component.stop! unless output_component.complete?
          end
          controller.write_and_await_response input_stopper_component
          begin
            controller.execute_component_and_await_completion output_component
          rescue ::Punchblock::ProtocolError => e
            raise PlaybackError, "Output failed for argument #{argument.inspect} due to #{e.inspect}"
          end
          input_stopper_component.stop! if input_stopper_component.executing?
          reason = input_stopper_component.complete_event.reason
          result = reason.interpretation if reason.respond_to? :interpretation
          return controller.parse_single_dtmf result unless result.nil?
          result
        end

        # @private
        def play_ssml(ssml, options = {})
          if [RubySpeech::SSML::Speak, Nokogiri::XML::Document].include? ssml.class
            output ssml.to_s, options
          end
        end

        # @private
        def output(content, options = {})
          options.merge! :ssml => content
          controller.execute_component_and_await_completion ::Punchblock::Component::Output.new(options)
        end

        #
        # Same as interruptible_play, but throws an error if unable to play the output
        # @see interruptible_play
        #
        # @private
        #
        def interruptible_play!(*outputs)
          result = nil
          outputs.each do |output|
            result = stream_file output
            break unless result.nil?
          end
          result
        end

        # @private
        def detect_type(output)
          result = nil
          result = :time if [Date, Time, DateTime].include? output.class
          result = :numeric if output.kind_of?(Numeric) || output =~ /^\d+$/
          result = :audio if !result && (/^\//.match(output.to_s) || URI::regexp.match(output.to_s))
          result ||= :text
        end

        # @private
        def play_ssml_for(*args)
          play_ssml ssml_for(args)
        end

        #
        # Generates SSML for the argument and options passed, using automatic detection
        # Directly returns the argument if it is already an SSML document
        #
        # @param [String, Hash, RubySpeech::SSML::Speak] the argument with options as accepted by the play_ methods, or an SSML document
        # @return [RubySpeech::SSML::Speak] an SSML document
        #
        # @private
        #
        def ssml_for(*args)
          return args[0] if args.size == 1 && args[0].is_a?(RubySpeech::SSML::Speak)
          argument, options = args.flatten
          options ||= {}
          type = detect_type argument
          send "ssml_for_#{type}", argument, options
        end

        # @private
        def ssml_for_text(argument, options = {})
          RubySpeech::SSML.draw { argument }
        end

        # @private
        def ssml_for_time(argument, options = {})
          interpretation = case argument
          when Date then 'date'
          when Time then 'time'
          end

          format = options.delete :format
          strftime = options.delete :strftime

          time_to_say = strftime ? argument.strftime(strftime) : argument.to_s

          RubySpeech::SSML.draw do
            say_as(:interpret_as => interpretation, :format => format) { time_to_say }
          end
        end

        # @private
        def ssml_for_numeric(argument, options = {})
          RubySpeech::SSML.draw do
            say_as(:interpret_as => 'cardinal') { argument.to_s }
          end
        end

        # @private
        def ssml_for_audio(argument, options = {})
          fallback = (options || {}).delete :fallback
          RubySpeech::SSML.draw do
            audio(:src => argument) { fallback }
          end
        end
      end
    end
  end
end