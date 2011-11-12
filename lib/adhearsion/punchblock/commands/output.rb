module Adhearsion
  module Punchblock
    module Commands
      module Output
        def speak(text, options = {})
          play_ssml(text, options) || output(:text, text, options)
        end

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
        def play(*arguments)
          result = true
          arguments.each do |argument|
            case argument
              when Hash
                value = argument.delete(:value)
                result = play_ssml_for(value, argument)
              when RubySpeech::SSML::Speak
                result = play_ssml argument
              else
                result = play_ssml_for(argument)
            end
          end
          result
        end

        # Plays the specified input arguments, raising an exception if any can't be played.
        # @see play
        #
        def play!(*arguments)
          if !play(*arguments)
            raise Adhearsion::PlaybackError, "One of the passed outputs is invalid"
          end
        end

        # Plays the given Date, Time, or Integer (seconds since epoch)
        # using the given timezone and format.
        #
        # @param [Date|Time|DateTime] Time to be said.
        # @param [Hash] Additional options to specify how exactly to say time specified.
        #
        # +:format+   - This format is used only to disambiguate times that could be interpreted in different ways.
        #   For example, 01/06/2011 could mean either the 1st of June or the 6th of January.
        #   Please refer to the SSML specification.
        # @see http://www.w3.org/TR/ssml-sayas/#S3.1
        # +:strftime+ - This format is what defines the string that is sent to the Speech Synthesis Engine.
        #   It uses Time::strftime symbols.
        #
        # @return [Boolean] true if successful, false if the given argument could not be played.
        #
        def play_time(*args)
          argument, options = args.flatten
          return false unless [Date, Time, DateTime].include? argument.class

          options ||= {}
          return false unless options.is_a? Hash
          play_ssml(ssml_for_time(argument, options))
        end

        # Plays the given Numeric argument or string representing a decimal number.
        # When playing numbers, Adhearsion assumes you're saying the number, not the digits. For example, play("100")
        # is pronounced as "one hundred" instead of "one zero zero".
        #
        # @param [Numeric|String] Numeric or String containing a valid Numeric, like "321".
        #
        # @return [Boolean] true if successful, false if the given argument could not be played.
        #
        def play_numeric(*args)
          argument, options = args.flatten
          if argument.kind_of?(Numeric) || argument =~ /^\d+$/
            play_ssml(ssml_for_numeric(argument, options))
          end
        end

        # Plays the given audio file.
        # SSML supports http:// paths and full disk paths.
        # The Punchblock backend will have to handle cases like Asterisk where there is a fixed sounds directory.
        #
        # @param [String] http:// URL or full disk path to the sound file
        # @param [Hash] Additional options to specify how exactly to say time specified.
        # +:fallback+ - The text to play if the file is not available
        #
        # @return [Boolean] true on correct play of the file, false on file missing or not playable
        #
        def play_audio(*args)
          argument, options = args.flatten
          play_ssml(ssml_for_audio(argument, options))
        end

        def play_ssml(ssml, options = {})
          if [RubySpeech::SSML::Speak, Nokogiri::XML::Document].include? ssml.class
            output :ssml, ssml.to_s, options
          end
        end

        def output(type, content, options = {})
          begin
            options.merge! type => content
            execute_component_and_await_completion ::Punchblock::Component::Output.new(options)
          rescue StandardError => e
            false
          end
        end#output

        def output!(type, content, options = {})
          options.merge! type => content
          execute_component_and_await_completion ::Punchblock::Component::Output.new(options)
        end#output

        # Same as interruptible_play, but throws an error if unable to play the output
        # @see interruptible_play
        #
        def interruptible_play!(*outputs)
          result = nil
          outputs.each do |output|
            result = stream_file(output,  "1234567890*#")
            break if !result.nil?
          end
          result
        end

        
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
        # @param [RubySpeech::SSML::Speak] The SSML to play to the user
        # @param [Hash] Additional options.
        # +:digits+ - How many digits to expect from the user
        # +:initial_timeout+ - Time in ms to wait for the first digit before time-out
        # +:inter_digit_timeout+ - Milliseconds to wait between every digit before timeout
        #
        # @return [String|Nil] The single DTMF character entered by the user, or nil if nothing was entered
        #
        def interruptible_play(*outputs)
          result = nil
          outputs.each do |output|
            begin
              result = interruptible_play!(output)
            rescue PlaybackError => e
              # Ignore this exception and play the next output
              logger.warn e.message
            ensure
              break if result
            end
          end
          result
        end

        def detect_type(output)
          result = nil
          if [Date, Time, DateTime].include? output.class
            result = :time
          end
          if output.kind_of?(Numeric) || output =~ /^\d+$/
            result = :numeric
          end
          if !result && URI::regexp(%w(http https)).match(output.to_s)
            result = :audio
          end
          if !result && /\//.match(output.to_s)
            result = :audio
          end
          result ||= :text
        end#detect_type
        
        def play_ssml_for(*args)
          play_ssml ssml_for(args)
        end

        # Generates SSML for the argument and options passed, using automatic detection
        # Directly returns the argument if it is already an SSML document
        #
        # @param [String|Hash|RubySpeech::SSML::Speak] the argument with options as accepted by the play_ methods, or an SSML document
        # @return [RubySpeech::SSML::Speak] an SSML document
        def ssml_for(*args)
          if args.size == 1 && args[0].class == RubySpeech::SSML::Speak
            return args[0]
          end
          argument, options = args.flatten
          options ||= {}
          type = detect_type(argument)
          send("ssml_for_#{type}", argument, options)
        end#ssml_for

        def ssml_for_text(argument, options = {})
          RubySpeech::SSML.draw do
            argument
          end
        end#ssml_for_text

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
        end#ssml_for_time

        def ssml_for_numeric(argument, options = {})
          RubySpeech::SSML.draw do
            say_as(:interpret_as => 'cardinal') { argument.to_s }
          end
        end

        def ssml_for_audio(argument, options = {})
          options ||= {}
          fallback = options.delete :fallback
          RubySpeech::SSML.draw {
            audio :src => argument do
              fallback
            end
          }
        end

        # Plays a single output, not only files, accepting interruption by one of the digits specified
        # Currently still stops execution, will be fixed soon in Punchblock
        #
        # @param [Object] String or Hash specifying output and options
        # @param [String] String with the digits that are allowed to interrupt output
        # @return [String|nil] The pressed digit, or nil if nothing was pressed
        def stream_file(argument, digits = '0123456789#*')
          result = nil
          ssml = ssml_for argument
          output_component = ::Punchblock::Component::Output.new :ssml => ssml.to_s
          input_stopper_component = ::Punchblock::Component::Input.new :mode => :dtmf,
            :grammar => {
              :value => grammar_accept(digits).to_s
          }
          input_stopper_component.register_event_handler ::Punchblock::Event::Complete do |event|
            Thread.new {
              output_component.stop! unless output_component.complete?
              reason = event.reason
              result = reason.interpretation if reason.respond_to? :interpretation
            }
          end
          write_and_await_response input_stopper_component
          execute_component_and_await_completion output_component
          input_stopper_component.stop! if input_stopper_component.executing?
          return parse_single_dtmf result if !result.nil?
          result
        end

      end#module
    end#module
  end#module
end#module
