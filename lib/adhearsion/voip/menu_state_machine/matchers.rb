require File.join(File.dirname(__FILE__), 'calculated_match')

module Adhearsion
  module VoIP
    class MatchCalculator

      class << self

        def build_with_pattern(pattern, match_payload, &block)
          class_for_pattern_type(pattern.class.name).new(pattern, match_payload, &block)
        end

        def inherited(klass)
          subclasses << klass
        end

        private

        def class_for_pattern_type(pattern_type)
          sought_class_name = "Adhearsion::VoIP::#{pattern_type.camelize}MatchCalculator"
          subclasses.find { |klass| klass.name == sought_class_name }
        end

        def subclasses
          @@subclasses ||= []
        end

      end

      attr_reader :pattern, :match_payload
      def initialize(pattern, match_payload)
        @pattern, @match_payload = pattern, match_payload
      end

      protected

      def new_calculated_match(options)
        CalculatedMatch.new({:pattern => pattern, :match_payload => match_payload}.merge(options))
      end

      def coerce_to_numeric(victim)
        victim.kind_of?(Numeric) ? victim : (victim.to_s =~ /^\d+$/ ? victim.to_s.to_i : nil )
      end
    end

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
          CalculatedMatch.failed_match!(pattern, query, match_payload)
        end
      end

      private

      # Returns all numbers in the range (@pattern) that +begin with+ the number given
      # as the first argument.
      #
      # NOTE! If you're having trouble reading what this method is actually doing, it's
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
            matches.concat((([num, first].max)..[(num+ones_count), last].min).to_a)
            num *= 10
            power += 1
          end
        end
      end
    end

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
    end

    class StringMatchCalculator < MatchCalculator
      def match(query)
        args = { :query => query, :exact_matches => nil,
                 :potential_matches => nil }

        if pattern == query.to_s
          args[:exact_matches] = [pattern]
        elsif pattern.starts_with? query.to_s
          args[:potential_matches] = [pattern]
        end

        new_calculated_match args
      end
    end
  end
end