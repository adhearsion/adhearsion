require File.dirname(__FILE__) + "/../../../test_helper"
require 'adhearsion'
require 'adhearsion/voip/asterisk/manager_interface'

context "ManagerInterface" do
  
  before :each do
    @socket_connect_data = "Asterisk Call Manager/1.0\r\nResponse: Success\r\nMessage: Authentication accepted\r\n\r\n"
    @Manager = Adhearsion::VoIP::Asterisk::Manager
  end
  
  test "should receive data and not die" do
    host, port = "localhost", 9999
    
    manager = @Manager::ManagerInterface.new :hostname => host, :port => port
    
    mock_em_connection = flexmock "mock object with ManagerInterfaceActionsConnection mixin"
    mock_em_connection.extend @Manager::ManagerInterface::ManagerInterfaceActionsConnection.new(manager)
    mock_em_connection.should_receive(:send_data).zero_or_more_times.with(String).and_return
    flexmock(EventMachine).should_receive(:connect).with(host, port, Module).and_return mock_em_connection
    
    manager.connect!
    
    flexmock(manager).should_receive(:action_message_received).once.with(@Manager::NormalAmiResponse)
    manager.send(:instance_variable_get, :@actions_connection).receive_data(@socket_connect_data)
  end
  
  test "a received message that matches an action ID for which we're waiting" do
    host, port = "localhost", 9999
    
    # mock out new_action_id
    action_id = "OHAILOLZ"
    
    # instantiate a new ManagerInterface
    manager = @Manager::ManagerInterface.new :hostname => host, :port => port
    
    flexmock(manager).should_receive(:new_action_id).once.and_return action_id
    
    mock_em_connection = flexmock "mock object with ManagerInterfaceActionsConnection mixin"
    mock_em_connection.extend @Manager::ManagerInterface::ManagerInterfaceActionsConnection.new(manager)
    mock_em_connection.should_receive(:send_data).once.and_return
    flexmock(EventMachine).should_receive(:connect).with(host, port, Module).and_return mock_em_connection
    
    manager.connect!
    
    flexmock(FutureResource).new_instances.should_receive(:resource).once.and_return :THREAD_WAITING_MOCKED_OUT
    flexmock(FutureResource).new_instances.should_receive(:resource=).once.with(@Manager::NormalAmiResponse)
    
    manager.send_action("ping").should.equal :THREAD_WAITING_MOCKED_OUT
    
    # test that the hash table is waiting for the action
    manager.send(:instance_variable_get, :@sent_messages).has_key?(action_id).should.equal true
    
    # flexmock(manager).should_receive(:action_message_received).once.with(@Manager::NormalAmiResponse)
    
    mock_em_connection.receive_data("Response: Pong\r\nActionID: #{action_id}\r\n\r\n")
    
    manager.send(:instance_variable_get, :@sent_messages).has_key?(action_id).should.equal false
  end
  
end

context "DelegatingAsteriskManagerInterfaceParser" do
  test "should translate the :syntax_error_encountered method call when a method_delegation_map is given" do
    official_method, new_method = :syntax_error_encountered, :ohai_syntax_error!
    method_argument = :testing123
    mock_manager_interface = flexmock "ManagerInterface which receives callbacks"
    mock_manager_interface.should_receive(new_method).once.with(method_argument).and_return
    parser = Adhearsion::VoIP::Asterisk::Manager::DelegatingAsteriskManagerInterfaceParser.new mock_manager_interface,
        official_method => new_method
    parser.send official_method, method_argument
  end
  test "should translate the :message_received method call when a method_delegation_map is given" do
    official_method, new_method = :message_received, :wuzup_new_message_YO!
    method_argument = :message_message_message_message
    mock_manager_interface = flexmock "ManagerInterface which receives callbacks"
    mock_manager_interface.should_receive(new_method).once.with(method_argument).and_return
    parser = Adhearsion::VoIP::Asterisk::Manager::DelegatingAsteriskManagerInterfaceParser.new mock_manager_interface,
        official_method => new_method
    parser.send official_method, method_argument
  end
  test "should translate the :syntax_error_encountered method call when a method_delegation_map is given" do
    official_method, new_method = :error_received, :zomgs_ERROR!
    method_argument = :errrrrrr
    mock_manager_interface = flexmock "ManagerInterface which receives callbacks"
    mock_manager_interface.should_receive(new_method).once.with(method_argument).and_return
    parser = Adhearsion::VoIP::Asterisk::Manager::DelegatingAsteriskManagerInterfaceParser.new mock_manager_interface,
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
    parser=Adhearsion::VoIP::Asterisk::Manager::DelegatingAsteriskManagerInterfaceParser.new mock_manager_interface, method_delegation_map
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