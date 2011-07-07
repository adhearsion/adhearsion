require 'spec_helper'
require 'adhearsion'
require 'adhearsion/voip/asterisk/manager_interface'

module ManagerInterfaceTestHelper

  def mocked_queue
    # This mock queue receives a ManagerInterfaceAction with <<(). Within the semantics of the OO design, this should be
    # immediately picked up by the writer queue. The writer queue calls to_s on each object and passes that string to the
    # event socket, blocking if it's an event with causal events.
    write_queue_mock = TestableQueueMock.new
    flexmock(Queue).should_receive(:new).once.and_return write_queue_mock
    write_queue_mock
  end

  def ami_packets
    OpenStruct.new.tap do |struct|
      struct.fresh_socket_connection = "Asterisk Call Manager/1.0\r\nResponse: Success\r\n"+
          "Message: Authentication accepted\r\n\r\n"

      struct.reload_event = %{Event: ChannelReload\r\nPrivilege: system,all\r\nChannel: SIP\r\n} +
          %{ReloadReason: RELOAD (Channel module reload)\r\nRegistry_Count: 1\r\nPeer_Count: 2\r\nUser_Count: 1\r\n\r\n}

      struct.authentication_failed = %{Asterisk Call Manager/1.0\r\nResponse: Error\r\nMessage: Authentication failed\r\nActionID: %s\r\n\r\n}

      struct.unknown_command_error = "Response: Error\r\nActionID: 2123123\r\nMessage: Invalid/unknown command\r\n\r\n"

      struct.pong = "Response: Pong\r\nActionID: %s\r\n\r\n"
    end
  end

  def new_manager_with_events
    @Manager::ManagerInterface.new :host => @host, :port => @port, :events => true, :auto_reconnect => false
  end

  def new_manager_without_events
    @Manager::ManagerInterface.new :host => @host, :port => @port, :events => false, :auto_reconnect => false
  end

  def new_blank_ami_response
    @Manager::ManagerInterfaceResponse.new
  end

  def mock_for_next_created_socket
    flexmock("TCPSocket").tap do |mock|
      flexmock(TCPSocket).should_receive(:new).once.and_return mock
    end
  end

end


##
# Had to implement this class to make the Thread-based testing simpler.
#
class TestableQueueMock

  attr_accessor :manager
  def initialize
    @shifted    = []
    @unshifted  = []
  end

  def actions
    @shifted + @unshifted
  end

  def <<(action)
    @unshifted << action
    @on_push.call(action) if @on_push
  end

  def on_push(&block)
    @on_push = block
    self
  end

  def shift
    return :STOP! if actions.empty?
    next_action = @unshifted.shift
    @shifted << next_action
    next_action
  end

  def received_action?(action)
    actions.include?(action)
  end

end

