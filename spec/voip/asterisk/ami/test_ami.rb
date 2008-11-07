require File.dirname(__FILE__) + "/../../../test_helper"
require 'adhearsion'
require 'adhearsion/voip/asterisk/manager_interface'

context "ManagerInterface" do
  
  include ManagerInterfaceTestHelper
  
  before :each do
    @Manager = Adhearsion::VoIP::Asterisk::Manager
    @host, @port = "localhost", 9999
  end
  
  test "should receive data and not die" do
    manager = new_manager_without_events
    flexmock(Thread).should_receive(:new).once.and_yield
    mock_em_connection = mock_for_next_created_socket
    mock_em_connection.should_receive(:readpartial).once.and_return ami_packets.fresh_socket_connection
    mock_em_connection.should_receive(:readpartial).once.and_raise EOFError
    
    flexmock(manager).should_receive(:action_message_received).once.with(@Manager::NormalAmiResponse)
    manager.connect!
    
  end
  
  test "a received message that matches an action ID for which we're waiting" do
    action_id = "OHAILOLZ"
    
    manager = new_manager_without_events
    
    flexmock(manager).should_receive(:new_action_id).once.and_return action_id
    
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
    
    manager.connect!
    
    the_following_code {
      manager.send_action "Foobar"
    }.should.raise @Manager::AMIError
    
  end
  
  test "after calling connect!() with events enabled, both connections perform a login"
  
  test "a failed login on the actions socket raises an AuthenticationFailedException"
  
  test "a failed login on the events socket raises an AuthenticationFailedException"
  
  test "a failed login on the events socket sets the state to :failed"
  
  # TEST THAT BOTH CONNECTIONS DO A LOGIN
  
  # TODO: TEST THAT "will follow" actions include the events relevant to their crap.
  
  # TODO: TEST THE WRITE LOCK FOR MESSAGES WHICH DO NOT REPLY WITH AN ACTION ID DO LOCK EVERYTHING..
  
  # TODO: test that logging in with bad credentials raises an AuthenticationFailedException
  
  # QUESTION: Do AMI errors respond with action id? Answer: NOT ALL OF THEM!
  
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
    
    def ami_packets
      returning OpenStruct.new do |struct|
        struct.fresh_socket_connection = "Asterisk Call Manager/1.0\r\nResponse: Success\r\n"+
            "Message: Authentication accepted\r\n\r\n"
        
        struct.reload_event = %{Event: ChannelReload\r\nPrivilege: system,all\r\nChannel: SIP\r\n} +
            %{ReloadReason: RELOAD (Channel module reload)\r\nRegistry_Count: 1\r\nPeer_Count: 2\r\nUser_Count: 1\r\n\r\n}
        
        struct.unknown_command_error = "Response: Error\r\nActionID: 2123123\r\nMessage: Invalid/unknown command\r\n\r\n"
      end
    end
    
    def new_manager_with_events
      @Manager::ManagerInterface.new :hostname => @host, :port => @port, :events => true
    end
    
    def new_manager_without_events
      @Manager::ManagerInterface.new :hostname => @host, :port => @port, :events => false
    end
    
    def mock_for_next_created_socket
      actions_socket_mock = flexmock "TCPSocket"
      flexmock(TCPSocket).should_receive(:new).once.and_return actions_socket_mock
      actions_socket_mock
    end
    
  end
}
