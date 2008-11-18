require File.dirname(__FILE__) + "/../../../test_helper"
require 'adhearsion'
require 'adhearsion/voip/asterisk/manager_interface'

context "ManagerInterface" do
  
  include ManagerInterfaceTestHelper
  
  before :each do
    @Manager = Adhearsion::VoIP::Asterisk::Manager
    @host, @port = "foobar", 9999
  end
  
  test "should receive data and not die" do
    flexmock(@Manager::ManagerInterface::ManagerInterfaceAction).new_instances.should_receive(:response).once.and_return new_blank_ami_response
    
    mocked_queue
    
    manager = new_manager_without_events
    flexmock(Thread).should_receive(:new).twice.and_yield
    mock_em_connection = mock_for_next_created_socket
    
    mock_em_connection.should_receive(:readpartial).once.and_return ami_packets.fresh_socket_connection
    mock_em_connection.should_receive(:readpartial).once.and_raise EOFError
    
    flexmock(manager).should_receive(:action_message_received).once.with(@Manager::NormalAmiResponse)
    manager.connect!
  end
  
  test "should use the defaults specified in DEFAULT_SETTINGS when no overrides are given" do
    manager = @Manager::ManagerInterface.new
    %w[host port username password events].each do |property|
      manager.send(property).should.eql @Manager::ManagerInterface::DEFAULT_SETTINGS[property.to_sym]
    end
  end
  
  test "should override the DEFAULT_SETTINGS settings with overrides given to the constructor" do
    overrides = {
      :host     => "yayiamahost",
      :port     => 1337,
      :username => "root",
      :password => "toor",
      :events   => false
    }
    manager = @Manager::ManagerInterface.new overrides
    %w[host port username password events].each do |property|
      manager.send(property).should.eql overrides[property.to_sym]
    end
  end
  
  test "should raise an ArgumentError when it's instantiated with an unrecognized named argument" do
    the_following_code {
      @Manager::ManagerInterface.new :ifeelsopretty => "OH SO PRETTY!"
    }.should.raise ArgumentError
  end
  
  test "a received message that matches an action ID for which we're waiting" do
    action_id = "OHAILOLZ"
    
    manager = new_manager_without_events
    
    flexmock(@Manager::ManagerInterface::ManagerInterfaceAction).new_instances.should_receive(:action_id).once.and_return action_id
    flexmock(manager).should_receive(:login_actions).once.and_return
    
    mock_em_connection = mock_for_next_created_socket
    
    manager.connect!
    
    flexmock(FutureResource).new_instances.should_receive(:resource).once.and_return :THREAD_WAITING_MOCKED_OUT
    flexmock(FutureResource).new_instances.should_receive(:resource=).once.with(@Manager::NormalAmiResponse)
    
    manager.send_action("ping").should.equal :THREAD_WAITING_MOCKED_OUT
    
    manager.send(:instance_variable_get, :@sent_messages).has_key?(action_id).should.equal true
    
    manager.send(:instance_variable_get, :@actions_connection).
        send(:instance_variable_get, :@handler).
        receive_data("Response: Pong\r\nActionID: #{action_id}\r\n\r\n")
    
    manager.send(:instance_variable_get, :@sent_messages).has_key?(action_id).should.equal false
  end
  
  test "a received event is received by Theatre" do
    flexmock(Adhearsion::Events).should_receive(:trigger).once.with(%w[asterisk events], @Manager::Event)
    
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
  
  test "an AMIError should be raised when the action's FutureResource is set to an AMIError instance" do

    flexmock(FutureResource).new_instances.should_receive(:resource).once.and_return @Manager::AMIError.new
    
    manager            = new_manager_without_events
    actions_connection = mock_for_next_created_socket
    flexmock(manager).should_receive(:login_actions).once.and_return
    
    manager.connect!
    
    the_following_code {
      manager.send_action "Foobar"
    }.should.raise @Manager::AMIError
    
  end
  
  test "an AuthenticationFailedException should be raised when the action's FutureResource is set to an AMIError instance" do
    flexmock(FutureResource).new_instances.should_receive(:resource).once.and_return @Manager::AMIError.new
    
    manager            = new_manager_without_events
    actions_connection = mock_for_next_created_socket
    
    the_following_code {
      manager.connect!
    }.should.raise @Manager::ManagerInterface::AuthenticationFailedException
    
  end
  
  test "THIS TEST IS AN EXPERIMENT TO START FROM SCRATCH AND TEST WRITES GOING THROUGH THE WRITE QUEUE!" do
    # Note: this test will be cleaned up and used a reference for refactoring the other failing tests in this file.
    response = new_blank_ami_response
    flexmock(@Manager::ManagerInterface::ManagerInterfaceAction).new_instances.should_receive(:response).once.and_return response
    
    flexmock(TCPSocket).should_receive(:new).once.and_return StringIO.new
    
    write_queue_mock = mocked_queue
    
    manager = new_manager_without_events
    write_queue_mock.manager = manager
    
    manager.connect!
    
    manager.send_action "Ping"
    
    write_queue_mock.actions.size.should.equal 2
    write_queue_mock.actions.first.name.should.eql "Login"
    write_queue_mock.actions.last.name.should.eql "Ping"
  end
  
  test "after calling connect!() with events enabled, both connections perform a login" do
    response = new_blank_ami_response
    
    flexstub(@Manager::ManagerInterface::ManagerInterfaceAction).new_instances.should_receive(:response).and_return response
    
    actions_socket = StringIO.new
    events_socket  = StringIO.new
    
    flexmock(TCPSocket).should_receive(:new).twice.and_return actions_socket, events_socket
    
    write_queue_mock = mocked_queue
    
    manager = new_manager_with_events
    manager.connect!
    
    write_queue_mock.actions.size.should.equal 1
    write_queue_mock.actions.select { |action| action.name == "Login" }.size.should.equal 1
    write_queue_mock.actions.first.headers['Events'].should.eql "Off"
  end
  
  test "a failed login on the actions socket raises an AuthenticationFailedException" do
    manager = new_manager_with_events
    
    mock_socket = flexmock("mock TCPSocket")
    
    # By saying this should happen only once, we're also asserting that the events thread never does a login.
    flexmock(EventSocket).should_receive(:connect).once.and_return mock_socket
    
    login_error         = @Manager::AMIError.new
    login_error.message = "Authentication failed"
    
    action = @Manager::ManagerInterface::ManagerInterfaceAction.new "Login", "Username" => "therestdoesntmatter"
    flexmock(action).should_receive(:response).once.and_return login_error
    
    flexmock(@Manager::ManagerInterface::ManagerInterfaceAction).should_receive(:new).once.and_return action
    
    the_following_code {
      manager.connect!
    }.should.raise @Manager::ManagerInterface::AuthenticationFailedException
    
  end
  
  # test "should raise an error if trying to send an action before connecting" do
  #   the_following_code {
  #     new_manager_without_events.send_action "foo"
  #   }.should.raise( @Manager::ManagerInterface::NotConnectedError)
  # end
  
  test "sending an Action on the ManagerInterface should be received by the EventSocket" do
    name, headers = "foobar", {"BLAH" => 1226534602.32764}
    
    response = @Manager::NormalAmiResponse.new
    
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
    
    write_queue_mock.actions.size.should.equal 1
  end
  
  test 'ManagerInterface#action_error_received' do
    action_id = "foobar"
    
    error = @Manager::AMIError.new
    error["ActionID"] = action_id
    
    action = @Manager::ManagerInterface::ManagerInterfaceAction.new "Blah"
    flexmock(action).should_receive(:action_id).and_return action_id
    flexmock(action.future_resource).should_receive(:resource=).once.with(error)
    manager = new_manager_without_events
    
    flexmock(manager).should_receive(:data_for_message_received_with_action_id).once.with(action_id).and_return action
    
    manager.action_error_received error
  end
  
  # TEST action_error_received()!! It's buggy!
  
  # test 'a "will follow" AMI action' do
  
  # TODO: TEST THAT actions with causal events are combined.
  
  # TODO: TEST THE WRITE LOCK FOR MESSAGES WHICH DO NOT REPLY WITH AN ACTION ID DO LOCK EVERYTHING..
  
  # QUESTION: Do AMI errors respond with action id?
  
  # YAGNI? test "a failed login on sets the state to :failed"
  
