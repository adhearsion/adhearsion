module Adhearsion
  module MenuDSL

    class Menu

      DEFAULT_MAX_NUMBER_OF_TRIES = 1
      DEFAULT_TIMEOUT             = 5

      relationships :menu_builder => MenuDSL::MenuBuilder

      attr_reader :builder, :timeout, :tries_count, :max_number_of_tries

      def initialize(options={}, &block)
        @tries_count          = 0 # Counts the number of tries the menu's been executed
        @timeout              = options[:timeout] || DEFAULT_TIMEOUT
        @max_number_of_tries  = options[:tries]   || DEFAULT_MAX_NUMBER_OF_TRIES
        @builder = menu_builder.new

        @builder.build(&block)

        initialize_digit_buffer
      end

      def <<(other)
        digit_buffer << other
      end

      def digit_buffer
        @digit_buffer
      end

      def digit_buffer_string
        digit_buffer.to_s
      end

      def digit_buffer_empty?
        digit_buffer.empty?
      end

      def continue
        return MenuGetAnotherDigitOrTimeout.new if digit_buffer_empty?

        calculated_matches = builder.calculate_matches_for digit_buffer_string

        if calculated_matches.exact_match_count >= 1
          first_exact_match = calculated_matches.exact_matches.first
          if calculated_matches.potential_match_count.zero?
            menu_result_found! first_exact_match, digit_buffer_string
          else
            get_another_digit_or_finish!(first_exact_match.match_payload, first_exact_match.query)
          end
        elsif calculated_matches.potential_match_count >= 1
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
        builder.execute_hook_for(:invalid, digit_buffer_string)
      end

      def execute_timeout_hook
        builder.execute_hook_for(:timeout, digit_buffer_string)
      end

      def execute_failure_hook
        builder.execute_hook_for(:failure, digit_buffer_string)
      end

      protected

      # If you're using a more complex class in subclasses, you may want to override this method in addition to the
      # digit buffer, digit_buffer_empty, and digit_buffer_string methods
      def initialize_digit_buffer
        @digit_buffer = ClearableStringBuffer.new
      end

      def invalid!
        return MenuResultInvalid.new
      end

      def menu_result_found!(match_object, new_extension)
        return MenuResultFound.new(match_object, new_extension)
      end

      def get_another_digit_or_finish!(match_payload, new_extension)
        return MenuGetAnotherDigitOrFinish.new(match_payload, new_extension)
      end

      def get_another_digit_or_timeout!
        return MenuGetAnotherDigitOrTimeout.new
      end

      # The superclass from which all message-like exceptions descend. It should never
      # be instantiated directly.
      class MenuResult; end
      class MenuResultDone < MenuResult; end

      class MenuResultFound < MenuResult

        attr_reader :match_object, :new_extension

        def initialize(match_object, new_extension)
          super()
          @match_object = match_object
          @new_extension = new_extension
        end

      end #class MenuResultFound < MenuResult

      module MenuGetAnotherDigit; end

      class MenuGetAnotherDigitOrFinish < MenuResultFound
        include MenuGetAnotherDigit
      end

      class MenuGetAnotherDigitOrTimeout < MenuResult
        include MenuGetAnotherDigit
      end

      class MenuResultInvalid < MenuResult; end

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
