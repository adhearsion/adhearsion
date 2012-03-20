# encoding: utf-8

module Adhearsion
  module MenuDSL
    class CalculatedMatchCollection
      attr_reader :calculated_matches, :potential_matches, :exact_matches,
        :actual_potential_matches, :actual_exact_matches

      def initialize
        @calculated_matches       = []
        @potential_matches        = []
        @exact_matches            = []
        @actual_potential_matches = []
        @actual_exact_matches     = []
      end

      def <<(calculated_match)
        calculated_matches << calculated_match
        actual_potential_matches.concat calculated_match.potential_matches
        actual_exact_matches.concat calculated_match.exact_matches

        potential_matches << calculated_match if calculated_match.potential_match?
        exact_matches << calculated_match if calculated_match.exact_match?
      end

      def potential_match_count
        actual_potential_matches.size
      end

      def exact_match_count
        actual_exact_matches.size
      end

      def potential_match?
        potential_match_count > 0
      end

      def exact_match?
        exact_match_count > 0
      end
    end
  end
end
