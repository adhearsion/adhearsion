# encoding: utf-8

module Adhearsion
  module MenuDSL
    class FixnumMatchCalculator < MatchCalculator

      def match(query)
        numeric_query = coerce_to_numeric query
        exact_match, potential_match = nil
        if pattern == numeric_query
          exact_match = pattern
        elsif pattern.to_s.starts_with? query.to_s
          potential_match = pattern
        end
        new_calculated_match :query => query, :exact_matches => exact_match, :potential_matches => potential_match
      end

    end # class FixnumMatchCalculator
  end
end
