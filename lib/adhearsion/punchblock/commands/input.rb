module Adhearsion
  module Punchblock
    module Commands
      module Input
        # Utility method for DTMF GRXML grammars
        #
        # @param [Integer] Number of digits to accept in the grammar.
        # @return [RubySpeech::GRXML::Grammar] A grammar suitable for use in SSML prompts.
        def grammar_digits(digits = 1)
          grammar = RubySpeech::GRXML.draw do
            self.mode = 'dtmf'
            self.root = 'inputdigits'
            rule id: 'digits' do
              one_of do
                0.upto(9) {|d| item { d.to_s } }
              end
            end

            rule id: 'inputdigits', scope: 'public' do
              item repeat: digits.to_s do
                ruleref uri: '#digits'
              end
            end
          end
        end#grammar_digits

        def input!(*args, &block)
          options = args.last.kind_of?(Hash) ? args.pop : {}
          number_of_digits = args.shift

          options[:play]  = [*options[:play]].compact

          if options.has_key?(:interruptible) && options[:interruptible] == false
            play_command = :play!
          else
            options[:interruptible] = true
            play_command = :interruptible_play!
          end

          if options.has_key? :speak
            raise ArgumentError unless options[:speak].is_a? Hash
            raise ArgumentError, 'Must include a text string when requesting TTS fallback' unless options[:speak].has_key?(:text)
            options[:speak][:interruptible] = options[:interruptible]
          end

          timeout         = options[:timeout]
          terminating_key = options[:accept_key]
          terminating_key = if terminating_key
            terminating_key.to_s
          elsif number_of_digits.nil? && !terminating_key.equal?(false)
            '#'
          end

          if number_of_digits && number_of_digits < 0
            ahn_log.warn "Giving -1 to #input is now deprecated. Do not specify a first " +
                             "argument to allow unlimited digits." if number_of_digits == -1
            raise ArgumentError, "The number of digits must be positive!"
          end

          buffer = ''
          if options[:play].any?
            begin
              # Consume the sound files one at a time. In the event of playback
              # failure, this tells us which files remain unplayed.
              while file = options[:play].shift
                key = send play_command, file
                key = nil if play_command == :play!
                break if key
              end
            rescue PlaybackError
              raise unless options[:speak]
              key = speak options[:speak].delete(:text), options[:speak]
            end
            key ||= ''
          elsif options[:speak]
            key = speak(options[:speak].delete(:text), options[:speak]) || ''
          else
            key = wait_for_digit timeout || -1
          end
          loop do
            return buffer if key.nil?
            if terminating_key
              if key == terminating_key
                return buffer
              else
                buffer << key
                return buffer if number_of_digits && number_of_digits == buffer.length
              end
            else
              buffer << key
              return buffer if number_of_digits && number_of_digits == buffer.length
            end
            return buffer if block_given? && yield(buffer)
            key = wait_for_digit(timeout || -1)
          end
        end

      end#module
    end
  end
end