end

context "ManagerInterface#write_loop" do
  
  include ManagerInterfaceTestHelper
  
  before :each do
    @Manager = Adhearsion::VoIP::Asterisk::Manager
  end
  
  test "should stop when the stop instruction is sent to the write queue and return :stopped" do
    flexmock(TCPSocket).should_receive(:new).once.and_return StringIO.new
    flexmock(FutureResource).new_instances.should_receive(:resource).once.and_return new_blank_ami_response
    
    mock_queue = flexmock "a mock write-Queue"
    
    mock_queue.should_receive(:shift).once.and_return :STOP!
    mock_queue.should_receive(:<<).once.and_return nil
    
    flexmock(Queue).should_receive(:new).once.and_return mock_queue
    
    manager = new_manager_without_events
    manager.connect!
  end
  
end

context "ManagerInterfaceAction" do
  
  before :each do
    @ManagerInterface = Adhearsion::VoIP::Asterisk::Manager::ManagerInterface
  end
  
  test "should simply proxy the replies_with_action_id?() method" do
    name, headers = "foobar", {"foo" => "bar"}
    flexmock(@ManagerInterface).should_receive(:replies_with_action_id?).once.and_return
    @ManagerInterface::ManagerInterfaceAction.new(name, headers).replies_with_action_id?
  end
  
  test "should simply proxy the has_causal_events?() method" do
    name, headers = "foobar", {"foo" => "bar"}
    flexmock(@ManagerInterface).should_receive(:has_causal_events?).once.and_return
    @ManagerInterface::ManagerInterfaceAction.new(name, headers).has_causal_events?
  end
  
  test "should properly convert itself into a String" do
    name, headers = "Hawtsawce", {"Monkey" => "Zoo"}
    string = @ManagerInterface::ManagerInterfaceAction.new(name, headers).to_s
    string.should =~ /^Action: Hawtsawce\r\n/
    string.should =~ /\r\n\r\n$/
    string.should =~ /^(\w+:\s*[\w-]+\r\n){3}\r\n$/
  end
  
