require File.dirname(__FILE__) + "/test_helper"

describe "The Adhearsion module" do
  # This it is of questionable benefit
  it "should have a VERSION constant" do
    assert(Adhearsion.const_defined?(:VERSION), "VERSION constant should be defined")
  end
end