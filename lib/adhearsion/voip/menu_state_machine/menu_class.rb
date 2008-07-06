require 'adhearsion/voip/menu_state_machine/menu_builder'
module Adhearsion
  module VoIP
    class Menu

      DEFAULT_MAX_NUMBER_OF_TRIES = 1
      DEFAULT_TIMEOUT             = 5 # seconds

      relationships :menu_builder => MenuBuilder

      attr_reader :builder, :timeout, :tries_count, :max_number_of_tries, :digit_container
      def initialize(options={}, &block)
        @tries_count         = 0 # Counts the number of tries the menu's been executed
        
        @timeout             = options[:timeout] || DEFAULT_TIMEOUT
        @max_number_of_tries = options[:tries]   || DEFAULT_MAX_NUMBER_OF_TRIES

        @builder = menu_builder.new
        yield @builder

        initialize_digit_container
      end

      def <<(other)
        digit_container << other
      end

      def continue
        raise MenuGetAnotherDigitOrTimeout if digit_container.empty?

        calculated_matches = builder.calculate_matches_for digit_container

        if calculated_matches.exact_match_count >= 1
          first_exact_match = calculated_matches.exact_matches.first
          if calculated_matches.potential_match_count.zero?
            # Match found with no extenuating ambiguities! Go with the first exact match
            menu_result_found! first_exact_match.match_payload, digit_container
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
        @digit_container.clear!
      end

      def execute_invalid_hook
        builder.execute_hook_for(:invalid, digit_container)
      end

      def execute_timeout_hook
        builder.execute_hook_for(:premature_timeout, digit_container)
      end

      def execute_failure_hook
        builder.execute_hook_for(:failure, digit_container)
      end

      protected
      
      # If you're using a more complex class in subclasses, you may want to override this method in addition to the 
      # digit_container method
      def initialize_digit_container
        @digit_container = ClearableString.new
      end

      def invalid!
        raise MenuResultInvalid
      end

      def menu_result_found!(match_payload, new_extension)
        raise MenuResultFound.new(match_payload, new_extension)
      end

      def get_another_digit_or_finish!(match_payload, new_extension)
        raise MenuGetAnotherDigitOrFinish.new(match_payload, new_extension)
      end

      def get_another_digit_or_timeout!
        raise MenuGetAnotherDigitOrTimeout
      end

      # The superclass from which all message-like exceptions decend. It should never
      # be instantiated directly.
      class MenuResult < Exception; end

      # Raised when the user's input matches
      class MenuResultFound < MenuResult
        attr_reader :match_payload, :new_extension
        def initialize(match_payload, new_extension)
          super()
          @match_payload  = match_payload
          @new_extension = new_extension
        end
      end

      module MenuGetAnotherDigit; end

      class MenuGetAnotherDigitOrFinish < MenuResultFound
        include MenuGetAnotherDigit
      end

      class MenuGetAnotherDigitOrTimeout < MenuResult
        include MenuGetAnotherDigit
      end

      class MenuResultFound < MenuResult; end

      # Raised when the user's input matches no patterns
      class MenuResultInvalid < MenuResult; end

      # For our default purposes, we need the digit_container to behave much like a normal String except that it should 
      # handle its own resetting (clearing).
      class ClearableString < String
        def clear!
          replace ""
        end
      end

    end
  end
end