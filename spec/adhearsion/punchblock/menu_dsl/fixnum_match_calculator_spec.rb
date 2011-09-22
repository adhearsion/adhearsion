require 'spec_helper'

module Adhearsion
  module Punchblock
    module MenuDSL

      describe "FixnumMatchCalculator" do
        include PunchblockCommandTestHelpers

        attr_reader :match_payload
        before(:each) do
          @match_payload = :main
        end

        let(:fixnumcalculator) { FixnumMatchCalculator }

        it "a potential match scenario" do
          calculator = fixnumcalculator.new(444, match_payload)
          match = calculator.match 4
          match.potential_match?.should be true
          match.exact_match?.should_not be true
          match.potential_matches.should == [444]
        end

        it "a multi-digit exact match scenario" do
          calculator = fixnumcalculator.new(5555, match_payload)
          calculator.match(5555).exact_match?.should be true
        end

        it "a single-digit exact match scenario" do
          calculator = fixnumcalculator.new(1, match_payload)
          calculator.match(1).exact_match?.should be true
        end

        it "the context name given to the calculator should be passed on the CalculatedMatch" do
          match_payload = :icanhascheezburger
          calculator = fixnumcalculator.new(1337, match_payload)
          calculator.match(1337).match_payload.should be match_payload
        end

      end
    end
  end
end