end

context "DelegatingAsteriskManagerInterfaceLexer" do
  test "should translate the :syntax_error_encountered method call when a method_delegation_map is given" do
    official_method, new_method = :syntax_error_encountered, :ohai_syntax_error!
    method_argument = :testing123
    mock_manager_interface = flexmock "ManagerInterface which receives callbacks"
    mock_manager_interface.should_receive(new_method).once.with(method_argument).and_return
    parser = Adhearsion::VoIP::Asterisk::Manager::DelegatingAsteriskManagerInterfaceLexer.new mock_manager_interface,
        official_method => new_method
    parser.send official_method, method_argument
  end
  test "should translate the :message_received method call when a method_delegation_map is given" do
    official_method, new_method = :message_received, :wuzup_new_message_YO!
    method_argument = :message_message_message_message
    mock_manager_interface = flexmock "ManagerInterface which receives callbacks"
    mock_manager_interface.should_receive(new_method).once.with(method_argument).and_return
    parser = Adhearsion::VoIP::Asterisk::Manager::DelegatingAsteriskManagerInterfaceLexer.new mock_manager_interface,
        official_method => new_method
    parser.send official_method, method_argument
  end
  test "should translate the :syntax_error_encountered method call when a method_delegation_map is given" do
    official_method, new_method = :error_received, :zomgs_ERROR!
    method_argument = :errrrrrr
    mock_manager_interface = flexmock "ManagerInterface which receives callbacks"
    mock_manager_interface.should_receive(new_method).once.with(method_argument).and_return
    parser = Adhearsion::VoIP::Asterisk::Manager::DelegatingAsteriskManagerInterfaceLexer.new mock_manager_interface,
        official_method => new_method
    parser.send official_method, method_argument
  end
  
  test "should translate all method calls when a comprehensive method_delegation_map is given" do
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

context "ActionManagerInterfaceConnection" do
  test "should notify its associated ManagerInterface when a new message is received"
  test "should notify its associated ManagerInterface when a new event is received"
  test "should notify its associated ManagerInterface when a new error is received"
end

context "EventManagerInterfaceConnection" do
  test "should notify its associated ManagerInterface when a new message is received"
  test "should notify its associated ManagerInterface when a new event is received"
  test "should notify its associated ManagerInterface when a new error is received"
  test "should stop gracefully by allowing the Queue to finish writing to the Theatre"
  test "should stop forcefully by not allowing the Queue to finish writing to the Theatre"
end

BEGIN {
  
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
      returning OpenStruct.new do |struct|
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
      @Manager::ManagerInterface.new :host => @host, :port => @port, :events => true
    end
    
    def new_manager_without_events
      @Manager::ManagerInterface.new :host => @host, :port => @port, :events => false
    end
    
    def new_blank_ami_response
      @Manager::NormalAmiResponse.new
    end
    
    def mock_for_next_created_socket
      returning flexmock("TCPSocket") do |mock|
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
}
