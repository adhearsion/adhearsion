# encoding: utf-8

require 'spec_helper'

module Adhearsion
  class CallController
    module MenuDSL
      describe StringMatchCalculator do

        let(:match_payload) { :doesnt_matter }

        it "numerical digits mixed with special digits" do
          %w[5*11#3 5*** ###].each do |str|
            calculator = StringMatchCalculator.new str, match_payload

            match_case = calculator.match str[0,2]
            expect(match_case).not_to be_exact_match
            expect(match_case).to be_potential_match
            expect(match_case.potential_matches).to eq([str])

            match_case = calculator.match str
            expect(match_case).to be_exact_match
            expect(match_case).not_to be_potential_match
            expect(match_case.exact_matches).to eq([str])
          end
        end

        it "matching the special DTMF characters such as * and #" do
          %w[* #].each do |special_digit|
            calculator = StringMatchCalculator.new(special_digit, match_payload)
            match_case = calculator.match special_digit
            expect(match_case.exact_matches.first).to eq(special_digit)
            expect(match_case).to be_exact_match
            expect(match_case).not_to be_potential_match
          end
        end
      end
    end
  end
end