describe "ManagerInterface" do

  include ManagerInterfaceTestHelper

  before :each do
    @Manager = Adhearsion::VoIP::Asterisk::Manager
    @host, @port = "foobar", 9999
  end

  it "should receive data and not die" do
    flexmock(@Manager::ManagerInterface::ManagerInterfaceAction).new_instances.should_receive(:response).once.and_return new_blank_ami_response

    mocked_queue

    manager = new_manager_without_events

    t = flexmock('Thread')
    t.should_receive(:join)
    flexmock(Thread).should_receive(:new).twice.and_yield.and_return(t)
    mock_em_connection = mock_for_next_created_socket

    mock_em_connection.should_receive(:readpartial).once.and_return ami_packets.fresh_socket_connection
    mock_em_connection.should_receive(:readpartial).once.and_raise EOFError

    flexmock(manager).should_receive(:action_message_received).once.with(@Manager::ManagerInterfaceResponse)
    manager.connect!
  end

  it "should use the defaults specified in DEFAULT_SETTINGS when no overrides are given" do
    manager = @Manager::ManagerInterface.new
    %w[host port username password events].each do |property|
      manager.send(property).should ==@Manager::ManagerInterface::DEFAULT_SETTINGS[property.to_sym]
    end
  end

  it "should override the DEFAULT_SETTINGS settings with overrides given to the constructor" do
    overrides = {
      :host     => "yayiamahost",
      :port     => 1337,
      :username => "root",
      :password => "toor",
      :events   => false
    }
    manager = @Manager::ManagerInterface.new overrides
    %w[host port username password events].each do |property|
      manager.send(property).should ==overrides[property.to_sym]
    end
  end

  it "should raise an ArgumentError when it's instantiated with an unrecognized named argument" do
    the_following_code {
      @Manager::ManagerInterface.new :ifeelsopretty => "OH SO PRETTY!"
    }.should raise_error ArgumentError
  end

  it "a received message that matches an action ID for which we're waiting" do
    action_id = "OHAILOLZ"

    manager = new_manager_without_events

    flexmock(@Manager::ManagerInterface::ManagerInterfaceAction).new_instances.should_receive(:action_id).once.and_return action_id
    flexmock(manager).should_receive(:login_actions).once.and_return

    mock_em_connection = mock_for_next_created_socket

    manager.connect!

    flexmock(FutureResource).new_instances.should_receive(:resource).once.and_return :THREAD_WAITING_MOCKED_OUT
    flexmock(FutureResource).new_instances.should_receive(:resource=).once.with(@Manager::ManagerInterfaceResponse)

    manager.send_action("ping").should be :THREAD_WAITING_MOCKED_OUT

    # Avoid race where message may not yet be in the sent_messages queue
    sleep(0.1)
    manager.send(:instance_variable_get, :@sent_messages).has_key?(action_id).should be true

    manager.send(:instance_variable_get, :@actions_connection).
        send(:instance_variable_get, :@handler).
        receive_data("Response: Pong\r\nActionID: #{action_id}\r\n\r\n")

    manager.send(:instance_variable_get, :@sent_messages).has_key?(action_id).should be false
  end

  it "a received event is received by Theatre" do
    flexmock(Adhearsion::Events).should_receive(:trigger).once.with(%w[asterisk manager_interface], @Manager::ManagerInterfaceEvent)

    manager = new_manager_with_events
    flexmock(manager).should_receive(:login_actions).once.and_return
    flexmock(manager).should_receive(:login_events).once.and_return

    mock_actions_connection = mock_for_next_created_socket
    mock_events_connection  = mock_for_next_created_socket

    manager.connect!

    manager.send(:instance_variable_get, :@events_connection).
        send(:instance_variable_get, :@handler).
        receive_data ami_packets.reload_event
  end

  it "an ManagerInterfaceError should be raised when the action's FutureResource is set to an ManagerInterfaceError instance" do

    flexmock(FutureResource).new_instances.should_receive(:resource).once.and_return @Manager::ManagerInterfaceError.new

    manager            = new_manager_without_events
    actions_connection = mock_for_next_created_socket
    flexmock(manager).should_receive(:login_actions).once.and_return

    manager.connect!

    the_following_code {
      manager.send_action "Foobar"
    }.should raise_error @Manager::ManagerInterfaceError

  end

  it "an AuthenticationFailedException should be raised when the action's FutureResource is set to an ManagerInterfaceError instance" do
    flexmock(FutureResource).new_instances.should_receive(:resource).once.and_return @Manager::ManagerInterfaceError.new

    manager            = new_manager_without_events
    actions_connection = mock_for_next_created_socket

    the_following_code {
      manager.connect!
    }.should raise_error @Manager::ManagerInterface::AuthenticationFailedException

  end

