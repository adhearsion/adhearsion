require 'spec_helper'

describe "VoIP platform operations" do
  it "can map a platform name to a module which holds its platform-specific operations" do
    Adhearsion::Commands.for(:asterisk).should == Adhearsion::Asterisk::Commands
  end
end
