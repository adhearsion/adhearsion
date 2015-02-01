# encoding: utf-8

require 'spec_helper'

module Adhearsion
  class CallController
    module MenuDSL
      describe ArrayMatchCalculator do

        let(:match_payload) { :doesnt_matter }

        it "matching arrays with fixnums" do
          calculator = ArrayMatchCalculator.new [11,5,14,115], match_payload
          match_case = calculator.match '11'
          expect(match_case).to be_exact_match
          expect(match_case).to be_potential_match
          expect(match_case.exact_matches).to eq([11])
          expect(match_case.potential_matches).to eq([115])
        end

        it "matching arrays with strings with digits and special digits" do
          calculator = ArrayMatchCalculator.new %w[*57 4 *54 115 ###], match_payload
          match_case = calculator.match '*5'
          expect(match_case).not_to be_exact_match
          expect(match_case).to be_potential_match
          expect(match_case.potential_matches).to eq(%w[*57 *54])

          match_case = calculator.match '*57'
          expect(match_case).to be_exact_match
          expect(match_case).not_to be_potential_match
          expect(match_case.exact_matches).to eq(%w[*57])
        end

        it "matching an array with a combination of Fixnums and Strings" do
          calculator = ArrayMatchCalculator.new ['11',5,'14',115], match_payload
          match_case = calculator.match '11'
          expect(match_case).to be_exact_match
          expect(match_case).to be_potential_match
          expect(match_case.exact_matches).to eq(['11'])
          expect(match_case.potential_matches).to eq([115])
        end

        it "matching empty array should never match" do
          calculator = ArrayMatchCalculator.new [], match_payload
          match_case = calculator.match '98'
          expect(match_case).not_to be_exact_match
          expect(match_case).not_to be_potential_match
          expect(match_case.exact_matches).to eq([])
          expect(match_case.potential_matches).to eq([])

          match_case = calculator.match '*2'
          expect(match_case).not_to be_exact_match
          expect(match_case).not_to be_potential_match
          expect(match_case.exact_matches).to eq([])
          expect(match_case.potential_matches).to eq([])
        end

        it "matching array with nil should skip nil field" do
          pattern = [1,2,nil,5,10]
          calculator = ArrayMatchCalculator.new pattern, match_payload
          match_case = calculator.match '1'
          expect(match_case).to be_exact_match
          expect(match_case).to be_potential_match
          expect(match_case.exact_matches).to eq([1])
          expect(match_case.potential_matches).to eq([10])

          match_case = calculator.match '99'
          expect(match_case).not_to be_exact_match
          expect(match_case).not_to be_potential_match

          expect(pattern).to eq([1,2,nil,5,10])
        end
      end
    end
  end
end
