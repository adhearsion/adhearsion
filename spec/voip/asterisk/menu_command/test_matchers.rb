require File.join(File.dirname(__FILE__), *%w[.. .. .. test_helper])
require 'adhearsion/voip/menu_state_machine/menu_builder'
require 'adhearsion/voip/menu_state_machine/matchers'

context "MatchCalculator" do
  test "the build_with_pattern() method should return an appropriate subclass instance based on the pattern's class" do
    Adhearsion::VoIP::MatchCalculator.build_with_pattern(1..2, :main).should.be.instance_of Adhearsion::VoIP::RangeMatchCalculator
  end

end

context "The RangeMatchCalculator" do

  test "matching with a Range should handle the case of two potential matches in the range" do
    digits_that_begin_with_eleven = [110..119, 1100..1111].map { |x| Array(x) }.flatten

    calculator = Adhearsion::VoIP::RangeMatchCalculator.new 11..1111, :match_payload_doesnt_matter
    match = calculator.match 11
    match.exact_matches.should == [11]
    match.potential_matches.should == digits_that_begin_with_eleven
  end

  test 'return values of #match should be an instance of CalculatedMatch' do
    calculator = Adhearsion::VoIP::RangeMatchCalculator.new 1..9, :match_payload_doesnt_matter
    calculator.match(0).should.be.instance_of Adhearsion::VoIP::CalculatedMatch
    calculator.match(1000).should.be.instance_of Adhearsion::VoIP::CalculatedMatch
  end

end

context "FixnumMatchCalculator" do
  attr_reader :match_payload
  before:each do
    @match_payload = :main
  end

  test "a potential match scenario" do
    calculator = Adhearsion::VoIP::FixnumMatchCalculator.new(444, match_payload)
    match = calculator.match 4
    match.should.be.potential_match
    match.should.not.be.exact_match
    match.potential_matches.should == [444]
  end

  test 'a multi-digit exact match scenario' do
    calculator = Adhearsion::VoIP::FixnumMatchCalculator.new(5555, match_payload)
    calculator.match(5555).should.be.exact_match
  end

  test 'a single-digit exact match scenario' do
    calculator = Adhearsion::VoIP::FixnumMatchCalculator.new(1, match_payload)
    calculator.match(1).should.be.exact_match
  end

  test 'the context name given to the calculator should be passed on to the CalculatedMatch' do
    match_payload = :icanhascheezburger
    calculator = Adhearsion::VoIP::FixnumMatchCalculator.new(1337, match_payload)
    calculator.match(1337).match_payload.should.equal match_payload
  end

end

context "StringMatchCalculator" do

  attr_reader :match_payload
  before:each do
    @match_payload = :doesnt_matter
  end

  test "numerical digits mixed with special digits" do

    %w[5*11#3 5*** ###].each do |str|
      calculator = Adhearsion::VoIP::StringMatchCalculator.new(str, match_payload)

      match_case = calculator.match str[0,2]

      match_case.should.not.be.exact_match
      match_case.should.be.potential_match
      match_case.potential_matches.should == [str]

      match_case = calculator.match str
      match_case.should.be.exact_match
      match_case.should.not.be.potential_match
      match_case.exact_matches.should == [str]
    end
  end

  test "matching the special DTMF characters such as * and #" do
    %w[* #].each do |special_digit|
      calculator = Adhearsion::VoIP::StringMatchCalculator.new(special_digit, match_payload)
      match_case = calculator.match special_digit
      match_case.should.not.be.potential_match
      match_case.should.be.exact_match
      match_case.exact_matches.first.should == special_digit
    end
  end

end