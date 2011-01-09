require File.dirname(__FILE__) + "/../test_helper"

require 'adhearsion/voip/dsl/numerical_string'
require 'adhearsion/voip/constants'

describe "A NumericalString" do
  it "NumericalString should appear to be behave like a Fixnum in a case statement" do
    assert 123 === numerical_string_for("123")
    assert 987 === numerical_string_for("0987")
  end

  it "NumericalString should appear to behave like a String in a case statement" do
    assert "123"  === numerical_string_for("123")
    assert "0987" === numerical_string_for("0987")
  end

  it "when compared against a Range that contains the numeric equivalent, the NumericalString is seen as a member" do
    assert((100..200) === numerical_string_for("150"))
    assert((100..200) === numerical_string_for("0150"))
    assert !((100..200) === numerical_string_for("1000000"))
  end

  it "comparing against a regular expression works" do
    assert %r|^\d+$| === numerical_string_for("027316287")
  end

  it "checking if a string representation of a number starts with a leading zero" do
    with_leading_zeros    = %w(01 01234 01.23 01.2)
    without_leading_zeros = %w(1 1.2 0 0.0)

    with_leading_zeros.each do |number|
      numerical_string.starts_with_leading_zero?(number).should be true
    end

    without_leading_zeros.each do |number|
      !numerical_string.starts_with_leading_zero?(number).should be true
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
