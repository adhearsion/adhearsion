# encoding: utf-8

require 'spec_helper'

module Adhearsion
  class CallController
    module MenuDSL

      describe RangeMatchCalculator do
        it "matching with a Range should handle the case of two potential matches in the range" do
          digits_that_begin_with_eleven = [110..119, 1100..1111].map { |x| Array(x) }.flatten
          calculator = RangeMatchCalculator.new 11..1111, :match_payload_doesnt_matter
          match = calculator.match '11'
          expect(match.exact_matches).to eq(['11'])
          expect(match.potential_matches).to eq(digits_that_begin_with_eleven)
        end

        it "return values of #match should be an instance of CalculatedMatch" do
          calculator = RangeMatchCalculator.new 1..9, :match_payload_doesnt_matter
          expect(calculator.match('0')).to be_an_instance_of CalculatedMatch
          expect(calculator.match('1000')).to be_an_instance_of CalculatedMatch
        end

        it "returns a failed match if the query is not numeric or coercible to numeric" do
          calculator = RangeMatchCalculator.new 1..9, :match_payload_doesnt_matter
          expect(calculator.match("ABC")).to be_an_instance_of CalculatedMatch
        end
      end

    end
  end
end
