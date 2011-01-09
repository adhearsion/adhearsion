require File.dirname(__FILE__) + "/test_helper"

describe "Connecting to an XMPP Server" do

  include XMPPTestHelper

  before(:all) { }
  
  # TODO: Actually it something
  
  after do
    XMPP.stop
  end
end


BEGIN {
  module XMPPTestHelper



  end
}