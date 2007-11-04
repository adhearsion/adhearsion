require File.dirname(__FILE__) + "/../test_helper"
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

describe "A PhoneNumber" do
  
  it "should have an ISN pattern-matching method" do
    !! Adhearsion::VoIP::DSL::PhoneNumber.new("0115544332211").isn?.should == false
    !! Adhearsion::VoIP::DSL::PhoneNumber.new("1*548").isn?.should == false
  end
  
  it "should have a US local number pattern-matching method" do
    !! Adhearsion::VoIP::DSL::PhoneNumber.new("18887776665555").local_number?.should == false
    !! Adhearsion::VoIP::DSL::PhoneNumber.new("18887776665555").national_number?.should == false
    
    !! Adhearsion::VoIP::DSL::PhoneNumber.new("8887776665555").local_number?.should == false
    !! Adhearsion::VoIP::DSL::PhoneNumber.new("8887776665555").national_number?.should == true
     
    !! Adhearsion::VoIP::DSL::PhoneNumber.new("4445555").local_number?.should == true
    !! Adhearsion::VoIP::DSL::PhoneNumber.new("4445555").national_number?.should == false
  end
  
  it "should convert from vanity numbers properly" do
    Adhearsion::VoIP::DSL::PhoneNumber.from_vanity("1-800-FUDGEME").should == "18003834363"
  end
end