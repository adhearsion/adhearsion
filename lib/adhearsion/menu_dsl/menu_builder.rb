# encoding: utf-8

module Adhearsion
  module MenuDSL

    class MenuBuilder

      attr_accessor :patterns, :menu_callbacks

      def initialize
        @patterns = []
        @menu_callbacks = {}
        @context = nil
      end

      def build(&block)
        @context = eval "self", block.binding
        instance_eval(&block)
      end

      def match(*args, &block)
        payload = if block_given?
          raise ArgumentError, "You cannot specify both a block and a controller name." if args.last.is_a? Class
          nil
        else
          raise ArgumentError, "You need to provide a block or a controller name." unless args.last.is_a? Class
          args.pop
        end

        raise ArgumentError, "You cannot call this method without patterns." if args.empty?

        args.each do |pattern|
          @patterns << MatchCalculator.build_with_pattern(pattern, payload, &block)
        end
      end

      def weighted_match_calculators
        @patterns
      end

      def has_matchers?
        @patterns.size > 0
      end

      def execute_hook_for(symbol, input)
        callback = @menu_callbacks[symbol]
        return unless callback
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

      def validator(&block)
        raise LocalJumpError, "Must supply a block!" unless block_given?
        @menu_callbacks[:validator] = block
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
