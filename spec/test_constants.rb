require 'test_helper'
describe "Adhearsion" do
  # This test is of questionable benefit
  test "should have a VERSION constant" do
    assert(Adhearsion.const_defined?(:VERSION), "VERSION constant should be defined")
  end
end