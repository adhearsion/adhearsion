# encoding: utf-8

require 'spec_helper'

module Adhearsion
  module MenuDSL
    describe CalculatedMatch do
      it "should make accessible the context name" do
        CalculatedMatch.new(:match_payload => :foobar).match_payload.should be :foobar
      end

      it "should make accessible the original pattern" do
        CalculatedMatch.new(:pattern => :something).pattern.should be :something
      end

      it "should make accessible the matched query" do
        CalculatedMatch.new(:query => 123).query.should be 123
      end

      it "#type_of_match should return :exact, :potential, or nil" do
        CalculatedMatch.new(:potential_matches => [1]).type_of_match.should be :potential
        CalculatedMatch.new(:exact_matches => [3,3]).type_of_match.should be :exact
        CalculatedMatch.new(:exact_matches => [8,3], :potential_matches => [0,9]).type_of_match.should be :exact
      end

      it "#exact_match? should return true if the match was exact" do
        CalculatedMatch.new(:exact_matches => [0,3,5]).exact_match?.should be true
      end

      it "#potential_match? should return true if the match was exact" do
        CalculatedMatch.new(:potential_matches => [88,99,77]).potential_match?.should be true
      end

      it "#failed_match? should return false if the match was exact" do
        CalculatedMatch.new(:potential_matches => [88,99,77]).failed_match?.should be false
      end

      it "#exact_matches should return an array of exact matches" do
        CalculatedMatch.new(:exact_matches => [0,3,5]).exact_matches.should be == [0,3,5]
      end

      it "#potential_matches should return an array of potential matches" do
        CalculatedMatch.new(:potential_matches => [88,99,77]).potential_matches.should be == [88,99,77]
      end

      it "::failed_match! should return a match that *really* failed" do
        failure = CalculatedMatch.failed_match! 10..20, 30, :match_payload_does_not_matter
        failure.exact_match?.should_not be true
        failure.potential_match?.should_not be true
        failure.failed_match?.should be true
        failure.type_of_match.should be nil

        failure.match_payload.should be :match_payload_does_not_matter
        failure.pattern.should be == (10..20)
        failure.query.should be == 30
      end
    end
  end
end
