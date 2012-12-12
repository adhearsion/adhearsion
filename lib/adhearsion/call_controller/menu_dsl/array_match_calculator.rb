# encoding: utf-8

module Adhearsion
  class CallController
    module MenuDSL

      class ArrayMatchCalculator < MatchCalculator
        @array_type = nil

        def initialize(pattern, match_payload)
          if pattern.size == 0
            super
            return
          end
          @array_type = pattern.first.class
          raise unless [String,Fixnum].include?(@array_type)
          pattern.each do |rec|
            next if rec.nil?
            raise unless rec.class == @array_type
          end
          super
        end

        def match(query)
          if pattern.size == 0
            return new_calculated_match :query => query, :exact_matches => nil, :potential_matches => nil
          end
          args = { :query => query, :exact_matches => [], :potential_matches => [] }
          exact_match, potential_match = nil
          pattern.each do |pat|
            next if pat.nil?
            if @array_type == Fixnum
              numeric_query = coerce_to_numeric query
              if pat == numeric_query
                args[:exact_matches] += [pat]
              elsif pat.to_s.starts_with? query.to_s
                args[:potential_matches] += [pat]
              end
            elsif @array_type == String
              if pat == query.to_s
                args[:exact_matches] += [pat]
              elsif pat.starts_with? query.to_s
                args[:potential_matches] += [pat]
              end
            end
          end
          new_calculated_match args
        end

      end # class ArrayMatchCalculator

    end
  end
end