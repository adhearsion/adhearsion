# encoding: utf-8

require 'spec_helper'

module Adhearsion
  class CallController
    module MenuDSL
      describe CalculatedMatch do
        it "should make accessible the context name" do
          expect(CalculatedMatch.new(:match_payload => :foobar).match_payload).to be :foobar
        end

        it "should make accessible the original pattern" do
          expect(CalculatedMatch.new(:pattern => :something).pattern).to be :something
        end

        it "should make accessible the matched query" do
          expect(CalculatedMatch.new(:query => 123).query).to be 123
        end

        it "#type_of_match should return :exact, :potential, or nil" do
          expect(CalculatedMatch.new(:potential_matches => [1]).type_of_match).to be :potential
          expect(CalculatedMatch.new(:exact_matches => [3,3]).type_of_match).to be :exact
          expect(CalculatedMatch.new(:exact_matches => [8,3], :potential_matches => [0,9]).type_of_match).to be :exact
        end

        it "#exact_match? should return true if the match was exact" do
          expect(CalculatedMatch.new(:exact_matches => [0,3,5]).exact_match?).to be true
        end

        it "#potential_match? should return true if the match was exact" do
          expect(CalculatedMatch.new(:potential_matches => [88,99,77]).potential_match?).to be true
        end

        it "#failed_match? should return false if the match was exact" do
          expect(CalculatedMatch.new(:potential_matches => [88,99,77]).failed_match?).to be false
        end

        it "#exact_matches should return an array of exact matches" do
          expect(CalculatedMatch.new(:exact_matches => [0,3,5]).exact_matches).to eq([0,3,5])
        end

        it "#potential_matches should return an array of potential matches" do
          expect(CalculatedMatch.new(:potential_matches => [88,99,77]).potential_matches).to eq([88,99,77])
        end

        it "::failed_match! should return a match that *really* failed" do
          failure = CalculatedMatch.failed_match! 10..20, 30, :match_payload_does_not_matter
          expect(failure.exact_match?).not_to be true
          expect(failure.potential_match?).not_to be true
          expect(failure.failed_match?).to be true
          expect(failure.type_of_match).to be nil

          expect(failure.match_payload).to be :match_payload_does_not_matter
          expect(failure.pattern).to eq(10..20)
          expect(failure.query).to eq(30)
        end
      end
    end
  end
end
