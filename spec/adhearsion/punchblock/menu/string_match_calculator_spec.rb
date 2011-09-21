require 'spec_helper'

module Adhearsion
  module Punchblock
    module Menu

      describe "StringMatchCalculator" do
        include PunchblockCommandTestHelpers

        attr_reader :match_payload
        before(:each) do
          @match_payload = :doesnt_matter
        end

        let(:stringmatchcalculator) { StringMatchCalculator }

        it "numerical digits mixed with special digits" do
          %w[5*11#3 5*** ###].each do |str|
            calculator = stringmatchcalculator.new(str, match_payload)

            match_case = calculator.match str[0,2]
            match_case.exact_match?.should_not be true
            match_case.potential_match?.should be true
            match_case.potential_matches.should == [str]

            match_case = calculator.match str
            match_case.exact_match?.should be true
            match_case.potential_match?.should_not be true
            match_case.exact_matches.should == [str]
          end
        end

        it "matching the special DTMF characters such as * and #" do
          %w[* #].each do |special_digit|
            calculator = stringmatchcalculator.new(special_digit, match_payload)
            match_case = calculator.match special_digit
            match_case.potential_match?.should_not be true
            match_case.exact_match?.should be true
            match_case.exact_matches.first.should == special_digit
          end
        end

      end
    end
  end
end
