module Adhearsion
  module Rayo
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
          unless play_time(arguments)
            arguments.flatten.each do |argument|
              # result starts off as true.  But if the following command ever returns false, then result
              # remains false.
              result &= play_numeric(argument) || play_audio(argument)
            end
          end
          result
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

          interpretation = case argument
            when Date then 'date'
            when Time then 'time'
          end

          format    = options.delete :format
          strftime  = options.delete :strftime

          time_to_say = strftime ? argument.strftime(strftime) : argument.to_s

          play_ssml(RubySpeech::SSML.draw do
            say_as(:interpret_as => interpretation, :format => format) { time_to_say }
          end)
        end

        # Plays the given Numeric argument or string representing a decimal number.
        # When playing numbers, Adhearsion assumes you're saying the number, not the digits. For example, play("100")
        # is pronounced as "one hundred" instead of "one zero zero".
        #
        # @param [Numeric|String] Numeric or String containing a valid Numeric, like "321".
        #
        # @return [Boolean] true if successful, false if the given argument could not be played.
        #
        def play_numeric(argument)
          if argument.kind_of?(Numeric) || argument =~ /^\d+$/
            play_ssml(RubySpeech::SSML.draw do
              say_as(:interpret_as => 'cardinal') { argument.to_s }
            end)
          end
        end

        # Plays the given audio file.
        # SSML supports http:// paths and full disk paths.
        # The Punchblock backend will have to handle cases like Asterisk where there is a fixed sounds directory.
        #
        # @param [String] http:// URL or full disk path to the sound file
        #
        # @return [Boolean] true on correct play of the file, false on file missing or not playable
        #
        def play_audio(filename)
          play_ssml RubySpeech::SSML.draw { audio :src => filename }
        end

        def play_ssml(ssml, options = {})
          if [RubySpeech::SSML::Speak, Nokogiri::XML::Document].include? ssml.class
            output :ssml, ssml.to_s, options
          end
        end

        def output(type, content, options = {})
          begin
            options.merge! type => content
            execute_component_and_await_completion Punchblock::Component::Output.new(options)
          rescue StandardError => e
            false
          end
        end#output

        # Plays the given SSML, allowing for DTMF input of a single digit from the user
        # At the end of the played file it returns nil
        #
        # @example Ask the user for a number, then play it back
        #   ssml = RubySpeech::SSML.draw do
        #     "Please press a button"
        #   end
        #   input = interruptible_play(ssml)
        #   if !input.nil?
        #     play input
        #   end
        #
        # @params [RubySpeech::SSML::Speak] The SSML to play to the user
        #
        # @return [String|Nil] The single DTMF character entered by the user, or nil if nothing was entered
        #
        def interruptible_play(ssml)
          result = nil
          options = {:ssml => ssml.to_s}
          output_component = Punchblock::Component::Output.new(options)
          input_options = {
            :mode => :dtmf,
            :grammar => {:value => '[1 DIGIT]', :content_type => 'application/grammar+voxeo'},
            :event_callback => lambda { |event|
              Thread.new {
                if !output_component.complete_event.set_yet?
                  output_component.stop!
                end
                if event.reason.is_a? Punchblock::Component::Input::Complete::Success
                  result = event.reason.interpretation
                end
              }
            }
          }
          input_component = Punchblock::Component::Input.new(input_options)
          write_and_await_response input_component
          execute_component_and_await_completion output_component
          if !input_component.complete_event.set_yet?
            input_component.stop!
          end
          return result
        end#interruptible_play

      end#module
    end#module
  end#module
end#module
