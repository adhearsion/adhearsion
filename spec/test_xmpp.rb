require File.dirname(__FILE__) + "/test_helper"

context "Connecting to an XMPP Server" do

  include XMPPTestHelper

  before(:all) { require '' }

  before :each do

  end

  after :each do
    XMPP.stop
  end





  after do
    XMPP.stop
  end
end


BEGIN {
  module XMPPTestHelper



  end
}