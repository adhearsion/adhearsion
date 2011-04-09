require 'spec_helper'
require 'adhearsion/voip/menu_state_machine/menu_builder'
require 'adhearsion/voip/menu_state_machine/matchers'

describe "MatchCalculator" do
  it "the build_with_pattern() method should return an appropriate subclass instance based on the pattern's class" do
    Adhearsion::VoIP::MatchCalculator.build_with_pattern(1..2, :main).should be_an_instance_of Adhearsion::VoIP::RangeMatchCalculator
  end

end

describe "The RangeMatchCalculator" do

  it "matching with a Range should handle the case of two potential matches in the range" do
    digits_that_begin_with_eleven = [110..119, 1100..1111].map { |x| Array(x) }.flatten

    calculator = Adhearsion::VoIP::RangeMatchCalculator.new 11..1111, :match_payload_doesnt_matter
    match = calculator.match 11
    match.exact_matches.should == [11]
    match.potential_matches.should == digits_that_begin_with_eleven
  end

  it 'return values of #match should be an instance of CalculatedMatch' do
    calculator = Adhearsion::VoIP::RangeMatchCalculator.new 1..9, :match_payload_doesnt_matter
    calculator.match(0).should be_an_instance_of Adhearsion::VoIP::CalculatedMatch
    calculator.match(1000).should be_an_instance_of Adhearsion::VoIP::CalculatedMatch
  end

end

describe "FixnumMatchCalculator" do
  attr_reader :match_payload
  before(:each) do
    @match_payload = :main
  end

  it "a potential match scenario" do
    calculator = Adhearsion::VoIP::FixnumMatchCalculator.new(444, match_payload)
    match = calculator.match 4
    match.potential_match?.should be true
    match.exact_match?.should_not be true
    match.potential_matches.should == [444]
  end

  it 'a multi-digit exact match scenario' do
    calculator = Adhearsion::VoIP::FixnumMatchCalculator.new(5555, match_payload)
    calculator.match(5555).exact_match?.should be true
  end

  it 'a single-digit exact match scenario' do
    calculator = Adhearsion::VoIP::FixnumMatchCalculator.new(1, match_payload)
    calculator.match(1).exact_match?.should be true
  end

  it 'the context name given to the calculator should be passed on to the CalculatedMatch' do
    match_payload = :icanhascheezburger
    calculator = Adhearsion::VoIP::FixnumMatchCalculator.new(1337, match_payload)
    calculator.match(1337).match_payload.should be match_payload
  end

end

describe "StringMatchCalculator" do

  attr_reader :match_payload
  before(:each) do
    @match_payload = :doesnt_matter
  end

  it "numerical digits mixed with special digits" do

    %w[5*11#3 5*** ###].each do |str|
      calculator = Adhearsion::VoIP::StringMatchCalculator.new(str, match_payload)

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
      calculator = Adhearsion::VoIP::StringMatchCalculator.new(special_digit, match_payload)
      match_case = calculator.match special_digit
      match_case.potential_match?.should_not be true
      match_case.exact_match?.should be true
      match_case.exact_matches.first.should == special_digit
    end
  end

end
