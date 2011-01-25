=begin
describe "Connecting via AMI" do
  it "should raise an exception if the password was invalid" do
    host, port = "localhost", 5038
    ami = Adhearsion::VoIP::Asterisk::AMI.new "admin", "bad_password", "localhost", :port => port

    ami_server = AmiServer.new
    flexmock(TCPSocket).should_receive(:new).once.with(host, port).and_return(ami_server)
    flexmock(IO).should_receive(:select).at_least.once.with([ami_server], nil, nil, 1.0).and_return(true)

    the_following_code do
      ami.connect!
    end.should raise_error Adhearsion::VoIP::Asterisk::AMI::AuthenticationFailedException
    ami.disconnect!
  end

  it "should discover its own permissions and make them available as connection attributes"

  it "should find the Asterisk version when connecting" do
    host, port = "localhost", 5038
    ami = Adhearsion::VoIP::Asterisk::AMI.new "admin", "password", "localhost", :port => port

    ami_server = AmiServer.new
    flexmock(TCPSocket).should_receive(:new).once.with(host, port).and_return(ami_server)
    flexmock(IO).should_receive(:select).at_least.once.with([ami_server], nil, nil, 1.0).and_return(true)

    ami.connect!
    ami.version.should == "1.0"
    ami.disconnect!
  end
end

describe "The AMI command interface" do

  before do
    host, port = "localhost", 5038
    @ami = Adhearsion::VoIP::Asterisk::AMI.new "admin", "password", host, :port => port, :events => false

    ami_server = AmiServer.new
    flexmock(TCPSocket).should_receive(:new).once.with(host, port).and_return(ami_server)
    flexmock(IO).should_receive(:select).at_least.once.with([ami_server], nil, nil, 1.0).and_return(true)

    @ami.connect!
  end

  after do
    @ami.disconnect!
  end

  it "should respond to an immediate command" do
    resp = @ami.queues
    resp[0][:raw].should be_a_kind_of String
  end

  it "should respond to a follows command" do
    resp = @ami.command :Command => "show channels"
    resp[0][:raw].should be_a_kind_of String
  end

  it "should respond to a DBGet for a non-existent key with an exception" do
    the_following_code do
      resp = @ami.dbget :Family => "none", :Key => "somekey"
    end.should raise_error Adhearsion::VoIP::Asterisk::AMI::ActionError
  end

  it "should respond to a DBGet for a key with an event" do
    resp = @ami.dbput :Family => "none", :Key => "somekey", :Val => 5
    resp = @ami.dbget :Family => "none", :Key => "somekey"
    resp[0]['Val'].should == "5"
  end

  it "should respond to a command that generates follows event(s)" do
    resp = @ami.queuestatus
    resp[0]['Queue'].should == "default"
  end

  it "should show usage for an improper follows command" do
    resp = @ami.command :Command => "meetme list"
    resp[0][:raw].should be_a_kind_of String
  end

  it "should respond to a synchronous originate"
  it "should respond to an asynchronous originate"

  it "should define events() as a private method to prevent turning events on or off" do
    @ami.private_methods.include?("events").should be true
  end

  it "should raise an exception when Asterisk doesn't recognize a command" do
    the_following_code {
      @ami.this_command_does_not_exist_kthx
    }.should raise_error Adhearsion::VoIP::Asterisk::AMI::ActionError

  end

end

describe 'AMI#originate' do
  include AmiCommandTestHelper
  it "should pass the arguments to execute_ami_command! with the options given" do
    ami     = new_ami_instance
    options = { :channel => "ohai_lolz", :application => "Echo" }
    flexmock(ami).should_receive(:execute_ami_command!).with(:originate, options).once
    ami.originate options
  end

  it "should rename the :caller_id Hash key to :callerid" do
    ami, caller_id = new_ami_instance, "Jay"
    options = { :channel => "ohai_lolz", :application => "Echo"}
    flexmock(ami).should_receive(:execute_ami_command!).with(:originate, options.merge(:callerid => caller_id)).once
    ami.originate options.merge(:caller_id => caller_id)
  end

end

describe 'AMI#call_and_exec' do
  include AmiCommandTestHelper
  it "should execute originate properly with the minimum arguments" do
    number, app = "12224446666", "Echo"

    ami = flexmock new_ami_instance
    ami.should_receive(:originate).once.with(:channel => number, :application => app).and_return true
    ami.call_and_exec number, app
  end

end

describe 'AMI#introduce' do

  include AmiCommandTestHelper

  it "should execute origiante properly (when :caller_id and :options aren't specified)" do
    caller, callee, caller_id = "SIP/12224446666@trunk", "SIP/12224447777@trunk", "Jay Phillips"

    correct_args = {:application => "Dial", :channel => caller, :data => callee, :caller_id => "Jay"}
    ami = flexmock new_ami_instance
    ami.should_receive(:originate).once.with(correct_args).and_return(true)
    ami.introduce caller, callee, :caller_id => "Jay"
  end

end

describe "The manager proxy" do
  before do
    host, port = "localhost", 5038
    @ami = Adhearsion::VoIP::Asterisk::AMI.new "admin", "password", "localhost", :port => port, :events => false

    ami_server = AmiServer.new
    flexmock(TCPSocket).should_receive(:new).once.with(host, port).and_return(ami_server)
    flexmock(IO).should_receive(:select).at_least.once.with([ami_server], nil, nil, 1.0).and_return(true)

    @ami.connect!
    @door = DRb.start_service "druby://127.0.0.1:9050", Adhearsion::DrbDoor.instance
  end

  it "should accept a command" do
    client = DRbObject.new nil, DRb.uri
    client.proxy.ping
  end

  after do
    DRb.stop_service
    @ami.disconnect!
  end
end

describe "The command-sending interface" do
  it "should raise an exception if permission was denied"
  it "should allow variables to be specified as a Hash"
end

describe "Sent arbitrary AMI commands" do

  it "should allow a convenient way of parsing by event name"
  it "should return Hash arguments"

  it "should recognize its subclasses"
  it "should send events to all of its subclasses"
  it "should catch action names with method_missing() and format them properly"

  it "should raise an exception if permission was denied"
end

describe "AMI Packets" do
  it "A Packet should not be an error" do
    Adhearsion::VoIP::Asterisk::AMI::Packet.new.error?.should.be false
  end
  it "An ErrorPacket should be an error" do
    Adhearsion::VoIP::Asterisk::AMI::ErrorPacket.new.error?.should.be true
  end
end

BEGIN {
module AmiCommandTestHelper
  def new_ami_instance
    # TODO. mock everything out here
    Adhearsion::VoIP::Asterisk::AMI.new("user","pass").tap do |ami|
      flexmock(ami).should_receive(:connect!).and_return(true)
    end
  end

end
}
=end