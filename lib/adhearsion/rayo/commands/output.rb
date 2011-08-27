module Adhearsion
  module Rayo
    module Commands
      module Output
        # Plays the specified sound file names. This method will handle Time/DateTime objects (e.g. Time.now),
        # Fixnums (e.g. 1000), Strings which are valid Fixnums (e.g "123"), and direct sound files. When playing
        # numbers, Adhearsion assumes you're saying the number, not the digits. For example, play("100")
        # is pronounced as "one hundred" instead of "one zero zero". To specify how the Date/Time objects are said
        # pass in as an array with the first parameter as the Date/Time/DateTime object along with a hash with the
        # additional options. See play_time for more information.
        #
        # @example Play file hello-world.???
        #   play 'hello-world'
        # @example Speak current time
        #   play Time.now
        # @example Speak today's date
        #   play Date.today
        # @example Speak today's date in a specific format
        #   play [Date.today, {:format => 'BdY'}]
        # @example Play sound file, speak number, play two more sound files
        #   play %w"a-connect-charge-of 22 cents-per-minute will-apply"
        # @example Play two sound files
        #   play "you-sound-cute", "what-are-you-wearing"
        #
        # @return [Boolean] true is returned if everything was successful. Otherwise, false indicates that
        #   some sound file(s) could not be played.
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
        # +:timezone+ - Sends a timezone to asterisk. See /usr/share/zoneinfo for a list. Defaults to the machine timezone.
        # +:format+   - This is the format the time is to be said in.  Defaults to "ABdY 'digits/at' IMp"
        #
        def play_time(*args)
          argument, options = args.flatten
          return false unless [Date, Time, DateTime].include? argument.class

          interpretation = case argument
          when Date then 'date'
          when Time then 'time'
          end

          play_ssml(RubySpeech::SSML.draw do
            say_as(:interpret_as => interpretation) { argument.to_s }
          end)

          # options ||= {}
          #
          # return false unless options.is_a? Hash
          #
          # timezone = options.delete(:timezone) || ''
          # format   = options.delete(:format)   || ''
          # epoch    = case argument
          #            when Time || DateTime
          #              argument.to_i
          #            when Date
          #              format = 'BdY' unless format.present?
          #              argument.to_time.to_i
          #            end
          #
          # return false if epoch.nil?
          #
          # execute :sayunixtime, epoch, timezone, format
        end

        def play_numeric(argument)
          if argument.kind_of?(Numeric) || argument =~ /^\d+$/
            play_ssml(RubySpeech::SSML.draw do
              say_as(:interpret_as => 'cardinal') { argument.to_s }
            end)
          end
        end

        def play_audio(filename)
          play_ssml RubySpeech::SSML.draw { audio :src => filename }
        end

        def play_ssml(ssml)
          return unless [RubySpeech::SSML::Speak, Nokogiri::XML::Document].include? ssml.class
          begin
            execute_component_and_await_completion Punchblock::Component::Output.new(:ssml => ssml)
          rescue StandardError => e
            false
          end
        end
      end
    end
  end
end
