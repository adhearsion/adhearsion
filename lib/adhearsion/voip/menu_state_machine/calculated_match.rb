module Adhearsion
  module VoIP
    class CalculatedMatch

      # Convenience method for instantiating failed matches
      def self.failed_match!(pattern, query, match_payload)
        new :pattern => pattern, :query => query, :match_payload => match_payload
      end

      attr_reader :match_payload, :potential_matches, :exact_matches, :pattern, :query

      def initialize(options={})
        @pattern, @query, @match_payload = options.values_at :pattern, :query, :match_payload
        @potential_matches = options[:potential_matches] ? Array(options[:potential_matches]) : []
        @exact_matches     = options[:exact_matches] ? Array(options[:exact_matches])     : []
      end

      def exact_match?
        exact_matches.any?
      end

      def potential_match?
        potential_matches.any?
      end

      def failed_match?
        !potential_match? && !exact_match?
      end

      def type_of_match
        if exact_match?
          :exact
        elsif potential_match?
          :potential
        end
      end

    end

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