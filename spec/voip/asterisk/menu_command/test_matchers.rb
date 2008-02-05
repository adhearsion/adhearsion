require File.join(File.dirname(__FILE__), *%w[.. .. .. test_helper])
require 'adhearsion/voip/asterisk/menu_command/menu_builder'
require 'adhearsion/voip/asterisk/menu_command/matchers'

context "MatchCalculator" do
  test "the build_with_pattern() method should return an appropriate subclass instance based on the pattern's class" do
    Adhearsion::VoIP::Asterisk::Commands::MatchCalculator.build_with_pattern(1..2, :main).should.be.instance_of Adhearsion::VoIP::Asterisk::Commands::RangeMatchCalculator
  end
  
  test "build_with_pattern() should properly instantiate a SymbolMatchCalculator (which requires a block)" do
    calculator = Adhearsion::VoIP::Asterisk::Commands::MatchCalculator.build_with_pattern(:custom, :context_name) { throw :inside_block }
    calculator.should.be.instance_of Adhearsion::VoIP::Asterisk::Commands::SymbolMatchCalculator
    calculator.block.should.throw :inside_block
  end
end

context "The RangeMatchCalculator" do
  
  test "matching with a Range should handle the case of two potential matches in the range" do
    digits_that_begin_with_eleven = [110..119, 1100..1111].map { |x| Array(x) }.flatten
    
    calculator = Adhearsion::VoIP::Asterisk::Commands::RangeMatchCalculator.new 11..1111, :context_name_doesnt_matter
    match = calculator.match 11
    match.exact_matches.should == [11]
    match.potential_matches.should == digits_that_begin_with_eleven
  end
  
  test 'return values of #match should be an instance of CalculatedMatch' do
    calculator = Adhearsion::VoIP::Asterisk::Commands::RangeMatchCalculator.new 1..9, :context_name_doesnt_matter
    calculator.match(0).should.be.instance_of Adhearsion::VoIP::Asterisk::Commands::CalculatedMatch
    calculator.match(1000).should.be.instance_of Adhearsion::VoIP::Asterisk::Commands::CalculatedMatch
  end
  
end

context "FixnumMatchCalculator" do
  attr_reader :context_name
  before:each do
    @context_name = :main
  end

  test "a potential match scenario" do
    calculator = Adhearsion::VoIP::Asterisk::Commands::FixnumMatchCalculator.new(444, context_name)
    match = calculator.match 4
    match.should.be.potential_match
    match.should.not.be.exact_match
    match.potential_matches.should == [444]
  end
  
  test 'a multi-digit exact match scenario' do
    calculator = Adhearsion::VoIP::Asterisk::Commands::FixnumMatchCalculator.new(5555, context_name)
    calculator.match(5555).should.be.exact_match
  end
  
  test 'a single-digit exact match scenario' do
    calculator = Adhearsion::VoIP::Asterisk::Commands::FixnumMatchCalculator.new(1, context_name)
    calculator.match(1).should.be.exact_match
  end
  
  test 'the context name given to the calculator should be passed on to the CalculatedMatch' do
    context_name = :icanhascheezburger
    calculator = Adhearsion::VoIP::Asterisk::Commands::FixnumMatchCalculator.new(1337, context_name)
    calculator.match(1337).context_name.should.equal context_name
  end
  
end

context "StringMatchCalculator" do
  
  attr_reader :context_name
  before:each do
    @context_name = :doesnt_matter
  end
  
  test "numerical digits mixed with special digits" do
    
    %w[5*11#3 5*** ###].each do |str|
      calculator = Adhearsion::VoIP::Asterisk::Commands::StringMatchCalculator.new(str, context_name)
      
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
      calculator = Adhearsion::VoIP::Asterisk::Commands::StringMatchCalculator.new(special_digit, context_name)
      match_case = calculator.match special_digit
      match_case.should.not.be.potential_match
      match_case.should.be.exact_match
      match_case.exact_matches.first.should == special_digit
    end
  end
  
end

context "SymbolMatchCalculator" do
  
  attr_reader :context_name
  before:each do
    @context_name = :blah_blah_blah?
  end
  
  test "should remove the question mark from context_name if one is supplied" do
    context_name_with_question_mark    = :icanhascheezburger?
    context_name_without_question_mark = :icanhascheezburger
    
    calculator = Adhearsion::VoIP::Asterisk::Commands::SymbolMatchCalculator.new(:custom, context_name_with_question_mark, &lambda{})
    calculator.context_name.should.equal context_name_without_question_mark
    
    calculator = Adhearsion::VoIP::Asterisk::Commands::SymbolMatchCalculator.new(:custom, context_name_without_question_mark, &lambda{})
    calculator.context_name.should.equal context_name_without_question_mark
  end
  
  test "should raise a LocalJumpError if no block is given" do
    lambda {
      Adhearsion::VoIP::Asterisk::Commands::SymbolMatchCalculator.new(:custom, context_name)
    }.should.raise LocalJumpError
  end
  
  test "should report an exact match for two strings that obviously match" do
    calculator = Adhearsion::VoIP::Asterisk::Commands::SymbolMatchCalculator.new(:custom, context_name) { |query| ["foobar"] }
    calculator.match("foobar").should.be.exact_match
  end

  test "should report an exact match when the block returns a String version of the Numeric query" do
    calculator = Adhearsion::VoIP::Asterisk::Commands::SymbolMatchCalculator.new(:custom, context_name) { |query| ["556"] }
    calculator.match(556).should.be.exact_match
    
    calculator = Adhearsion::VoIP::Asterisk::Commands::SymbolMatchCalculator.new(:custom, context_name) { |query| [313] }
    calculator.match("313").should.be.exact_match
    
  end
  
  test 'should raise an exception if the pattern given is NOT :custom' do
    lambda {
      Adhearsion::VoIP::Asterisk::Commands::SymbolMatchCalculator.new(:this_is_not_custom, context_name) {}
    }.should.raise ArgumentError
  end
end
