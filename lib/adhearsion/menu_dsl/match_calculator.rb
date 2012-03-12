# encoding: utf-8

module Adhearsion
  module MenuDSL
    class MatchCalculator

      class << self

        def build_with_pattern(pattern, match_payload, &block)
          class_for_pattern(pattern).new pattern, match_payload, &block
        end

        private

        def class_for_pattern(pattern)
          MenuDSL.const_get "#{pattern.class.name.camelize}MatchCalculator"
        end
      end

      attr_reader :pattern, :match_payload, :block

      def initialize(pattern, match_payload, &block)
        @pattern, @match_payload, @block = pattern, match_payload, block
      end

      protected

      def new_calculated_match(options)
        CalculatedMatch.new({:pattern => pattern, :match_payload => match_payload, :block => block}.merge(options))
      end

      def coerce_to_numeric(victim)
        victim.kind_of?(Numeric) ? victim : (victim.to_s =~ /^\d+$/ ? victim.to_s.to_i : nil )
      end

    end # class MatchCalculator
  end
end
