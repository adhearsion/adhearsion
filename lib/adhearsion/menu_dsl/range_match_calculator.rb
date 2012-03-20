# encoding: utf-8

module Adhearsion
  module MenuDSL

    class RangeMatchCalculator < MatchCalculator

      def initialize(pattern, match_payload)
        raise unless pattern.first.kind_of?(Numeric) && pattern.last.kind_of?(Numeric)
        super
      end

      def match(query)
        numerical_query = coerce_to_numeric query
        if numerical_query
          exact_match = pattern.include?(numerical_query) ? query : nil
          potential_matches = numbers_in_range_like numerical_query
          potential_matches.reject! { |m| m.to_s == exact_match.to_s } if exact_match

          new_calculated_match :query => query, :exact_matches => exact_match,
            :potential_matches => potential_matches
        else
          CalculatedMatch.failed_match! pattern, query, match_payload
        end
      end

      private

      # Returns all numbers in the range (@pattern) that +begin with+ the number given
      # as the first arguement.
      #
      # NOTE: If you're having trouble reading what this method is actually doing. It's
      # effectively a much more efficient version of this:
      #
      # pattern.to_a.select { |x| x.to_s.starts_with? num.to_s }.flatten
      #
      # Huge thanks to Dave Troy (http://davetroy.blogspot.com) for this awesomely
      # efficient code!
      def numbers_in_range_like(num)
        return (pattern === 0 ? [0] : nil) if num == 0
        raise ArgumentError unless num.kind_of?(Numeric)
        Array.new.tap do |matches|
          first, last = pattern.first, pattern.last
          power = 0
          while num < last
            ones_count = 10**power - 1
            range = ([num, first].max..[num + ones_count, last].min).to_a
            matches.concat range
            num *= 10
            power += 1
          end
        end
      end

    end # class RangeMatchCalculator

  end
end
