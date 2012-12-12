# encoding: utf-8

module Adhearsion
  class CallController
    module MenuDSL
      class ArrayMatchCalculator < MatchCalculator

        def initialize(pattern, match_payload, &block)
          super
          pattern.compact!
        end

        def match(query)
          if pattern.size == 0
            return new_calculated_match :query => query, :exact_matches => nil, :potential_matches => nil
          end
          args = { :query => query, :exact_matches => [], :potential_matches => [] }
          pattern.each do |pat|
            case pat
            when Fixnum
              numeric_query = coerce_to_numeric query
              if pat == numeric_query
                args[:exact_matches] += [pat]
              elsif pat.to_s.starts_with? query.to_s
                args[:potential_matches] += [pat]
              end
            when String
              if pat == query.to_s
                args[:exact_matches] += [pat]
              elsif pat.starts_with? query.to_s
                args[:potential_matches] += [pat]
              end
            end
          end
          new_calculated_match args
        end

      end
    end
  end
end
