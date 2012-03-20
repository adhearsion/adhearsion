# encoding: utf-8

require 'spec_helper'

module Adhearsion
  module MenuDSL

    describe RangeMatchCalculator do
      it "matching with a Range should handle the case of two potential matches in the range" do
        digits_that_begin_with_eleven = [110..119, 1100..1111].map { |x| Array(x) }.flatten
        calculator = RangeMatchCalculator.new 11..1111, :match_payload_doesnt_matter
        match = calculator.match 11
        match.exact_matches.should be == [11]
        match.potential_matches.should be == digits_that_begin_with_eleven
      end

      it "return values of #match should be an instance of CalculatedMatch" do
        calculator = RangeMatchCalculator.new 1..9, :match_payload_doesnt_matter
        calculator.match(0).should be_an_instance_of CalculatedMatch
        calculator.match(1000).should be_an_instance_of CalculatedMatch
      end

      it "returns a failed match if the query is not numeric or coercible to numeric" do
        calculator = RangeMatchCalculator.new 1..9, :match_payload_doesnt_matter
        calculator.match("ABC").should be_an_instance_of CalculatedMatch
      end
    end

  end
end
