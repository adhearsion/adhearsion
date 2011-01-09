require File.dirname(__FILE__) + "/../test_helper"

require 'adhearsion/voip/dsl/numerical_string'
require 'adhearsion/voip/constants'

describe "A NumericalString" do
  it "NumericalString should appear to be behave like a Fixnum in a case statement" do
    (123 === numerical_string_for("123")).should be true
    (987 === numerical_string_for("0987")).should be true
  end

  it "NumericalString should appear to behave like a String in a case statement" do
    ("123"  === numerical_string_for("123")).should be true
    ("0987" === numerical_string_for("0987")).should be true
  end

  it "when compared against a Range that contains the numeric equivalent, the NumericalString is seen as a member" do
    ((100..200) === numerical_string_for("150")).should be true
    ((100..200) === numerical_string_for("0150")).should be true
    ((100..200) === numerical_string_for("1000000")).should be false
  end

  it "comparing against a regular expression works" do
    (%r|^\d+$| === numerical_string_for("027316287")).should be true
  end

  it "checking if a string representation of a number starts with a leading zero" do
    with_leading_zeros    = %w(01 01234 01.23 01.2)
    without_leading_zeros = %w(1 1.2 0 0.0)

    with_leading_zeros.each do |number|
      numerical_string.starts_with_leading_zero?(number).should_not be false
    end

    without_leading_zeros.each do |number|
      numerical_string.starts_with_leading_zero?(number).should_not be true
    end
  end

  private
    def numerical_string
      Adhearsion::VoIP::DSL::NumericalString
    end

    def numerical_string_for(string)
      numerical_string.new(string)
    end
end
