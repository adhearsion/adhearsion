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
            match_case.should_not be_exact_match
            match_case.should be_potential_match
            match_case.potential_matches.should be == [str]

            match_case = calculator.match str
            match_case.should be_exact_match
            match_case.should_not be_potential_match
            match_case.exact_matches.should be == [str]
          end
        end

        it "matching the special DTMF characters such as * and #" do
          %w[* #].each do |special_digit|
            calculator = StringMatchCalculator.new(special_digit, match_payload)
            match_case = calculator.match special_digit
            match_case.exact_matches.first.should be == special_digit
            match_case.should be_exact_match
            match_case.should_not be_potential_match
          end
        end
      end
    end
  end
end
