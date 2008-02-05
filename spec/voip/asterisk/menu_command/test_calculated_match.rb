require File.join(File.dirname(__FILE__), *%w[.. .. .. test_helper])
require 'adhearsion/voip/asterisk/menu_command/calculated_match'

context 'CalculatedMatch' do
  test "should make accessible the context name" do
    Adhearsion::VoIP::Asterisk::Commands::CalculatedMatch.new(:context_name => :foobar).context_name.should.equal :foobar
  end
  test "should make accessible the original pattern" do
    Adhearsion::VoIP::Asterisk::Commands::CalculatedMatch.new(:pattern => :something).pattern.should.equal :something
  end
  test "should make accessible the matched query" do
    Adhearsion::VoIP::Asterisk::Commands::CalculatedMatch.new(:query => 123).query.should.equal 123
  end
  test '#type_of_match should return :exact, :potential, or nil' do
    Adhearsion::VoIP::Asterisk::Commands::CalculatedMatch.new(:potential_matches => [1]).type_of_match.should.equal :potential
    Adhearsion::VoIP::Asterisk::Commands::CalculatedMatch.new(:exact_matches => [3,3]).type_of_match.should.equal :exact
    Adhearsion::VoIP::Asterisk::Commands::CalculatedMatch.new(:exact_matches => [8,3], :potential_matches => [0,9]).type_of_match.should.equal :exact
    Adhearsion::VoIP::Asterisk::Commands::CalculatedMatch.new.type_of_match.should.equal nil
  end
  test '#exact_match? should return true if the match was exact' do
    Adhearsion::VoIP::Asterisk::Commands::CalculatedMatch.new(:exact_matches => [0,3,5]).should.be.exact_match
  end
  
  test '#potential_match? should return true if the match was exact' do
    Adhearsion::VoIP::Asterisk::Commands::CalculatedMatch.new(:potential_matches => [88,99,77]).should.be.potential_match
  end
  
  test '#exact_matches should return an array of exact matches' do
    Adhearsion::VoIP::Asterisk::Commands::CalculatedMatch.new(:exact_matches => [0,3,5]).exact_matches.should == [0,3,5]
  end
  
  test '#potential_matches should return an array of potential matches' do
    Adhearsion::VoIP::Asterisk::Commands::CalculatedMatch.new(:potential_matches => [88,99,77]).potential_matches.should == [88,99,77]
  end
  
  test '::failed_match! should return a match that *really* failed' do
    failure = Adhearsion::VoIP::Asterisk::Commands::CalculatedMatch.failed_match! 10..20, 30, :context_name_does_not_matter
    failure.should.not.be.exact_match
    failure.should.not.be.potential_match
    failure.type_of_match.should.be nil
    
    failure.context_name.should.equal :context_name_does_not_matter
    failure.pattern.should == (10..20)
    failure.query.should == 30
  end
  
end

context 'CalculatedMatchCollection' do
  
  include CalculatedMatchCollectionTestHelper
  
  attr_reader :collection
  before:each do
    @collection = Adhearsion::VoIP::Asterisk::Commands::CalculatedMatchCollection.new
  end
  
  test 'the <<() method should collect the potential matches into the actual_potential_matches Array' do
    mock_matches_array_1 = [:foo, :bar, :qaz], 
    mock_matches_array_2 = [10,20,30]
    mock_matches_1 = mock_with_potential_matches mock_matches_array_1
    mock_matches_2 = mock_with_potential_matches mock_matches_array_2
    
    collection << mock_matches_1
    collection.actual_potential_matches.should == mock_matches_array_1
    
    collection << mock_matches_2
    collection.actual_potential_matches.should == mock_matches_array_1 + mock_matches_array_2
  end
  
  test 'the <<() method should collect the exact matches into the actual_exact_matches Array' do
    mock_matches_array_1 = [:blam, :blargh], 
    mock_matches_array_2 = [5,4,3,2,1]
    mock_matches_1 = mock_with_exact_matches mock_matches_array_1
    mock_matches_2 = mock_with_exact_matches mock_matches_array_2
    
    collection << mock_matches_1
    collection.actual_exact_matches.should == mock_matches_array_1
    
    collection << mock_matches_2
    collection.actual_exact_matches.should == mock_matches_array_1 + mock_matches_array_2
  end
  
  test "if any exact matches exist, the exact_match?() method should return true" do
    collection << mock_with_exact_matches([1,2,3])
    collection.should.be.exact_match
  end
  
  test "if any potential matches exist, the potential_match?() method should return true" do
    collection << mock_with_potential_matches([1,2,3])
    collection.should.be.potential_match
  end
end

BEGIN {
module CalculatedMatchCollectionTestHelper
  def mock_with_potential_matches(potential_matches)
    Adhearsion::VoIP::Asterisk::Commands::CalculatedMatch.new :potential_matches => potential_matches
  end
  
  def mock_with_exact_matches(exact_matches)
    Adhearsion::VoIP::Asterisk::Commands::CalculatedMatch.new :exact_matches => exact_matches
  end
  
  def mock_with_potential_and_exact_matches(potential_matches, exact_matches)
    Adhearsion::VoIP::Asterisk::Commands::CalculatedMatch.new :potential_matches => potential_matches, 
                        :exact_matches => exact_matches
  end
  
end
}