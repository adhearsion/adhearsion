# encoding: utf-8

require 'spec_helper'

module Adhearsion
  class CallController
    module MenuDSL
      describe FixnumMatchCalculator do
        let(:match_payload) { :main }

        it "a potential match scenario" do
          calculator = FixnumMatchCalculator.new(444, match_payload)
          match = calculator.match '4'
          expect(match).to be_potential_match
          expect(match).not_to be_exact_match
          expect(match.potential_matches).to eq([444])
        end

        it "a multi-digit exact match scenario" do
          calculator = FixnumMatchCalculator.new(5555, match_payload)
          match = calculator.match '5555'
          expect(match).to be_exact_match
        end

        it "a single-digit exact match scenario" do
          calculator = FixnumMatchCalculator.new(1, match_payload)
          match = calculator.match '1'
          expect(match).to be_exact_match
        end

        it "the context name given to the calculator should be passed on the CalculatedMatch" do
          match_payload = :icanhascheezburger
          calculator = FixnumMatchCalculator.new(1337, match_payload)
          expect(calculator.match('1337').match_payload).to be match_payload
        end
      end
    end
  end
end
