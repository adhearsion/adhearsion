module Adhearsion
  module Punchblock
    module MenuDSL

      class MenuBuilder

        def initialize
          @patterns = []
          @menu_callbacks = {}
        end

        def match(patterns, payload, &block)
          patterns = [patterns] if patterns != Array
          if patterns.any?
            patterns.each do |pattern|
              @patterns << MatchCalculator.build_with_pattern(pattern, payload)
            end
          else
            raise ArgumentError, "You cannot call this method without patterns."
          end
        end

        def weighted_match_calculators
          @patterns
        end

        def execute_hook_for(symbol, input)
          callback = @menu_callbacks[symbol]
          callback.call input if callback
        end
        def invalid(&block)
          raise LocalJumpError, "Must supply a block!" unless block_given?
          @menu_callbacks[:invalid] = block
        end

        def timeout(&block)
          raise LocalJumpError, "Must supply a block!" unless block_given?
          @menu_callbacks[:timeout] = block
        end

        def failure(&block)
          raise LocalJumpError, "Must supply a block!" unless block_given?
          @menu_callbacks[:failure] = block
        end

        def calculate_matches_for(result)
          CalculatedMatchCollection.new.tap do |collection|
            weighted_match_calculators.each do |pattern|
              collection << pattern.match(result)
            end
          end
        end

      end # class MenuBuilder

    end
  end
end
