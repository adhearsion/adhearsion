# encoding: utf-8

module Adhearsion
  module MenuDSL
    class CalculatedMatch

      def self.failed_match!(pattern, query, match_payload)
        new :pattern => pattern, :query => query, :match_payload => match_payload
      end

      attr_reader :match_payload, :potential_matches, :exact_matches, :pattern, :query, :block

      def initialize(options = {})
        @pattern, @query, @match_payload, @block = options.values_at :pattern, :query, :match_payload, :block
        @potential_matches  = options[:potential_matches] ? Array(options[:potential_matches]) : []
        @exact_matches      = options[:exact_matches] ? Array(options[:exact_matches]) : []
      end

      def exact_match?
        exact_matches.any?
      end

      def potential_match?
        potential_matches.any?
      end

      def failed_match?
        !(potential_match? || exact_match?)
      end

      def type_of_match
        if exact_match?
          :exact
        elsif potential_match?
          :potential
        end
      end

    end
  end
end
