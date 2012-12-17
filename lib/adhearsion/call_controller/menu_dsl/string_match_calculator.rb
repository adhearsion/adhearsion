# encoding: utf-8

module Adhearsion
  class CallController
    module MenuDSL
      class StringMatchCalculator < MatchCalculator

        def match(query)
          args = { :query => query, :exact_matches => nil, :potential_matches => nil }

          pattern_string  = pattern.to_s
          query_string    = query.to_s

          if pattern_string == query_string
            args[:exact_matches] = [pattern]
          elsif pattern_string.starts_with? query_string
            args[:potential_matches] = [pattern]
          end

          new_calculated_match args
        end
      end
    end
  end
end
