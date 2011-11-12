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

        # Utility method to create a single-digit grammar to accept only some digits
        #
        # @param [String] String representing the digits to accept
        # @return [RubySpeech::GRXML::Grammar] A grammar suitable for use in SSML prompts.
        def grammar_accept(digits = '0123456789#*')
          allowed_digits = '0123456789#*'
          gram_digits = digits.chars.map {|x| x if allowed_digits.include? x}
          gram_digits.compact!

          grammar = RubySpeech::GRXML.draw do
            self.mode = 'dtmf'
            self.root = 'inputdigits'
            rule id: 'acceptdigits' do
              one_of do
                gram_digits.each {|d| item { d.to_s}}
              end
            end


            rule id: 'inputdigits', scope: 'public' do
              item repeat: '1' do
                ruleref uri: '#acceptdigits'
              end
            end

          end
          grammar
        end

        # Waits for a single digit and returns it, or returns nil if nothing was pressed
        #
        # @param [Integer] the timeout to wait before returning, in milliseconds
        # @return [String|nil] the pressed key, or nil if timeout was reached
        def wait_for_digit(timeout = 1000)
          input_component = execute_component_and_await_completion ::Punchblock::Component::Input.new :mode => :dtmf,
            :initial_timeout => timeout,
            :inter_digit_timeout => timeout,
              :grammar => {
                :value => grammar_accept.to_s
            }

          reason = input_component.complete_event.resource.reason
          result = reason.respond_to?(:interpretation) ? reason.interpretation : nil
          parse_single_dtmf result
        end

        # Parses a single DTMF tone in the format dtmf-*
        #
        # @param [String] the tone string to be parsed
        # @return [String] the digit in case input was 0-9, * or # if star or pound respectively
        def parse_single_dtmf(result)
          return if result.nil?
          case tone = result.split('-')[1]
          when 'star'
            '*'
          when 'pound'
            '#'
          else
            tone
          end
        end


        # Reworking of input
        # - Raise an exception if both :play and :speak are specified - DONE
        # - Allow :play arguments to be automatic, hashes, or SSML (is_a RubySpeech::SSML::Speak)
        # - :speak stays as a quick TTS option
        #
        
        def input(*args, &block)
          begin
            input! *args, &block
          rescue PlaybackError => e
            logger.warn { e }
            retry # If sound playback fails, play the remaining sound files and wait for digits
          end
        end
        

        def input!(*args, &block)
          options = args.last.kind_of?(Hash) ? args.pop : {}
          number_of_digits = args.shift

          options[:play] = Array(case options[:play]
            when String
              options[:play]
            when Array
              options[:play].compact
            when NilClass
              []
            else
              [options[:play]]
          end)

          if options.has_key?(:interruptible) && options[:interruptible] == false
            play_command = :play!
          else
            options[:interruptible] = true
            play_command = :interruptible_play!
          end

          if options.has_key? :speak
            raise ArgumentError, ':speak must be a Hash' unless options[:speak].is_a? Hash
            raise ArgumentError, 'Must include a text string when requesting TTS fallback' unless options[:speak].has_key?(:text)
            if options.has_key?(:speak) && options.has_key?(:play) && options[:play].size > 0
              raise ArgumentError, 'Must specify only one of :play or :speak'
            end
            # options[:speak][:interruptible] = options[:interruptible]
          end

          timeout         = options[:timeout]
          terminating_key = options[:accept_key]
          if terminating_key
            terminating_key = terminating_key.to_s
          elsif number_of_digits.nil? && !terminating_key.equal?(false)
            terminating_key = '#'
          end
          if number_of_digits && number_of_digits < 0
            ahn_log.warn "Giving -1 to #input is now deprecated. Do not specify a first " +
                             "argument to allow unlimited digits." if number_of_digits == -1
            raise ArgumentError, "The number of digits must be positive!"
          end
          buffer = ''
          if options[:play].any?
            # Consume the sound files one at a time. In the event of playback
            # failure, this tells us which files remain unplayed.
            while output = options[:play].shift
              if output.class == Hash
                argument = output.delete(:value)
                raise ArgumentError, ':value has to be specified for each :play argument that is a Hash' if argument.nil?
                key = send play_command, [argument, output]
              else
                key = send play_command, output
              end
              key = nil if play_command == :play!
              break if key
            end
            key ||= ''
            # instead use a normal play command, :speak is basically an alias
          elsif options[:speak]
            speak_output = options[:speak].delete(:text)
            key = send play_command, speak_output, options[:speak]
            key = nil if play_command == :play!
          else
            key = wait_for_digit timeout || nil
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
            key = wait_for_digit(timeout || nil)
          end
        end#input!

      end#module
    end
  end
end
