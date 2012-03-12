# encoding: utf-8

require 'spec_helper'

module Adhearsion
  module MenuDSL
    describe CalculatedMatchCollection do
      def mock_with_potential_matches(potential_matches)
        CalculatedMatch.new :potential_matches => potential_matches
      end

      def mock_with_exact_matches(exact_matches)
        CalculatedMatch.new :exact_matches => exact_matches
      end

      def mock_with_potential_and_exact_matches(potential_matches, exact_matches)
        CalculatedMatch.new :potential_matches => potential_matches,
                            :exact_matches => exact_matches
      end

      it "the <<() method should collect the potential matches into the actual_potential_matches Array" do
        mock_matches_array_1 = [:foo, :bar, :qaz],
        mock_matches_array_2 = [10, 20, 30]
        mock_matches_1 = mock_with_potential_matches mock_matches_array_1
        mock_matches_2 = mock_with_potential_matches mock_matches_array_2

        subject << mock_matches_1
        subject.actual_potential_matches.should be == mock_matches_array_1

        subject << mock_matches_2
        subject.actual_potential_matches.should be == mock_matches_array_1 + mock_matches_array_2
      end

      it "the <<() method should collect the exact matches into the actual_exact_matches Array" do
        mock_matches_array_1 = [:blam, :blargh],
        mock_matches_array_2 = [5,4,3,2,1]
        mock_matches_1 = mock_with_exact_matches mock_matches_array_1
        mock_matches_2 = mock_with_exact_matches mock_matches_array_2

        subject << mock_matches_1
        subject.actual_exact_matches.should be == mock_matches_array_1

        subject << mock_matches_2
        subject.actual_exact_matches.should be == mock_matches_array_1 + mock_matches_array_2
      end

      it "if any exact matches exist, the exact_match?() method should return true" do
        subject << mock_with_exact_matches([1,2,3])
        subject.exact_match?.should be true
      end

      it "if any potential matches exist, the potential_match?() method should return true" do
        subject << mock_with_potential_matches([1,2,3])
        subject.potential_match?.should be true
      end
    end
  end
end