# FIXME: Fix this it or nuke it.
#  it "THIS TEST IS AN EXPERIMENT TO START FROM SCRATCH AND TEST WRITES GOING THROUGH THE WRITE QUEUE!" do
#    # Note: this it will be cleaned up and used a reference for refactoring the other failing tests in this file.
#    response = new_blank_ami_response
#    flexmock(@Manager::ManagerInterface::ManagerInterfaceAction).new_instances.should_receive(:response).once.and_return response
#
#    flexmock(TCPSocket).should_receive(:new).once.and_return StringIO.new
#
#    write_queue_mock = mocked_queue
#
#    manager = new_manager_without_events
#    write_queue_mock.manager = manager
#
#    manager.connect!
#
#    manager.send_action "Ping"
#
#    write_queue_mock.actions.size.should be 2
#    write_queue_mock.actions.first.name.should =="login"
#    write_queue_mock.actions.last.name.should =="ping"
#  end

  it "after calling connect!() with events enabled, both connections perform a login" do
    response = new_blank_ami_response

    flexstub(@Manager::ManagerInterface::ManagerInterfaceAction).new_instances.should_receive(:response).and_return response

    # FIXME: It would be better if actions_socket blocked like the real thing...
    actions_socket = StringIO.new
    events_socket  = StringIO.new

    flexmock(TCPSocket).should_receive(:new).twice.and_return actions_socket, events_socket

    write_queue_mock = mocked_queue

    manager = new_manager_with_events
    flexmock(manager).should_receive(:start_actions_writer_loop).and_return true
    manager.connect!

    write_queue_mock.actions.first.name.should == "login"
    write_queue_mock.actions.first.headers['Events'].should == "Off"
  end

  it "a failed login on the actions socket raises an AuthenticationFailedException" do
    manager = new_manager_with_events

    mock_socket = flexmock("mock TCPSocket")

    # By saying this should happen only once, we're also asserting that the events thread never does a login.
    flexmock(EventSocket).should_receive(:connect).once.and_return mock_socket

    login_error         = @Manager::ManagerInterfaceError.new
    login_error.message = "Authentication failed"

    action = @Manager::ManagerInterface::ManagerInterfaceAction.new "Login", "Username" => "therestdoesntmatter"
    flexmock(action).should_receive(:response).once.and_return login_error

    flexmock(@Manager::ManagerInterface::ManagerInterfaceAction).should_receive(:new).once.and_return action

    the_following_code {
      manager.connect!
    }.should raise_error @Manager::ManagerInterface::AuthenticationFailedException

  end

  # it "should raise an error if trying to send an action before connecting" do
  #   the_following_code {
  #     new_manager_without_events.send_action "foo"
  #   }.should raise_error( @Manager::ManagerInterface::NotConnectedError)
  # end

  it "sending an Action on the ManagerInterface should be received by the EventSocket" do
    name, headers = "foobar", {"BLAH" => 1226534602.32764}

    response = @Manager::ManagerInterfaceResponse.new

    mock_connection = flexmock "EventSocket"
    flexmock(EventSocket).should_receive(:connect).once.and_return mock_connection

    action = @Manager::ManagerInterface::ManagerInterfaceAction.new(name, headers)
    action.future_resource.resource = response

    flexmock(@Manager::ManagerInterface::ManagerInterfaceAction).should_receive(:new).once.with(name, headers).and_return action

    write_queue_mock = mocked_queue

    manager = new_manager_without_events
    flexmock(manager).should_receive(:login_actions).once.and_return

    manager.connect!
    manager.send_action(name, headers)

    write_queue_mock.actions.size.should be 1
  end

  it 'ManagerInterface#action_error_received' do
    action_id = "foobar"

    error = @Manager::ManagerInterfaceError.new
    error["ActionID"] = action_id

    action = @Manager::ManagerInterface::ManagerInterfaceAction.new "Blah"
    flexmock(action).should_receive(:action_id).and_return action_id
    flexmock(action.future_resource).should_receive(:resource=).once.with(error)
    manager = new_manager_without_events

    flexmock(manager).should_receive(:data_for_message_received_with_action_id).once.with(action_id).and_return action

    manager.action_error_received error
  end

  it "unsupported actions" do
    @Manager::ManagerInterface::UnsupportedActionName::UNSUPPORTED_ACTION_NAMES.empty?.should_not be true
    @Manager::ManagerInterface::UnsupportedActionName::UNSUPPORTED_ACTION_NAMES.each do |action_name|
      manager = new_manager_without_events
      the_following_code {
        manager.send_action action_name
      }.should raise_error @Manager::ManagerInterface::UnsupportedActionName
    end
  end
