require 'spec_helper'
require 'adhearsion/voip/constants'
require 'adhearsion/voip/dsl/numerical_string'


# Use cases...
# case extension
#   when US_NUMBER
#   when (100..200)
#   when _('12Z')
#   when 123
#   when "123"
# end

def should_be_nil_or_false(arg)
  [nil, false].include?(arg).should == true
end

def should_not_be_nil_or_false(arg)
  [nil, false].include?(arg).should == false
end

describe "A PhoneNumber" do

  it "should have an ISN pattern-matching method" do
    should_be_nil_or_false Adhearsion::VoIP::DSL::PhoneNumber.new("0115544332211").isn?
    should_not_be_nil_or_false Adhearsion::VoIP::DSL::PhoneNumber.new("1*548").isn?
  end

  it "should have a US local number pattern-matching method" do
    should_be_nil_or_false Adhearsion::VoIP::DSL::PhoneNumber.new("18887776665555").us_local_number?
    should_be_nil_or_false Adhearsion::VoIP::DSL::PhoneNumber.new("18887776665555").us_national_number?

    should_be_nil_or_false Adhearsion::VoIP::DSL::PhoneNumber.new("8887776665555").us_local_number?
    should_be_nil_or_false Adhearsion::VoIP::DSL::PhoneNumber.new("8887776665555").us_national_number?

    should_not_be_nil_or_false Adhearsion::VoIP::DSL::PhoneNumber.new("4445555").us_local_number?
    should_be_nil_or_false Adhearsion::VoIP::DSL::PhoneNumber.new("4445555").us_national_number?
  end

  it "should convert from vanity numbers properly" do
    Adhearsion::VoIP::DSL::PhoneNumber.from_vanity("1-800-FUDGEME").should == "18003834363"
  end

end