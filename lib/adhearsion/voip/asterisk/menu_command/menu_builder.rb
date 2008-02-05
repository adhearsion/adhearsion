require File.join(File.dirname(__FILE__), 'matchers.rb')

module Adhearsion::VoIP::Asterisk::Commands
  class MenuBuilder

    def initialize
      @patterns = []
      @menu_callbacks = {}
    end

    def method_missing(context_name, *patterns, &block)
      name_string = context_name.to_s
      if patterns.empty? && block_given?
        @patterns << MatchCalculator.build_with_pattern(:custom, context_name, &block)
      elsif patterns.any?
        patterns.each do |pattern|
          @patterns << MatchCalculator.build_with_pattern(pattern, context_name)
        end
      else
        raise ArgumentError, "You cannot call this method without a pattern or a block!"
      end
      nil
    end

    def weighted_match_calculators
      @patterns
    end

    def execute_hook_for(symbol, input)
      callback = @menu_callbacks[symbol]
      callback.call input if callback
    end

    def on_invalid(&block)
      raise LocalJumpError, "Must supply a block!" unless block_given?
      @menu_callbacks[:invalid] = block
    end

    def on_premature_timeout(&block)
      raise LocalJumpError, "Must supply a block!" unless block_given?
      @menu_callbacks[:premature_timeout] = block
    end

    def on_failure(&block)
      raise LocalJumpError, "Must supply a block!" unless block_given?
      @menu_callbacks[:failure] = block
    end
  
    def calculate_matches_for(result)
      returning CalculatedMatchCollection.new do |collection|
        weighted_match_calculators.each do |pattern|
          collection << pattern.match(result)
        end
      end
    end
  
  end
end