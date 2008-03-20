require File.dirname(__FILE__) + "/test_helper"

context "The Adhearsion module" do
  # This test is of questionable benefit
  test "should have a VERSION constant" do
    assert(Adhearsion.const_defined?(:VERSION), "VERSION constant should be defined")
  end
end