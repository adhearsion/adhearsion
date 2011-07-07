require 'spec_helper'
require 'adhearsion/voip/menu_state_machine/calculated_match'

module CalculatedMatchCollectionTestHelper
  def mock_with_potential_matches(potential_matches)
    Adhearsion::VoIP::CalculatedMatch.new :potential_matches => potential_matches
  end

  def mock_with_exact_matches(exact_matches)
    Adhearsion::VoIP::CalculatedMatch.new :exact_matches => exact_matches
  end

  def mock_with_potential_and_exact_matches(potential_matches, exact_matches)
    Adhearsion::VoIP::CalculatedMatch.new :potential_matches => potential_matches,
                        :exact_matches => exact_matches
  end

end

describe 'CalculatedMatch' do
  it "should make accessible the context name" do
    Adhearsion::VoIP::CalculatedMatch.new(:match_payload => :foobar).match_payload.should be :foobar
  end
  it "should make accessible the original pattern" do
    Adhearsion::VoIP::CalculatedMatch.new(:pattern => :something).pattern.should be :something
  end
  it "should make accessible the matched query" do
    Adhearsion::VoIP::CalculatedMatch.new(:query => 123).query.should be 123
  end
  it '#type_of_match should return :exact, :potential, or nil' do
    Adhearsion::VoIP::CalculatedMatch.new(:potential_matches => [1]).type_of_match.should be :potential
    Adhearsion::VoIP::CalculatedMatch.new(:exact_matches => [3,3]).type_of_match.should be :exact
    Adhearsion::VoIP::CalculatedMatch.new(:exact_matches => [8,3], :potential_matches => [0,9]).type_of_match.should be :exact
    Adhearsion::VoIP::CalculatedMatch.new.type_of_match.should be nil
  end
  it '#exact_match? should return true if the match was exact' do
    Adhearsion::VoIP::CalculatedMatch.new(:exact_matches => [0,3,5]).exact_match?.should be true
  end

  it '#potential_match? should return true if the match was exact' do
    Adhearsion::VoIP::CalculatedMatch.new(:potential_matches => [88,99,77]).potential_match?.should be true
  end

  it '#exact_matches should return an array of exact matches' do
    Adhearsion::VoIP::CalculatedMatch.new(:exact_matches => [0,3,5]).exact_matches.should == [0,3,5]
  end

  it '#potential_matches should return an array of potential matches' do
    Adhearsion::VoIP::CalculatedMatch.new(:potential_matches => [88,99,77]).potential_matches.should == [88,99,77]
  end

  it '::failed_match! should return a match that *really* failed' do
    failure = Adhearsion::VoIP::CalculatedMatch.failed_match! 10..20, 30, :match_payload_does_not_matter
    failure.exact_match?.should_not be true
    failure.potential_match?.should_not be true
    failure.type_of_match.should be nil

    failure.match_payload.should be :match_payload_does_not_matter
    failure.pattern.should == (10..20)
    failure.query.should == 30
  end

end

describe 'CalculatedMatchCollection' do

  include CalculatedMatchCollectionTestHelper

  attr_reader :collection
  before(:each) do
    @collection = Adhearsion::VoIP::CalculatedMatchCollection.new
  end

  it 'the <<() method should collect the potential matches into the actual_potential_matches Array' do
    mock_matches_array_1 = [:foo, :bar, :qaz],
    mock_matches_array_2 = [10,20,30]
    mock_matches_1 = mock_with_potential_matches mock_matches_array_1
    mock_matches_2 = mock_with_potential_matches mock_matches_array_2

    collection << mock_matches_1
    collection.actual_potential_matches.should == mock_matches_array_1

    collection << mock_matches_2
    collection.actual_potential_matches.should == mock_matches_array_1 + mock_matches_array_2
  end

  it 'the <<() method should collect the exact matches into the actual_exact_matches Array' do
    mock_matches_array_1 = [:blam, :blargh],
    mock_matches_array_2 = [5,4,3,2,1]
    mock_matches_1 = mock_with_exact_matches mock_matches_array_1
    mock_matches_2 = mock_with_exact_matches mock_matches_array_2

    collection << mock_matches_1
    collection.actual_exact_matches.should == mock_matches_array_1

    collection << mock_matches_2
    collection.actual_exact_matches.should == mock_matches_array_1 + mock_matches_array_2
  end

  it "if any exact matches exist, the exact_match?() method should return true" do
    collection << mock_with_exact_matches([1,2,3])
    collection.exact_match?.should be true
  end

  it "if any potential matches exist, the potential_match?() method should return true" do
    collection << mock_with_potential_matches([1,2,3])
    collection.potential_match?.should be true
  end
end
