require 'spec_helper'

require 'adhearsion/voip/dsl/numerical_string'
require 'adhearsion/voip/constants'

describe "A NumericalString" do
  # FIXME: This test is fundamentally broken in Ruby 1.9.
  # See https://adhearsion.lighthouseapp.com/projects/5871/tickets/127-ruby-19-and-numericalstring-comparisons-in-case-statements
  # The suggested workaround is to cast the object to a string:
  # case numerical_string_object.to_s
  # when "0987" then ...
  # end
#  it "should appear to be behave like a Fixnum in a case statement" do
#    case numerical_string_for("123")
#      when 123 then true
#      else false
#    end.should be true
#
#    case numerical_string_for("0987")
#      when 987 then true
#      else false
#    end.should be true
#  end

  it "should appear to behave like a String in a case statement" do
    numerical_string_for("123").should === "123"
    numerical_string_for("0987").should === "0987"
  end

  it "when compared against a Range that contains the numeric equivalent, the NumericalString is seen as a member" do
    (100..200).should === numerical_string_for("150")
    (100..200).should === numerical_string_for("0150")
    (100..200).should_not === numerical_string_for("1000000")
  end

  it "comparing against a regular expression works" do
    %r|^\d+$|.should === numerical_string_for("027316287")
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
