# encoding: utf-8

require 'spec_helper'

module Adhearsion
  module MenuDSL
    describe FixnumMatchCalculator do
      let(:match_payload) { :main }

      it "a potential match scenario" do
        calculator = FixnumMatchCalculator.new(444, match_payload)
        match = calculator.match 4
        match.potential_match?.should be true
        match.exact_match?.should_not be true
        match.potential_matches.should be == [444]
      end

      it "a multi-digit exact match scenario" do
        calculator = FixnumMatchCalculator.new(5555, match_payload)
        calculator.match(5555).exact_match?.should be true
      end

      it "a single-digit exact match scenario" do
        calculator = FixnumMatchCalculator.new(1, match_payload)
        calculator.match(1).exact_match?.should be true
      end

      it "the context name given to the calculator should be passed on the CalculatedMatch" do
        match_payload = :icanhascheezburger
        calculator = FixnumMatchCalculator.new(1337, match_payload)
        calculator.match(1337).match_payload.should be match_payload
      end
    end
  end
end
