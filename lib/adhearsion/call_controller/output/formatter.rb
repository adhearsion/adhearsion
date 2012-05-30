# encoding: utf-8

module Adhearsion
  class CallController
    module Output
      module Formatter

        class << self
          def detect_type(output)
            result = nil
            result = :time if [Date, Time, DateTime].include? output.class
            result = :numeric if output.kind_of?(Numeric) || output =~ /^\d+$/
            result = :audio if !result && (/^\//.match(output.to_s) || URI::regexp.match(output.to_s))
            result ||= :text
          end

          #
          # Generates SSML for the argument and options passed, using automatic detection
          # Directly returns the argument if it is already an SSML document
          #
          # @param [String, Hash, RubySpeech::SSML::Speak] the argument with options as accepted by the play_ methods, or an SSML document
          # @return [RubySpeech::SSML::Speak] an SSML document
          #
          def ssml_for(*args)
            return args[0] if args.size == 1 && args[0].is_a?(RubySpeech::SSML::Speak)
            argument, options = args.flatten
            options ||= {}
            type = detect_type argument
            send "ssml_for_#{type}", argument, options
          end

          def ssml_for_text(argument, options = {})
            RubySpeech::SSML.draw { argument }
          end

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

          def ssml_for_numeric(argument, options = {})
            RubySpeech::SSML.draw do
              say_as(:interpret_as => 'cardinal') { argument.to_s }
            end
          end

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
end
