require File.dirname(__FILE__) + "/../../test_helper"
require File.dirname(__FILE__) + "/mock_ami_server"

require 'adhearsion'
require 'adhearsion/voip/asterisk/ami'

context "Connecting via AMI" do
  test "should raise an exception if the password was invalid" do
    host, port = "localhost", 5038
    ami = Adhearsion::VoIP::Asterisk::AMI.new "admin", "bad_password", "localhost", :port => port
  
    flexmock(TCPSocket).should_receive(:new).once.with(host, port).and_return AmiServer.new
    the_following_code do
      ami.connect!
    end.should.raise Adhearsion::VoIP::Asterisk::AMI::AuthenticationFailedException
    ami.disconnect!
  end
  
  test "should discover its own permissions and make them available as connection attributes"
  test "should start a new thread if events are enabled" do
    host, port = "localhost", 5038
    ami = Adhearsion::VoIP::Asterisk::AMI.new "admin", "password", "localhost", :port => port, :events => true
  
    flexmock(TCPSocket).should_receive(:new).once.with(host, port).and_return(AmiServer.new)
    ami.connect!
    ami.instance_eval { meta_eval { attr_accessor :event_thread } }
    ami.event_thread.should.be.a.kind_of Thread
    ami.disconnect!
  end
  
  test "should find the Asterisk version when connecting" do
    host, port = "localhost", 5038
    ami = Adhearsion::VoIP::Asterisk::AMI.new "admin", "password", "localhost", :port => port
  
    flexmock(TCPSocket).should_receive(:new).once.with(host, port).and_return AmiServer.new
    ami.connect!
    ami.version.should == "1.0"
    ami.disconnect!
  end
end

context "The AMI command interface" do
  before do
    host, port = "localhost", 5038
    @ami = Adhearsion::VoIP::Asterisk::AMI.new "admin", "password", "localhost", :port => port, :events => false
    flexmock(TCPSocket).should_receive(:new).once.with(host, port).and_return(AmiServer.new)
    @ami.connect!
  end
  
  after do
    @ami.disconnect!
  end
  
  test "should respond to an immediate command" do
    resp = @ami.queues
    resp[0][:raw].should.be.a.kind_of String
  end

  test "should respond to a follows command" do
    resp = @ami.command :Command => "show channels"
    resp[0][:raw].should.be.a.kind_of String
  end

  test "should respond to a DBGet for a non-existent key with an exception" do
    the_following_code do
      resp = @ami.dbget :Family => "none", :Key => "somekey"
    end.should.raise Adhearsion::VoIP::Asterisk::AMI::ActionError
  end
  
  test "should respond to a DBGet for a key with an event" do
    resp = @ami.dbput :Family => "none", :Key => "somekey", :Val => 5
    resp = @ami.dbget :Family => "none", :Key => "somekey"
    resp[0]['Val'].should == "5"
  end
  
  test "should respond to a command that generates follows event(s)" do
    resp = @ami.queuestatus
    resp[0]['Queue'].should == "default"
  end
  
  test "should respond to a synchronous originate"
  test "should responde to an asynchronous originate"

  test "should not respond to an 'events on' command" do
    resp = @ami.events :EventMask => "On"
    resp.should == nil
  end

  test "should respond to an 'events off' command" do
    resp = @ami.events :EventMask => "Off"
    resp[0].should.be.a.kind_of Hash
  end
end

context "The command-sending interface" do
  test "should raise an exception if permission was denied"
  test "should allow variables to be specified as a Hash"
end

context "Sent arbitrary AMI commands" do
  
  test "should allow a convenient way of parsing by event name"
  test "should return Hash arguments"
  
  test "should recognize its subclasses"
  test "should send events to all of its subclasses"
  test "should catch action names with method_missing() and format them properly"

  test "should raise an exception if permission was denied"
end

context "The event parser" do
  test "should parse the the YAML-like format "
  test "should allow a Hash to specify multiple matches"
  
end
