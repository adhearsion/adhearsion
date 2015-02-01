# encoding: utf-8

module Adhearsion
  class CallController
    module MenuDSL
      class ArrayMatchCalculator < MatchCalculator
        def match(query)
          args = { :query => query, :exact_matches => [], :potential_matches => [] }

          pattern.compact.each do |pat|
            pattern_string  = pat.to_s
            query_string    = query.to_s

            if pattern_string == query_string
              args[:exact_matches] << pat
            elsif pattern_string.start_with? query_string
              args[:potential_matches] << pat
            end
          end

          new_calculated_match args
        end
      end
    end
  end
end
