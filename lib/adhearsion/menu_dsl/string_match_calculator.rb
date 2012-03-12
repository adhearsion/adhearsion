# encoding: utf-8

module Adhearsion
  module MenuDSL

    class StringMatchCalculator < MatchCalculator

      def match(query)
        args = { :query => query, :exact_matches => nil, :potential_matches => nil }

        if pattern == query.to_s
          args[:exact_matches] = [pattern]
        elsif pattern.starts_with? query.to_s
          args[:potential_matches] = [pattern]
        end

        new_calculated_match args
      end

    end # class StringMatchCalculator

  end
end
