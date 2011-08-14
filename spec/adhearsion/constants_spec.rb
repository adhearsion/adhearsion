require 'spec_helper'

describe "The Adhearsion module" do
  # This it is of questionable benefit
  it "should have a VERSION constant" do
    Adhearsion.const_defined?(:VERSION).should be true
  end
end