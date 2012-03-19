# encoding: utf-8

module Adhearsion
  class CallController
    module Input

      Result = Struct.new(:response, :status, :menu) do
        def to_s
          response
        end
      end

      # Prompts for input via DTMF, handling playback of prompts,
      # timeouts, digit limits and terminator digits.
      #
      # @example A basic digit collection:
      #   ask "Welcome, ", "/opt/sounds/menu-prompt.mp3",
      #       :timeout => 10, :terminator => '#', :limit => 3 do |buffer|
      #     buffer == "12980"
      #   end
      #
      # The first arguments will be a list of sounds to play, as accepted by #play, including strings for TTS, Date and Time objects, and file paths.
      # :timeout, :terminator and :limit options may then be specified.
      # A block may be passed which is invoked on each digit being collected. If it returns true, the collection is terminated.
      #
      # @param [Object] A list of outputs to play, as accepted by #play
      # @param [Hash] options Options to use for the menu
      # @option options [Boolean] :interruptible If the prompt should be interruptible or not. Defaults to true
      # @option options [Integer] :limit Digit limit (causes collection to cease after a specified number of digits have been collected)
      # @option options [Integer] :timeout Timeout in seconds before the first and between each input digit
      # @option options [String] :terminator Digit to terminate input
      #
      # @return [Result] a result object from which the #response and #status may be established
      #
      # @see play
      # @see pass
      #
      def ask(*args, &block)
        options = args.last.kind_of?(Hash) ? args.pop : {}
        sound_files = args.flatten

        menu_instance = MenuDSL::Menu.new options do
          validator(&block) if block
        end
        menu_instance.validate :basic
        result_of_menu = nil

        until MenuDSL::Menu::MenuResultDone === result_of_menu
          result_of_menu = menu_instance.continue

          if result_of_menu.is_a?(MenuDSL::Menu::MenuGetAnotherDigit)
            next_digit = play_sound_files_for_menu menu_instance, sound_files
            menu_instance << next_digit if next_digit
          end # case
        end # while

        Result.new.tap do |result|
          result.response = menu_instance.result
          result.status   = menu_instance.status
          result.menu     = menu_instance
        end
      end

      # Creates and manages a multiple choice menu driven by DTMF, handling playback of prompts,
      # invalid input, retries and timeouts, and final failures.
      #
      # @example A complete example of the method is as follows:
      #   ask "Welcome, ", "/opt/sounds/menu-prompt.mp3", :tries => 2, :timeout => 10 do
      #     match 1, OperatorController
      #
      #     match 10..19 do
      #       pass DirectController
      #     end
      #
      #     match 5, 6, 9 do |exten|
      #      play "The #{exten} extension is currently not active"
      #     end
      #
      #     match '7', OfficeController
      #
      #     invalid { play "Please choose a valid extension" }
      #     timeout { play "Input timed out, try again." }
      #     failure { pass OperatorController }
      #   end
      #
      # The first arguments will be a list of sounds to play, as accepted by #play, including strings for TTS, Date and Time objects, and file paths.
      # :tries and :timeout options respectively specify the number of tries before going into failure, and the timeout in seconds allowed on each digit input.
      # The most important part is the following block, which specifies how the menu will be constructed and handled.
      #
      # #match handles connecting an input pattern to a payload.
      # The pattern can be one or more of: an integer, a Range, a string, an Array of the possible single types.
      # Input is matched against patterns, and the first exact match has it's payload executed.
      # Matched input is passed in to the associated block, or to the controller through #options.
      #
      # Allowed payloads are the name of a controller class, in which case it is executed through its #run method, or a block.
      #
      # #invalid has its associated block executed when the input does not possibly match any pattern.
      # #timeout's block is run when time expires before or between input digits.
      # #failure runs its block when the maximum number of tries is reached without an input match.
      #
      # #validator runs its block on each digit being collected. If it returns true, the collection is terminated.
      #
      # Execution of the current context resumes after #ask finishes. If you wish to jump to an entirely different controller, use #pass.
      # Menu will return :failed if failure was reached, or :done if a match was executed.
      #
      # @param [Object] A list of outputs to play, as accepted by #play
      # @param [Hash] options Options to use for the menu
      # @option options [Integer] :tries Number of tries allowed before failure
      # @option options [Integer] :timeout Timeout in seconds before the first and between each input digit
      # @option options [Boolean] :interruptible If the prompt should be interruptible or not. Defaults to true
      #
      # @return [Result] a result object from which the #response and #status may be established
      #
      # @see play
      # @see pass
      #
      def menu(*args, &block)
        options = args.last.kind_of?(Hash) ? args.pop : {}
        sound_files = args.flatten

        menu_instance = MenuDSL::Menu.new options, &block
        menu_instance.validate
        result_of_menu = nil

        catch :finish do
          until MenuDSL::Menu::MenuResultDone === result_of_menu
            if menu_instance.should_continue?
              result_of_menu = menu_instance.continue
            else
              logger.debug "Menu failed to get valid input. Calling \"failure\" hook."
              menu_instance.execute_failure_hook
              throw :finish
            end

            case result_of_menu
            when MenuDSL::Menu::MenuResultInvalid
              logger.debug "Menu received invalid input. Calling \"invalid\" hook and restarting."
              menu_instance.execute_invalid_hook
              menu_instance.restart!
              result_of_menu = nil
            when MenuDSL::Menu::MenuGetAnotherDigit
              next_digit = play_sound_files_for_menu menu_instance, sound_files
              if next_digit
                menu_instance << next_digit
              else
                case result_of_menu
                when MenuDSL::Menu::MenuGetAnotherDigitOrFinish
                  jump_to result_of_menu.match_object, :extension => result_of_menu.new_extension
                  throw :finish
                when MenuDSL::Menu::MenuGetAnotherDigitOrTimeout
                  logger.debug "Menu timed out. Calling \"timeout\" hook and restarting."
                  menu_instance.execute_timeout_hook
                  menu_instance.restart!
                  result_of_menu = nil
                end
              end
            when MenuDSL::Menu::MenuResultFound
              logger.debug "Menu received valid input (#{result_of_menu.new_extension}). Calling the matching hook."
              jump_to result_of_menu.match_object, :extension => result_of_menu.new_extension
              throw :finish
            end # case
          end # while
        end

        Result.new.tap do |result|
          result.response = menu_instance.result
          result.status   = menu_instance.status
          result.menu     = menu_instance
        end
      end

      def play_sound_files_for_menu(menu_instance, sound_files) # :nodoc:
        digit = nil
        if sound_files.any? && menu_instance.digit_buffer_empty?
          if menu_instance.interruptible
            digit = interruptible_play(*sound_files)
          else
            play(*sound_files)
          end
        end
        digit || wait_for_digit(menu_instance.timeout)
      end

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

      def jump_to(match_object, overrides = nil) # :nodoc:
        if match_object.block
          instance_exec overrides[:extension], &match_object.block
        else
          invoke match_object.match_payload, overrides
        end
      end

    end # module
  end
end
