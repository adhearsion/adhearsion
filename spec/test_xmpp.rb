require File.dirname(__FILE__) + "/test_helper"

context "Connecting to an XMPP Server" do

  include XMPPTestHelper

  before(:all) { }
  
  # TODO: Actually test something
  
  after do
    XMPP.stop
  end
end


BEGIN {
  module XMPPTestHelper



  end
}