# FIXME: Fix this it or nuke it.
#  it "normal use of Action:SIPPeers (which has causal events)" do
#
#    raise "TODO"
#
#    response = @Manager::ManagerInterfaceResponse.new
#    response["Message"] = "Peer status list will follow"
#
#    first_peer_entry = @Manager::ManagerInterfaceEvent.new "PeerEntry"
#    { "Channeltype" => "SIP", "ObjectName" => "softphone", "ChanObjectType" => "peer", "IPaddress" => "-none-",
#        "IPport" => "0", "Dynamic" => "yes", "Natsupport" => "no", "VideoSupport" => "no", "ACL" => "no",
#        "Status" => "Unmonitored", "RealtimeDevice" => "no" }.each_pair do |key,value|
#      first_peer_entry[key] = value
#    end
#
#    second_peer_entry = @Manager::ManagerInterfaceEvent.new "PeerEntry"
#    { "Channeltype" => "SIP", "ObjectName" => "teliax", "ChanObjectType" => "peer", "IPaddress" => "74.201.8.23",
#          "IPport" => "5060", "Dynamic" => "no", "Natsupport" => "yes", "VideoSupport" => "no", "ACL" => "no",
#          "Status" => "OK (24 ms)", "RealtimeDevice" => "no" }.each_pair do |key, value|
#      second_peer_entry[key] = value
#    end
#
#    ender = @Manager::ManagerInterfaceEvent.new "PeerlistComplete"
#    ender["ListItems"] = "2"
#
#    # flexmock(@Manager::ManagerInterface).new_instances.should_receive(:actions_connection_established).once.and_return
#    # flexmock(@Manager::ManagerInterface).new_instances.should_receive(:write_loop).once.and_return
#
#    manager = new_manager_without_events
#
#    class << manager
#      undef write_loop
#    end
#    action = manager.send_action "SIPPeers"
#
#    manager.send(:action_message_received, response)
#    manager.send(:action_message_received, first_peer_entry)
#    manager.send(:action_message_received, second_peer_entry)
#    manager.send(:action_message_received, ender)
#
#    action.response.should be_a_kind_of Array
#    action.response.size.should be 2
#
#    first, second = response.response
#
#    first["ObjectName"].should =="softphone"
#    last["ObjectName"].should =="teliax"
#  end
#
# FIXME: Fix this it or nuke it.
#  it "use of Action:SIPPeers (which has causal events) which causes an error" do
#
#  end

  # TODO: Create the abstraction layer atop AMI with separate tests and it harness.

  # TODO: Add tests which cause actions that don't reply with an action ID to raise an exception when sent

end

describe "ManagerInterface#write_loop" do

  include ManagerInterfaceTestHelper

  before :each do
    @Manager = Adhearsion::VoIP::Asterisk::Manager
  end

  it "should stop when the stop instruction is sent to the write queue and return :stopped" do
    flexmock(TCPSocket).should_receive(:new).once.and_return StringIO.new
    flexmock(FutureResource).new_instances.should_receive(:resource).once.and_return new_blank_ami_response

    mock_queue = flexmock "a mock write-Queue"

    mock_queue.should_receive(:shift).once.and_return :STOP!
    mock_queue.should_receive(:<<).and_return nil

    flexmock(Queue).should_receive(:new).once.and_return mock_queue

    manager = new_manager_without_events
    manager.connect!
    manager.disconnect!
  end

end

describe "Class methods of ManagerInterface" do

  before(:each) do
    @ManagerInterface = Adhearsion::VoIP::Asterisk::Manager::ManagerInterface
  end

  it "the SIPPeers actions should be a causal event" do
    @ManagerInterface.has_causal_events?("SIPPeers").should be true
  end

  it "the Queues action should not respond with an action id" do
    @ManagerInterface.replies_with_action_id?("Queues").should == false
  end

  it "the IAXPeers action should not respond with an action id" do
    # FIXME: This test relies on the side effect that earlier tests have run
    # and initialized the UnsupportedActionName::UNSUPPORTED_ACTION_NAMES
    # constant for an "unknown" version of Asterisk.  This should be fixed
    # to be more specific about which version of Asterisk is under test.
    # IAXPeers is supported (with Action IDs!) since Asterisk 1.8
    @ManagerInterface.replies_with_action_id?("IAXPeers").should == false
  end

  it "the ParkedCalls terminator event" do
    @ManagerInterface.causal_event_terminator_name_for("ParkedCalls").should =="parkedcallscomplete"
    @ManagerInterface.causal_event_terminator_name_for("parkedcalls").should =="parkedcallscomplete"
  end

end

