module Adhearsion
  module MenuDSL

    class MenuBuilder

      def initialize
        @patterns = []
        @menu_callbacks = {}
      end

      def build(&block)
        @context = eval("self", block.binding)
        instance_eval(&block)
      end

      def match(*args, &block)
        if args.size == 1
          if !block_given?
            raise ArgumentError, "You must provide a block or a controller name."
          end
          patterns = args[0]
          payload = nil
        elsif args.size == 2
          if block_given?
            raise ArgumentError, "You cannot specify both a block and a controller name."
          end
          patterns = args[0]
          payload = args[1]
        end
        patterns = [patterns] if patterns != Array
        if patterns.any?
          patterns.each do |pattern|
            @patterns << MatchCalculator.build_with_pattern(pattern, payload, &block)
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
        @context.instance_exec input, &callback
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
