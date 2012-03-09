module Adhearsion
  class CallController
    module Input
      #
      # Waits for a single digit and returns it, or returns nil if nothing was pressed
      #
      # @param [Integer] the timeout to wait before returning, in seconds. nil or -1 mean no timeout.
      # @return [String|nil] the pressed key, or nil if timeout was reached.
      #
      def wait_for_digit(timeout = 1) # :nodoc:
        timeout = nil if timeout == -1
        timeout *= 1_000 if timeout
        input_component = execute_component_and_await_completion ::Punchblock::Component::Input.new :mode => :dtmf,
          :initial_timeout => timeout,
          :inter_digit_timeout => timeout,
            :grammar => {
              :value => grammar_accept.to_s
          }

        reason = input_component.complete_event.reason
        result = reason.respond_to?(:interpretation) ? reason.interpretation : nil
        parse_single_dtmf result
      end

      # Used to receive keypad input from the user. Digits are collected
      # via DTMF (keypad) input until one of three things happens:
      #
      #  1. The number of digits you specify as the first argument is collected
      #  2. The timeout you specify with the :timeout option elapses, in seconds.
      #  3. The "#" key (or the key you specify with :accept_key) is pressed
      #
      # Usage examples
      #
      #   input   # Receives digits until the caller presses the "#" key
      #   input 3 # Receives three digits. Can be 0-9, * or #
      #   input 5, :accept_key => "*"   # Receive at most 5 digits, stopping if '*' is pressed
      #   input 1, :timeout => 60000 # Receive a single digit, returning an empty
      #                                   string if the timeout is encountered
      #   input 9, :timeout => 7000, :accept_key => "0" # Receives nine digits, returning
      #                                              # when the timeout is encountered
      #                                              # or when the "0" key is pressed.
      #   input 3, :play => "you-sound-cute"
      #   input :play => ["if-this-is-correct-press", 1, "otherwise-press", 2]
      #   input :interruptible => false, :play => ["you-cannot-interrupt-this-message"] # Disallow DTMF (keypad) interruption
      #                                                                                 # until after all files are played.
      #
      # When specifying outputs to play, the playback of the sequence of files will stop
      # immediately when the user presses the first digit.
      #
      # Accepted output types are:
      #   1. Any object supported by detect_type (@see detect_type)
      #   2. Any valid SSML document
      #   3. An Hash with at least the :value key set to a supported object type, and other keys as options to the specific output
      #
      # :play usage examples
      #   input 1, :play => RubySpeech::SSML.draw { string "hello there" } # 1 digit, SSML document
      #   input 2, :play => "hello there" # 2 digits, string
      #   input 2, :play => {:value => Time.now, :strftime => "%H:%M"} # 2 digits, Hash with :value
      #   input :play => [ "the time is", {:value => Time.now, :strftime => "%H:%M"} ] # no digit limit, two mixed outputs
      #
      # The :timeout option works like a digit timeout, therefore each digit pressed
      # causes the timer to reset. This is a much more user-friendly approach than an
      # absolute timeout.
      #
      # Note that when the digit limit is not specified the :accept_key becomes "#".
      # Otherwise there would be no way to end the collection of digits. You can
      # obviously override this by passing in a new key with :accept_key.
      #
      # @return [String] The keypad input received. An empty string is returned in the
      #                  absense of input. If the :accept_key argument was pressed, it
      #                  will not appear in the output.
      def input(*args, &block)
        begin
          input! *args, &block
        rescue PlaybackError => e
          logger.warn { e }
          retry # If sound playback fails, play the remaining sound files and wait for digits
        end
      end

      # Same as {#input}, but immediately raises an exception if sound playback fails
      #
      # @return (see #input)
      # @raise [Adhearsion::PlaybackError] If a sound file cannot be played
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

        play_command = if options.has_key?(:interruptible) && options[:interruptible] == false
          :play!
        else
          options[:interruptible] = true
          :interruptible_play!
        end

        if options.has_key? :speak
          raise ArgumentError, ':speak must be a Hash' unless options[:speak].is_a? Hash
          raise ArgumentError, 'Must include a text string when requesting TTS fallback' unless options[:speak].has_key?(:text)
          if options.has_key?(:speak) && options.has_key?(:play) && options[:play].size > 0
            raise ArgumentError, 'Must specify only one of :play or :speak'
          end
        end

        timeout     = options[:timeout]
        terminator  = options[:terminator]

        terminator = if terminator
          terminator.to_s
        elsif number_of_digits.nil? && !terminator.equal?(false)
          '#'
        end

        if number_of_digits && number_of_digits < 0
          logger.warn "Giving -1 to #input is now deprecated. Do not specify a first " +
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
              output = [argument, output]
            end
            key = send play_command, output
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
          key = wait_for_digit timeout
        end

        loop do
          return buffer if key.nil?
          if terminator
            if key == terminator
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
          key = wait_for_digit timeout
        end
      end # #input!
    end # Input
  end
end