describe "ManagerInterfaceAction" do

  before :each do
    @ManagerInterface = Adhearsion::VoIP::Asterisk::Manager::ManagerInterface
  end

  it "should simply proxy the replies_with_action_id?() method" do
    name, headers = "foobar", {"foo" => "bar"}
    flexmock(@ManagerInterface).should_receive(:replies_with_action_id?).once.and_return
    @ManagerInterface::ManagerInterfaceAction.new(name, headers).replies_with_action_id?
  end

  it "should simply proxy the has_causal_events?() method" do
    name, headers = "foobar", {"foo" => "bar"}
    action = @ManagerInterface::ManagerInterfaceAction.new(name, headers)
    flexmock(@ManagerInterface).should_receive(:has_causal_events?).once.with(name, headers).and_return :foo
    action.has_causal_events?.should be :foo
  end

  it "should properly convert itself into a String when additional headers are given" do
    name, headers = "Hawtsawce", {"Monkey" => "Zoo"}
    string = @ManagerInterface::ManagerInterfaceAction.new(name, headers).to_s
    string.should =~ /^Action: Hawtsawce\r\n/i
    string.should =~ /[^\n]\r\n\r\n$/
    string.should =~ /^(\w+:\s*[\w-]+\r\n){3}\r\n$/
  end

  it "should properly convert itself into a String when no additional headers are given" do
    string = @ManagerInterface::ManagerInterfaceAction.new("Ping").to_s
    string.should =~ /^Action: Ping\r\nActionID: [\w-]+\r\n\r\n$/i

    string = @ManagerInterface::ManagerInterfaceAction.new("ParkedCalls").to_s
    string.should =~ /^Action: ParkedCalls\r\nActionID: [\w-]+\r\n\r\n$/i
  end

end

describe "DelegatingAsteriskManagerInterfaceLexer" do
  it "should translate the :syntax_error_encountered method call when a method_delegation_map is given" do
    official_method, new_method = :syntax_error_encountered, :ohai_syntax_error!
    method_argument = :testing123
    mock_manager_interface = flexmock "ManagerInterface which receives callbacks"
    mock_manager_interface.should_receive(new_method).once.with(method_argument).and_return
    parser = Adhearsion::VoIP::Asterisk::Manager::DelegatingAsteriskManagerInterfaceLexer.new mock_manager_interface,
        official_method => new_method
    parser.send official_method, method_argument
  end
  it "should translate the :message_received method call when a method_delegation_map is given" do
    official_method, new_method = :message_received, :wuzup_new_message_YO!
    method_argument = :message_message_message_message
    mock_manager_interface = flexmock "ManagerInterface which receives callbacks"
    mock_manager_interface.should_receive(new_method).once.with(method_argument).and_return
    parser = Adhearsion::VoIP::Asterisk::Manager::DelegatingAsteriskManagerInterfaceLexer.new mock_manager_interface,
        official_method => new_method
    parser.send official_method, method_argument
  end
  it "should translate the :syntax_error_encountered method call when a method_delegation_map is given" do
    official_method, new_method = :error_received, :zomgs_ERROR!
    method_argument = :errrrrrr
    mock_manager_interface = flexmock "ManagerInterface which receives callbacks"
    mock_manager_interface.should_receive(new_method).once.with(method_argument).and_return
    parser = Adhearsion::VoIP::Asterisk::Manager::DelegatingAsteriskManagerInterfaceLexer.new mock_manager_interface,
        official_method => new_method
    parser.send official_method, method_argument
  end

  it "should translate all method calls when a comprehensive method_delegation_map is given" do
    method_delegation_map = {
      :error_received   => :here_is_an_error,
      :message_received => :here_is_a_message,
      :syntax_error_encountered => :here_is_a_syntax_error
    }
    mock_manager_interface = flexmock "ManagerInterface which receives callbacks"
    method_delegation_map.each_pair do |old_method,new_method|
      mock_manager_interface.should_receive(new_method).once.with(old_method).and_return
    end
    parser = Adhearsion::VoIP::Asterisk::Manager::DelegatingAsteriskManagerInterfaceLexer.new mock_manager_interface, method_delegation_map
    method_delegation_map.each_pair do |old_method, new_method|
      parser.send(old_method, old_method)
    end
  end
end

describe "ActionManagerInterfaceConnection" do
  it "should notify its associated ManagerInterface when a new message is received"
  it "should notify its associated ManagerInterface when a new event is received"
  it "should notify its associated ManagerInterface when a new error is received"
end

describe "EventManagerInterfaceConnection" do
  it "should notify its associated ManagerInterface when a new message is received"
  it "should notify its associated ManagerInterface when a new event is received"
  it "should notify its associated ManagerInterface when a new error is received"
  it "should stop gracefully by allowing the Queue to finish writing to the Theatre"
  it "should stop forcefully by not allowing the Queue to finish writing to the Theatre"
end
