# encoding: utf-8

module Adhearsion
  module MenuDSL

    class Menu

      DEFAULT_MAX_NUMBER_OF_TRIES = 1
      DEFAULT_TIMEOUT             = 5

      InvalidStructureError = Class.new Adhearsion::Error

      attr_reader :builder, :timeout, :tries_count, :max_number_of_tries, :terminator, :limit, :interruptible, :status

      def initialize(options = {}, &block)
        @tries_count          = 0 # Counts the number of tries the menu's been executed
        @timeout              = options[:timeout] || DEFAULT_TIMEOUT
        @max_number_of_tries  = options[:tries]   || DEFAULT_MAX_NUMBER_OF_TRIES
        @terminator           = options[:terminator].to_s
        @limit                = options[:limit]
        @interruptible        = options.has_key?(:interruptible) ? options[:interruptible] : true
        @builder              = MenuDSL::MenuBuilder.new
        @terminated           = false

        @builder.build(&block) if block

        initialize_digit_buffer
      end

      def validate(mode = nil)
        case mode
        when :basic
          @terminator.present? || !!@limit || raise(InvalidStructureError, "You must specify at least one of limit or terminator")
        else
          @builder.has_matchers? || raise(InvalidStructureError, "You must specify one or more matchers")
        end
      end

      def <<(other)
        if other == terminator
          @terminated = true
        else
          digit_buffer << other
        end
      end

      def digit_buffer
        @digit_buffer
      end

      def digit_buffer_string
        digit_buffer.to_s
      end
      alias :result :digit_buffer_string

      def digit_buffer_empty?
        digit_buffer.empty?
      end

      def continue
        return get_another_digit_or_timeout! if digit_buffer_empty?

        return menu_terminated! if @terminated
        return menu_limit_reached! if limit && digit_buffer.size >= limit

        return menu_validator_terminated! if execute_validator_hook

        calculated_matches = builder.calculate_matches_for digit_buffer_string

        if calculated_matches.exact_match_count >= 1
          first_exact_match = calculated_matches.exact_matches.first
          if calculated_matches.potential_match_count.zero?
            menu_result_found! first_exact_match, digit_buffer_string
          else
            get_another_digit_or_finish! first_exact_match.match_payload, first_exact_match.query
          end
        elsif calculated_matches.potential_match_count >= 1 || !@builder.has_matchers?
          get_another_digit_or_timeout!
        else
          invalid!
        end
      end

      def should_continue?
        tries_count < max_number_of_tries
      end

      def restart!
        @tries_count += 1
        digit_buffer.clear!
      end

      def execute_invalid_hook
        builder.execute_hook_for :invalid, digit_buffer_string
      end

      def execute_timeout_hook
        builder.execute_hook_for :timeout, digit_buffer_string
      end

      def execute_failure_hook
        builder.execute_hook_for :failure, digit_buffer_string
      end

      def execute_validator_hook
        builder.execute_hook_for :validator, digit_buffer_string
      end

      protected

      # If you're using a more complex class in subclasses, you may want to override this method in addition to the
      # digit buffer, digit_buffer_empty, and digit_buffer_string methods
      def initialize_digit_buffer
        @digit_buffer = ClearableStringBuffer.new
      end

      def invalid!
        @status = :invalid
        MenuResultInvalid.new
      end

      def menu_result_found!(match_object, new_extension)
        @status = :matched
        MenuResultFound.new(match_object, new_extension)
      end

      def menu_terminated!
        @status = :terminated
        MenuTerminated.new
      end

      def menu_validator_terminated!
        @status = :validator_terminated
        MenuValidatorTerminated.new
      end

      def menu_limit_reached!
        @status = :limited
        MenuLimitReached.new
      end

      def get_another_digit_or_finish!(match_payload, new_extension)
        @status = :multi_matched
        MenuGetAnotherDigitOrFinish.new(match_payload, new_extension)
      end

      def get_another_digit_or_timeout!
        @status = :potential
        MenuGetAnotherDigitOrTimeout.new
      end

      # The superclass from which all message-like exceptions descend. It should never
      # be instantiated directly.
      MenuResult      = Class.new
      MenuResultDone  = Class.new MenuResult

      class MenuResultFound < MenuResult

        attr_reader :match_object, :new_extension

        def initialize(match_object, new_extension)
          super()
          @match_object = match_object
          @new_extension = new_extension
        end

      end #class MenuResultFound < MenuResult

      MenuGetAnotherDigit = Module.new

      class MenuGetAnotherDigitOrFinish < MenuResultFound
        include MenuGetAnotherDigit
      end

      class MenuGetAnotherDigitOrTimeout < MenuResult
        include MenuGetAnotherDigit
      end

      MenuResultInvalid = Class.new MenuResult

      MenuTerminated = Class.new MenuResultDone
      MenuValidatorTerminated = Class.new MenuResultDone
      MenuLimitReached = Class.new MenuResultDone

      # For our default purpose, we need the digit_buffer to behave much like a normal String except that it should
      # handle its own resetting (clearing)
      class ClearableStringBuffer < String
        def clear!
          replace ""
        end

        def <<(other)
          super other.to_s
        end
      end


    end # class Menu

  end
end
