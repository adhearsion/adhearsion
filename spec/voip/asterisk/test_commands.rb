require File.dirname(__FILE__) + "/../../test_helper"
require 'adhearsion/voip/asterisk/menu_command/menu_class'
require 'adhearsion/voip/asterisk/menu_command/menu_builder'

context 'Asterisk VoIP Commands' do
  include DialplanCommandTestHelpers
  
  test "a call can write back to the PBX" do
    message = 'oh hai'
    mock_call.write message
    pbx_should_have_been_sent message
  end
end

context 'hangup command' do
  include DialplanCommandTestHelpers
  
  test "hanging up a call succesfully writes HANGUP back to the PBX and a success resopnse is returned" do
    pbx_should_respond_with_success
    response = mock_call.hangup
    pbx_should_have_been_sent 'HANGUP'
    response.should.equal pbx_success_response
  end
end

context 'interruptable_play command' do
  
  include DialplanCommandTestHelpers
  
  test 'should return a string for the digit that was pressed' do
    digits = [?0, ?1, ?#, ?*, ?9]
    file = "file_doesnt_matter"
    digits.each { |digit| pbx_should_respond_with_success digit }
    digits.map  { |digit| mock_call.send(:interruptable_play, file) }.should == digits.map(&:chr)
  end
  
  test "should return nil if no digit was pressed" do
    pbx_should_respond_with_success 0
    mock_call.send(:interruptable_play, 'foobar').should.equal nil
  end
  
  test "should play a series of files, stopping the series when a digit is played" do
    stubbed_keypad_input = [0, 0, ?3]
    stubbed_keypad_input.each do |digit|
      pbx_should_respond_with_success digit
    end
    
    files = (100..105).map(&:to_s)
    mock_call.send(:interruptable_play, *files).should == '3'
  end
  
end

context 'wait_for_digit command' do
  
  include DialplanCommandTestHelpers
  
  test 'should return a string for the digit that was pressed' do
    digits = [?0, ?1, ?#, ?*, ?9]
    digits.each { |digit| pbx_should_respond_with_success digit }
    digits.map  { |digit| mock_call.send(:wait_for_digit) }.should == digits.map(&:chr)
  end
  
  test "the timeout given must be converted to milliseconds" do
    pbx_should_respond_with_success 0
    mock_call.send(:wait_for_digit, 1)
    output.messages.first.ends_with?('1000').should.equal true
  end
end

context 'execute' do
  include DialplanCommandTestHelpers
  
  test 'execute writes exec and app name to the PBX' do
    pbx_should_respond_with_success
    assert_success mock_call.execute(:foo)
    pbx_should_have_been_sent 'EXEC foo '
  end
  
  test 'execute returns false if the command was not executed successfully by the PBX' do
    pbx_should_respond_with_failure
    assert !mock_call.execute(:foo), "execute should have failed"
  end
  
  test 'execute can accept arguments after the app name which get translated into pipe-delimited arguments to the PBX' do
    pbx_should_respond_with_success
    mock_call.execute :foo, 'bar', 'baz', 'hi'
    pbx_should_have_been_sent 'EXEC foo bar|baz|hi'
  end
end

context 'play command' do
  include DialplanCommandTestHelpers
  
  test 'passing a single string to play results in the playback application being executed with that file name on the PBX' do
    pbx_should_respond_with_success
    audio_file = "cents-per-minute"
    mock_call.play audio_file
    pbx_was_asked_to_play audio_file
  end
  
  test 'multiple strings can be passed to play, causing multiple playback commands to be issued' do
    2.times do 
      pbx_should_respond_with_success
    end
    audio_files = ["cents-per-minute", 'o-hai']
    mock_call.play(*audio_files)
    pbx_was_asked_to_play(*audio_files)
  end
  
  test 'If a number is passed to play(), the saynumber application is executed with the number as an argument' do
    pbx_should_respond_with_success
    mock_call.play 123
    pbx_was_asked_to_play_number(123)
  end
  
  test 'if a string representation of a number is passed to play(), the saynumber application is executed with the number as an argument' do
    pbx_should_respond_with_success
    mock_call.play '123'
    pbx_was_asked_to_play_number(123)
  end
  
  test 'If a Time is passed to play(), the SayUnixTime application will be executed with the time since the UNIX epoch in seconds as an argument' do
    time = Time.parse("12/5/2000")
    pbx_should_respond_with_success
    mock_call.play time
    pbx_was_asked_to_play_time(time.to_i)
  end 
   
  disabled_test 'If a string matching dollars and (optionally) cents is passed to play(), a series of command will be executed to read the dollar amount' do
    #TODO: I think we should not have this be part of play().  Too much functionality in one method. Too much overloading.  When we want to support multiple
    # currencies, it'll be completely unwieldy.  I'd suggest play_currency as a separate method. - Chad
  end
end

context 'input command' do
  include DialplanCommandTestHelpers
  
  test 'Can ask user for a specified number of digits worth of input via buttons on their phone' do
    pbx_should_respond_with_digits('1234')
    mock_call.input(4)
    pbx_was_asked_for_input(4)
  end
  
  test 'Does properly convert timeouts from seconds to milliseconds when applicable' do
    timeout = 1.minute
    pbx_should_respond_with_digits('4321')
    mock_call.input(4, :timeout => timeout)
    pbx_was_asked_for_input(4, :timeout => 1.minute)
    
    default_timeout_which_asterisk_interprets_as_infinity = -1
    pbx_should_respond_with_digits('4321')
    mock_call.input(4)
    pbx_was_asked_for_input(4, :timeout => default_timeout_which_asterisk_interprets_as_infinity)
  end
  
  test 'Can optionally ask for a specific termination sound when calling input()' do
    pbx_should_respond_with_digits('54321')
    mock_call.input(5, :play => 'arkansas')
    pbx_was_asked_for_input(5, :play => 'arkansas')
  end
  
  test 'Input getting a failure response returns false' do
    pbx_should_respond_with_failure
    assert !mock_call.input(1), "the pbx did not respond with failure"
  end
  
  test 'Input timing out when no digits are pressed returns false' do
    timeout = 1.minute
    pbx_should_respond_to_timeout " (timeout)"
    assert !mock_call.input(2, :timeout => timeout), "the pbx did not respond with failure"
  end
  
  test "Input timing out when digits are pressed returns those digits" do
    timeout = 1.minute
    pbx_should_respond_with_digits_and_timeout 1
    mock_call.input(9, :timeout => timeout).should == '1'
  end
  
  test 'Both possible input timeout responses are recognized' do
    timeout_results = ['200 result=123 (timeout)', '200 result= (timeout)']
    timeout_results.each do |timeout_result|
      assert mock_call.send(:input_timed_out?, timeout_result), "'#{timeout_result}' should have been recognized as a timeout"
    end
  end
end

context "The variable() command" do
  
  include DialplanCommandTestHelpers

  test "should call set_variable for every Hash-key argument given" do
    args = [:ohai, "ur_home_erly"]
    mock_call.should_receive(:set_variable).once.with(*args)
    mock_call.variable Hash[*args]
  end
  
  test "should call set_variable for every Hash-key argument given" do
    many_args = { :a => :b, :c => :d, :e => :f, :g => :h}
    mock_call.should_receive(:set_variable).times(many_args.size)
    mock_call.variable many_args
  end
  
  test "should call get_variable for every String given" do
    variables = ["foo", "bar", :qaz, :qwerty, :baz]
    variables.each do |var|
      mock_call.should_receive(:get_variable).once.with(var).and_return("X")
    end
    mock_call.variable(*variables)
  end
  
  test "should NOT return an Array when just one arg is given" do
    mock_call.should_receive(:get_variable).once.and_return "lol"
    mock_call.variable(:foo).should.not.be.kind_of Array
  end
  
  test "should raise an ArgumentError when a Hash and normal args are given" do
    the_following_code {
      mock_call.variable 5,4,3,2,1, :foo => :bar
    }.should.raise ArgumentError
  end

end

context "the set_variable method" do
  
  include DialplanCommandTestHelpers
  
  test "variables and values are properly quoted" do
    mock_call.should_receive(:raw_response).once.with 'SET VARIABLE foo "i can \\" has ruby?"'
    mock_call.set_variable 'foo', 'i can " has ruby?'
  end
  
  test "to_s() is effectively called on both the key and the value" do
    mock_call.should_receive(:raw_response).once.with 'SET VARIABLE QAZ "QWERTY"'
    mock_call.set_variable :QAZ, :QWERTY
  end
  
end

context "The queue management abstractions" do
  
  include DialplanCommandTestHelpers
  
  test 'should not create separate objects for queues with basically the same name' do
    mock_call.queue('foo').should.equal mock_call.queue('foo')
    mock_call.queue('bar').should.equal mock_call.queue(:bar)
  end
  
  test "queue() should return an instance of QueueProxy" do
    mock_call.queue("foobar").should.be.kind_of Adhearsion::VoIP::Asterisk::Commands::QueueProxy
  end
  
  test "a QueueProxy should respond to join!(), members()" do
    %w[join! agents].each do |method|
      mock_call.queue('foobar').should.respond_to(method)
    end
  end
  
  test 'a QueueProxy should return a QueueAgentsListProxy when members() is called' do
    mock_call.queue('foobar').agents.should.be.kind_of(Adhearsion::VoIP::Asterisk::Commands::QueueProxy::QueueAgentsListProxy)
  end
  
  test 'join! should properly join a queue' do
    mock_call.should_receive(:execute).once.with("queue", "foobaz", "", '', '', '')
    mock_call.should_receive(:get_variable).once.with("QUEUESTATUS").and_return "FULL"
    mock_call.queue("foobaz").join!
  end
  
  test 'should return a symbol representing the result of joining the queue' do
    mock_call.should_receive(:get_variable).once.with("QUEUESTATUS").and_return "TIMEOUT"
    mock_call.queue('monkey').join!.should.equal :timeout
  end
  
  test 'should join a queue with a timeout properly' do
    mock_call.should_receive(:execute).once.with("queue", "foobaz", "", '', '', '60')
    mock_call.should_receive(:get_variable).once.with("QUEUESTATUS").and_return "JOINEMPTY"
    mock_call.queue("foobaz").join! :timeout => 1.minute
  end
  
  test 'should join a queue with an announcement file properly' do
    mock_call.should_receive(:execute).once.with("queue", "roflcopter", "", '', '', '5')
    mock_call.should_receive(:get_variable).once.with("QUEUESTATUS").and_return "JOINEMPTY"
    mock_call.queue("roflcopter").join! :timeout => 5
  end
  
  test 'should join a queue with allow_transfer properly' do
    mock_call.should_receive(:execute).once.with("queue", "roflcopter", "Tt", '', '', '')
    mock_call.should_receive(:get_variable).once.with("QUEUESTATUS").and_return "JOINEMPTY"
    mock_call.queue("roflcopter").join! :allow_transfer => :everyone
  
    mock_call.should_receive(:execute).once.with("queue", "roflcopter", "T", '', '', '')
    mock_call.should_receive(:get_variable).once.with("QUEUESTATUS").and_return "JOINEMPTY"
    mock_call.queue("roflcopter").join! :allow_transfer => :caller

    mock_call.should_receive(:execute).once.with("queue", "roflcopter", "t", '', '', '')
    mock_call.should_receive(:get_variable).once.with("QUEUESTATUS").and_return "JOINEMPTY"
    mock_call.queue("roflcopter").join! :allow_transfer => :agent
  end
  
  test 'should join a queue with allow_hangup properly' do
    mock_call.should_receive(:execute).once.with("queue", "roflcopter", "Hh", '', '', '')
    mock_call.should_receive(:get_variable).once.with("QUEUESTATUS").and_return "JOINEMPTY"
    mock_call.queue("roflcopter").join! :allow_hangup => :everyone
  
    mock_call.should_receive(:execute).once.with("queue", "roflcopter", "H", '', '', '')
    mock_call.should_receive(:get_variable).once.with("QUEUESTATUS").and_return "JOINEMPTY"
    mock_call.queue("roflcopter").join! :allow_hangup => :caller

    mock_call.should_receive(:execute).once.with("queue", "roflcopter", "h", '', '', '')
    mock_call.should_receive(:get_variable).once.with("QUEUESTATUS").and_return "JOINEMPTY"
    mock_call.queue("roflcopter").join! :allow_hangup => :agent
  end
  
  test 'should join a queue properly with the :play argument' do
    mock_call.should_receive(:execute).once.with("queue", "roflcopter", "r", '', '', '')
    mock_call.should_receive(:get_variable).once.with("QUEUESTATUS").and_return "JOINEMPTY"
    mock_call.queue("roflcopter").join! :play => :ringing
    
    mock_call.should_receive(:execute).once.with("queue", "roflcopter", "", '', '', '')
    mock_call.should_receive(:get_variable).once.with("QUEUESTATUS").and_return "JOINEMPTY"
    mock_call.queue("roflcopter").join! :play => :music
  end
  
  test 'joining a queue with many options specified' do
    mock_call.should_receive(:execute).once.with("queue", "q", "rtHh", '', '', '120')
    mock_call.should_receive(:get_variable).once.with("QUEUESTATUS").and_return "JOINEMPTY"
    mock_call.queue('q').join! :allow_transfer => :agent, :timeout => 2.minutes,
                               :play => :ringing, :allow_hangup => :everyone
  end
  
  test 'join!() should raise an ArgumentError when unrecognized Hash key arguments are given' do
    the_following_code {
      mock_call.queue('iwearmysunglassesatnight').join! :misspelled => true
    }.should.raise ArgumentError
  end
  
  test 'should fetch the members with the name given to queue()' do
    mock_call.should_receive(:variable).once.with("QUEUE_MEMBER_COUNT(jay)").and_return 5
    mock_call.queue('jay').agents.size.should.equal 5
  end
  
  test 'should not fetch a QUEUE_MEMBER_COUNT each time count() is called when caching is enabled' do
    mock_call.should_receive(:variable).once.with("QUEUE_MEMBER_COUNT(sales)").and_return 0
    10.times do
      mock_call.queue('sales').agents(:cache => true).size
    end
  end
  
  test 'should raise an argument error if the members() method receives an unrecognized symbol' do
    the_following_code {
      mock_call.queue('foobarz').agents(:cached => true) # common typo
    }.should.raise ArgumentError
  end
  
  test 'when fetching agents, it should properly split by the supported delimiters' do
    queue_name = "doesnt_matter"
    mock_call.should_receive(:get_variable).with("QUEUE_MEMBER_LIST(#{queue_name})").and_return('Agent/007,Agent/003,Zap/2')
    mock_call.queue(queue_name).agents(:cache => true).to_a.size.should.equal 3
  end
  
  test 'when fetching agents, each array index should be an instance of AgentProxy' do
    queue_name = 'doesnt_matter'
    mock_call.should_receive(:get_variable).with("QUEUE_MEMBER_LIST(#{queue_name})").and_return('Agent/007,Agent/003,Zap/2')
    agents = mock_call.queue(queue_name).agents(:cache => true).to_a
    agents.size.should.be > 0
    agents.each do |agent|
      agent.should.be.kind_of Adhearsion::VoIP::Asterisk::Commands::QueueProxy::AgentProxy
    end
  end
  
  test 'QueueAgentsListProxy#<<() should new the channel driver given as the argument to the system' do
    queue_name, agent_channel = "metasyntacticvariablesftw", "Agent/123"
    pbx_should_respond_with_value "ADDED"
    mock_call.should_receive('execute').once.with("AddQueueMember", queue_name, agent_channel, "", "", "")
    mock_call.queue(queue_name).agents.new agent_channel
  end
  
  test 'when a queue agent is dynamically added and the queue does not exist, a QueueDoesNotExistError should be raised' do
    mock_call.should_receive(:get_variable).once.with('AQMSTATUS').and_return('NOSUCHQUEUE')
    the_following_code {
      mock_call.queue('this_should_not_exist').agents.new 'Agent/911'
    }.should.raise Adhearsion::VoIP::Asterisk::Commands::QueueProxy::QueueDoesNotExistError
  end
  
  test 'when a queue agent is dynamiaclly added and the adding was successful, true should be returned' do
    mock_call.should_receive(:get_variable).once.with("AQMSTATUS").and_return("ADDED")
    mock_call.should_receive(:execute).once.with("AddQueueMember", "lalala", "Agent/007", "", "", "")
    return_value = mock_call.queue('lalala').agents.new "Agent/007"
    return_value.should.equal true
  end
  
  test 'should raise an argument when an unrecognized key is given to add()' do
    the_following_code {
      mock_call.queue('q').agents.new :foo => "bar"
    }.should.raise ArgumentError
  end
  
  test 'should execute AddQueueMember with the penalty properly' do
    queue_name = 'name_does_not_matter'
    mock_call.should_receive(:execute).once.with('AddQueueMember', queue_name, '', 10, '', '')
    mock_call.should_receive(:get_variable).once.with('AQMSTATUS').and_return('ADDED')
    mock_call.queue(queue_name).agents.new :penalty => 10
  end
  
  test 'should execute AddQueueMember properly when the name is given' do
    queue_name, agent_name = 'name_does_not_matter', 'Jay Phillips'
    mock_call.should_receive(:execute).once.with('AddQueueMember', queue_name, '', '', '', agent_name)
    mock_call.should_receive(:get_variable).once.with('AQMSTATUS').and_return('ADDED')
    mock_call.queue(queue_name).agents.new :name => agent_name
  end
  
  test 'should execute AddQueueMember properly when the name, penalty, and interface is given' do
    queue_name, agent_name, interface, penalty = 'name_does_not_matter', 'Jay Phillips', 'Agent/007', 4
    mock_call.should_receive(:execute).once.with('AddQueueMember', queue_name, interface, penalty, '', agent_name)
    mock_call.should_receive(:get_variable).once.with('AQMSTATUS').and_return('ADDED')
    mock_call.queue(queue_name).agents.new interface, :name => agent_name, :penalty => penalty
  end
  
  test 'should return a correct boolean for exists?()' do
    mock_call.should_receive(:execute).once.with("RemoveQueueMember", "kablamm", "SIP/AdhearsionQueueExistenceCheck")
    mock_call.should_receive(:get_variable).once.with("RQMSTATUS").and_return "NOTINQUEUE"
    mock_call.queue("kablamm").exists?.should.equal true
    
    mock_call.should_receive(:execute).once.with("RemoveQueueMember", "monkey", "SIP/AdhearsionQueueExistenceCheck")
    mock_call.should_receive(:get_variable).once.with("RQMSTATUS").and_return "NOSUCHQUEUE"
    mock_call.queue("monkey").exists?.should.equal false
  end
  
  test 'should pause an agent properly from a certain queue' do
    mock_call.should_receive(:get_variable).once.with("QUEUE_MEMBER_LIST(lolcats)").and_return "Agent/007,Agent/008"
    mock_call.should_receive(:get_variable).once.with("PQMSTATUS").and_return "PAUSED"
    
    agents = mock_call.queue('lolcats').agents :cache => true
    agents.last.pause!.should.equal true
  end
  
  test 'should pause an agent properly from a certain queue and return false when the agent did not exist' do
    mock_call.should_receive(:get_variable).once.with("QUEUE_MEMBER_LIST(lolcats)").and_return "Agent/007,Agent/008"
    mock_call.should_receive(:get_variable).once.with("PQMSTATUS").and_return "NOTFOUND"
    mock_call.should_receive(:execute).once.with("PauseQueueMember", 'lolcats', "Agent/008")
    
    agents = mock_call.queue('lolcats').agents :cache => true
    agents.last.pause!.should.equal false
  end
  
  test 'should pause an agent globally properly' do
    mock_call.should_receive(:get_variable).once.with("QUEUE_MEMBER_LIST(family)").and_return "Agent/Jay"
    mock_call.should_receive(:get_variable).once.with("PQMSTATUS").and_return "PAUSED"
    mock_call.should_receive(:execute).once.with("PauseQueueMember", nil, "Agent/Jay")
    
    mock_call.queue('family').agents.first.pause! :everywhere => true
  end
  
  test 'should unpause an agent properly' do
    queue_name = "name with spaces"
    mock_call.should_receive(:get_variable).once.with("QUEUE_MEMBER_LIST(#{queue_name})").and_return "Agent/Jay"
    mock_call.should_receive(:get_variable).once.with("UPQMSTATUS").and_return "UNPAUSED"
    mock_call.should_receive(:execute).once.with("UnpauseQueueMember", queue_name, "Agent/Jay")

    mock_call.queue(queue_name).agents.first.unpause!.should.equal true
  end
  
  test 'should unpause an agent globally properly' do
    mock_call.should_receive(:get_variable).once.with("QUEUE_MEMBER_LIST(FOO)").and_return "Agent/Tom"
    mock_call.should_receive(:get_variable).once.with("UPQMSTATUS").and_return "UNPAUSED"
    mock_call.should_receive(:execute).once.with("UnpauseQueueMember", nil, "Agent/Tom")

    mock_call.queue('FOO').agents.first.unpause!(:everywhere => true).should.equal true
  end
  
  test 'waiting_count for a queue that does exist' do
    mock_call.should_receive(:get_variable).once.with("QUEUE_WAITING_COUNT(q)").and_return "50"
    flexmock(mock_call.queue('q')).should_receive(:exists?).once.and_return true
    mock_call.queue('q').waiting_count.should.equal 50
  end
  
  test 'waiting_count for a queue that does not exist' do
    the_following_code {  
      flexmock(mock_call.queue('q')).should_receive(:exists?).once.and_return false
      mock_call.queue('q').waiting_count
    }.should.raise Adhearsion::VoIP::Asterisk::Commands::QueueProxy::QueueDoesNotExistError
  end
  
  test 'empty? should call waiting_count' do
    queue = mock_call.queue 'testing_empty'
    flexmock(queue).should_receive(:waiting_count).once.and_return 0
    queue.should.be.empty
    
    queue = mock_call.queue 'testing_empty'
    flexmock(queue).should_receive(:waiting_count).once.and_return 99
    queue.should.not.be.empty
  end
  
  test 'any? should call waiting_count' do
    queue = mock_call.queue 'testing_empty'
    flexmock(queue).should_receive(:waiting_count).once.and_return 0
    queue.any?.should.equal false
    
    queue = mock_call.queue 'testing_empty'
    flexmock(queue).should_receive(:waiting_count).once.and_return 99
    queue.any?.should.equal true
  end
  
  test 'should remove an agent properly' do
    mock_call.should_receive(:get_variable).once.with("QUEUE_MEMBER_LIST(FOO)").and_return "Agent/Tom"
    mock_call.should_receive(:execute).once.with('RemoveQueueMember', 'FOO', 'Agent/Tom')
    mock_call.should_receive(:get_variable).once.with("RQMSTATUS").and_return "REMOVED"
    mock_call.queue('FOO').agents.first.remove!.should.equal true
  end
  
  test 'should remove an agent properly' do
    mock_call.should_receive(:get_variable).once.with("QUEUE_MEMBER_LIST(FOO)").and_return "Agent/Tom"
    mock_call.should_receive(:execute).once.with('RemoveQueueMember', 'FOO', 'Agent/Tom')
    mock_call.should_receive(:get_variable).once.with("RQMSTATUS").and_return "NOTINQUEUE"
    mock_call.queue('FOO').agents.first.remove!.should.equal false
  end
  
  test "should raise a QueueDoesNotExistError when removing an agent from a queue that doesn't exist" do
    mock_call.should_receive(:get_variable).once.with("QUEUE_MEMBER_LIST(cool_people)").and_return "Agent/ZeroCool"
    mock_call.should_receive(:execute).once.with("RemoveQueueMember", "cool_people", "Agent/ZeroCool")
    mock_call.should_receive(:get_variable).once.with("RQMSTATUS").and_return "NOSUCHQUEUE"
    the_following_code {
      mock_call.queue("cool_people").agents.first.remove!
    }.should.raise Adhearsion::VoIP::Asterisk::Commands::QueueProxy::QueueDoesNotExistError
  end
  
  test "should log an agent in properly with no agent id given" do
    mock_call.should_receive(:execute).once.with('AgentLogin', nil, 's')
    mock_call.queue('barrel_o_agents').agents.login!
  end
  
  test 'should remove "Agent/" before the agent ID given if necessary when logging an agent in' do
    mock_call.should_receive(:execute).once.with('AgentLogin', '007', 's')
    mock_call.queue('barrel_o_agents').agents.login! 'Agent/007'
    
    mock_call.should_receive(:execute).once.with('AgentLogin', '007', 's')
    mock_call.queue('barrel_o_agents').agents.login! '007'
  end

  test 'should add an agent silently properly' do
    mock_call.should_receive(:execute).once.with('AgentLogin', '007', '')
    mock_call.queue('barrel_o_agents').agents.login! 'Agent/007', :silent => false    
  
    mock_call.should_receive(:execute).once.with('AgentLogin', '008', 's')
    mock_call.queue('barrel_o_agents').agents.login! 'Agent/008', :silent => true
  end
  
  test 'logging an agent in should raise an ArgumentError is unrecognized arguments are given' do
    the_following_code {
      mock_call.queue('ohai').agents.login! 1,2,3,4,5
    }.should.raise ArgumentError
    
    the_following_code {
      mock_call.queue('lols').agents.login! 1337, :sssssilent => false
    }.should.raise ArgumentError
    
    the_following_code {
      mock_call.queue('qwerty').agents.login! 777, 6,5,4,3,2,1, :wee => :wee
    }.should.raise ArgumentError
  end
  
end

context 'the menu() method' do

  include DialplanCommandTestHelpers
  
  test "should instantiate a new Menu object, passing in its own arguments" do
    *args = 1,2,3,4,5
    
    flexmock(Adhearsion::VoIP::Asterisk::Commands::Menu).should_receive(:new).once.with(*args).and_throw(:instantiating_menu!)
    
    should_throw(:instantiating_menu!) { mock_call.menu(*args) }
  end
  
  test "should jump to a context when a timeout is encountered and there is at least one exact match" do
    pbx_should_respond_with_successful_background_response ?5
    pbx_should_respond_with_successful_background_response ?4
    pbx_should_respond_with_a_wait_for_digit_timeout
    
    context_named_main  = lambda { throw :inside_main!  }
    context_named_other = lambda { throw :inside_other! }
    flexmock(mock_call).should_receive(:main).once.and_return(context_named_main)
    flexmock(mock_call).should_receive(:other).never
    
    should_pass_control_to_a_context_that_throws :inside_main! do
      mock_call.menu do |link|
        link.main  54
        link.other 543
      end
    end
  end
  
  test "when the 'extension' variable is changed, it should be an instance of PhoneNumber" do
    pbx_should_respond_with_successful_background_response ?5
    mock_call.should_receive(:foobar).once.and_return lambda { throw :foobar! }
    should_pass_control_to_a_context_that_throws :foobar! do
      mock_call.menu do |link|
        link.foobar 5
      end
    end
    5.should === mock_call.extension
    mock_call.extension.__real_string.should == "5"
  end
  
end

context 'the Menu class' do
  
  include DialplanCommandTestHelpers
  
  test "should yield a MenuBuilder when instantiated" do
    lambda {
      Adhearsion::VoIP::Asterisk::Commands::Menu.new do |block_argument|
        block_argument.should.be.kind_of Adhearsion::VoIP::Asterisk::Commands::MenuBuilder
        throw :inside_block
      end
    }.should.throw :inside_block
  end
  
  test "should invoke wait_for_digit instead of interruptable_play when no sound files are given" do
    mock_call.should_receive(:wait_for_digit).once.with(5).and_return '#'
    mock_call.menu { |link| link.does_not_match 3 }
  end
  
  test 'should invoke interruptable_play when sound files are given only for the first digit' do
    sound_files = %w[i like big butts and i cannot lie]
    timeout = 1337
    
    mock_call.should_receive(:interruptable_play).once.with(*sound_files).and_return nil
    mock_call.should_receive(:wait_for_digit).once.with(timeout).and_return nil
    
    mock_call.menu(sound_files, :timeout => timeout) { |link| link.qwerty 12345 }
  end
   
  test 'if the call to interruptable_play receives a timeout, it should execute wait_for_digit with the timeout given' do
      sound_files = %w[i like big butts and i cannot lie]
      timeout = 987
      
      mock_call.should_receive(:interruptable_play).once.with(*sound_files).and_return nil
      mock_call.should_receive(:wait_for_digit).with(timeout).and_return
      
      mock_call.menu(sound_files, :timeout => timeout) { |link| link.foobar 911 }
  end
   
  test "should work when no files are given to be played and a timeout is reached on the first digit" do
    timeout = 12
    [:on_premature_timeout, :on_failure].each do |usage_case|
      should_throw :got_here! do
        mock_call.should_receive(:wait_for_digit).once.with(timeout).and_return nil # Simulates timeout
        mock_call.menu :timeout => timeout do |link|
          link.foobar 0
          link.__send__(usage_case) { throw :got_here! }
        end
      end
    end
  end
  
  test "should default the timeout to five seconds" do
    pbx_should_respond_with_successful_background_response ?2
    pbx_should_respond_with_a_wait_for_digit_timeout
    
    mock_call.should_receive(:wait_for_digit).once.with(5).and_return nil
    mock_call.menu { |link| link.foobar 22 }
  end
  
  test "when matches fail due to timeouts, the menu should repeat :tries times" do
    tries, times_timed_out = 10, 0

    tries.times do
      pbx_should_respond_with_successful_background_response ?4
      pbx_should_respond_with_successful_background_response ?0
      pbx_should_respond_with_a_wait_for_digit_timeout
    end
    
    should_throw :inside_failure_callback do
      mock_call.menu :tries => tries do |link|
        link.pattern_longer_than_our_test_input 400
        link.on_premature_timeout { times_timed_out += 1 }
        link.on_invalid { raise "should never get here!" }
        link.on_failure { throw :inside_failure_callback }
      end
    end
    times_timed_out.should.equal tries
  end
  
  test "when matches fail due to invalid input, the menu should repeat :tries times" do
    tries = 10
    times_invalid = 0
    
    tries.times do
      pbx_should_respond_with_successful_background_response ?0
    end
    
    should_throw :inside_failure_callback do
      mock_call.menu :tries => tries do |link|
        link.be_leet 1337
        link.on_premature_timeout { raise "should never get here!" }
        link.on_invalid { times_invalid += 1 }
        link.on_failure { throw :inside_failure_callback }
      end
    end
    times_invalid.should.equal tries
  end
  
  test "invoke on_invalid callback when an invalid extension was entered" do
    pbx_should_respond_with_successful_background_response ?5
    pbx_should_respond_with_successful_background_response ?5
    pbx_should_respond_with_successful_background_response ?5
    should_throw :inside_invalid_callback do
      mock_call.menu do |link|
        link.onetwothree 123
        link.on_invalid { throw :inside_invalid_callback }
      end
    end
  end
  
  test "invoke on_premature_timeout when a timeout is encountered" do
    pbx_should_respond_with_successful_background_response ?9
    pbx_should_respond_with_a_wait_for_digit_timeout
    
    should_throw :inside_timeout do
      mock_call.menu :timeout => 1 do |link|
        link.something 999
        link.on_premature_timeout { throw :inside_timeout }
      end
    end
  end
  
end

context "the Menu class's high-level judgment" do
  
  include DialplanCommandTestHelpers
  
  test "should match things in ambiguous ranges properly" do
    pbx_should_respond_with_successful_background_response ?1
    pbx_should_respond_with_successful_background_response ?1
    pbx_should_respond_with_successful_background_response ?1
    pbx_should_respond_with_a_wait_for_digit_timeout

    mock_call.should_receive(:main).and_return(lambda { throw :got_here! })
    
    should_pass_control_to_a_context_that_throws :got_here! do
      mock_call.menu do |link|
        link.blah 1
        link.main 11..11111
      end
    end
    111.should === mock_call.extension
  end
  
  test 'should match things in a range when there are many other non-matching patterns' do
    pbx_should_respond_with_successful_background_response ?9
    pbx_should_respond_with_successful_background_response ?9
    pbx_should_respond_with_successful_background_response ?5
    
    mock_call.should_receive(:conferences).and_return(lambda { throw :got_here! })

    should_pass_control_to_a_context_that_throws :got_here! do
      mock_call.menu do |link|
        link.sales        1
        link.tech_support 2
        link.finance      3
        link.conferences  900..999
      end
    end
  end
  
end

context 'the MenuBuilder' do
  
  include MenuBuilderTestHelper
  
  attr_reader :builder
  before:each do
    @builder = Adhearsion::VoIP::Asterisk::Commands::MenuBuilder.new
  end
  
  test "should convert each pattern given to it into a MatchCalculator instance" do
    returning builder do |link|
      link.foo 1,2,3
      link.bar "4", "5", 6
      link.qaz? {}
    end
    
    builder.weighted_match_calculators.size.should.equal 7
    builder.weighted_match_calculators.each do |match_calculator|
      match_calculator.should.be.kind_of Adhearsion::VoIP::Asterisk::Commands::MatchCalculator
    end
  end
  
  test "conflicting ranges" do
    returning builder do |link|
      link.hundreds     100...200
      link.thousands    1_000...2_000
      link.tenthousands 10_000...20_000
    end
    
    builder_should_match_with_these_quantities_of_calculated_matches \
      1       => {  :exact_match_count => 0, :potential_match_count => 11100 },
      10      => {  :exact_match_count => 0, :potential_match_count => 1110  },
      100     => {  :exact_match_count => 1, :potential_match_count => 110   },
      1_000   => {  :exact_match_count => 1, :potential_match_count => 10    },
      10_000  => {  :exact_match_count => 1, :potential_match_count => 0     },
      100_000 => {  :exact_match_count => 0, :potential_match_count => 0     }
    
  end
  
  test 'a String query ran against multiple Numeric patterns and a range' do
    returning builder do |link|
      link.sales        1
      link.tech_support 2
      link.finance      3
      link.conferences  900..999
    end
    match = builder.calculate_matches_for "995"
    require 'pp'
    # pp match
    match.should.not.be.potential_match
    match.should.be.exact_match
    match.actual_exact_matches.should == ["995"]
  end
  
  test "multiple patterns given at once" do
    returning builder do |link|
      link.multiple_patterns 1,2,3,4,5,6,7,8,9
      link.multiple_patterns 100..199, 200..299, 300..399, 400..499, 500..599,
                             600..699, 700..799, 800..899, 900..999
    end
    1.upto 9 do |num|
      returning builder.calculate_matches_for(num) do |matches_of_num|
        matches_of_num.potential_match_count.should.equal 100
        matches_of_num.exact_match_count.should.equal 1
      end
      returning builder.calculate_matches_for((num * 100) + 5) do |matches_of_num|
        matches_of_num.potential_match_count.should.equal 0
        matches_of_num.exact_match_count.should.equal 1
      end
    end
  end
  
  test "numeric literals that don't match but ultimately would" do
    returning builder do |link|
      link.nineninenine 999
      link.shouldnt_match 4444
    end
    builder.calculate_matches_for(9).potential_match_count.should.equal 1
  end

  test "three fixnums that obviously don't conflict" do
    returning builder do |link|
      link.one   1
      link.two   2
      link.three 3
    end
    [[1,2,3,4,'#'], [1,1,1,0,0]].transpose.each do |(input,expected_matches)|
      matches = builder.calculate_matches_for input
      matches.exact_match_count.should.equal expected_matches
    end
  end
  
  test "numerical digits mixed with special digits" do
    returning builder do |link|
      link.one   '5*11#3'
      link.two   '5***'
      link.three '###'
    end
    
    builder_should_match_with_these_quantities_of_calculated_matches \
      '5'      => { :potential_match_count => 2, :exact_match_count => 0 },
      '*'      => { :potential_match_count => 0, :exact_match_count => 0 },
      '5**'    => { :potential_match_count => 1, :exact_match_count => 0 },
      '5*1'    => { :potential_match_count => 1, :exact_match_count => 0 },
      '5*11#3' => { :potential_match_count => 0, :exact_match_count => 1 },
      '5*11#4' => { :potential_match_count => 0, :exact_match_count => 0 },
      '5***'   => { :potential_match_count => 0, :exact_match_count => 1 },
      '###'    => { :potential_match_count => 0, :exact_match_count => 1 },
      '##*'    => { :potential_match_count => 0, :exact_match_count => 0 }
    
  end
  
  test 'a Fixnum exact match conflicting with a Range that would ultimately match' do
    returning builder do |link|
      link.single_digit 1
      link.range 100..200
    end
    matches = builder.calculate_matches_for 1
    matches.potential_match_count.should.equal 100
  end
  
  test "custom blocks" do
    strange_use_case = %w[321 4321 54321]
    returning builder do |link|
      link.arbitrary? do |str|
        strange_use_case.select { |num| num.reverse.starts_with?(str) }
      end
    end
    
    builder_should_match_with_these_quantities_of_calculated_matches \
      1      => { :exact_match_count => 3 },
      12     => { :exact_match_count => 3 },
      123    => { :exact_match_count => 3 },
      1234   => { :exact_match_count => 2 },
      12345  => { :exact_match_count => 1 },
      123456 => { :exact_match_count => 0 }

  end
  
end

context 'say_digits command' do
  include DialplanCommandTestHelpers
  test 'Can execute the saydigits application using say_digits' do
    digits = "12345"
    pbx_should_respond_with_success
    mock_call.say_digits digits
    pbx_was_asked_to_execute "saydigits", digits
  end
  
  test 'Cannot pass non-integers into say_digits.  Will raise an ArgumentError' do
    the_following_code {
      mock_call.say_digits 'abc'
    }.should.raise(ArgumentError)
    
    the_following_code {
      mock_call.say_digits '1.20'
    }.should.raise(ArgumentError)
  end
  
end

context 'tone command' do
  include DialplanCommandTestHelpers
  
  test 'Supported tone codes are available in a look up table' do
    predefined_tones.keys.map(&:to_s).sort.should.equal(%w(busy dial info record).sort)
  end
  
  test 'Requesting to play a predefined tone plays the correct tone' do
    name, tone = predefined_tones.to_a.first
    pbx_should_respond_with_success
    mock_call.tone name
    pbx_was_asked_to_play_tone tone
  end
  
  test 'Requesting to play a custom tone by passing a raw tone code plays that raw custom tone directly' do
    custom_tone = "3333/33,0/15000"
    pbx_should_respond_with_success
    mock_call.tone custom_tone
    pbx_was_asked_to_play_tone custom_tone
  end
  
  test 'Requesting to play a custom tone by passing in its name plays it by name' do
    custome_tone_name = :constipated
    pbx_should_respond_with_success
    mock_call.tone custome_tone_name
    pbx_was_asked_to_play_tone custome_tone_name
  end
end

context 'get variable command' do
  include DialplanCommandTestHelpers
  
  test "Getting a variable that isn't set returns nothing" do
    pbx_should_respond_with "200 result=0"
    assert !mock_call.get_variable('OMGURFACE')
  end
  
  test 'An empty variable should return an empty String' do
    pbx_should_respond_with_value ""
    mock_call.get_variable('kablamm').should == ""
  end
  
  test "Getting a variable that is set returns its value" do
    unique_id = "1192470850.1"
    pbx_should_respond_with_value unique_id
    variable_value_returned = mock_call.get_variable('UNIQUEID')
    variable_value_returned.should.equal unique_id
  end
end

context "duration_of command" do
  include DialplanCommandTestHelpers
  
  test "Duration of must take a block" do
    the_following_code {
      mock_call.duration_of
    }.should.raise(LocalJumpError)
  end
  
  test "Passed block to duration of is actually executed" do
    the_following_code {
      mock_call.duration_of {
        throw :inside_duration_of
      }
    }.should.throw :inside_duration_of
  end
  
  test "Duration of block is returned" do
    start_time = Time.parse('9:25:00')
    end_time   = Time.parse('9:25:05')
    expected_duration = end_time - start_time
    
    flexmock(Time).should_receive(:now).twice.and_return(start_time, end_time)
    duration = mock_call.duration_of {
      # This doesn't matter
    }
    
    duration.should.equal expected_duration
  end
end

context "Dial command" do
  include DialplanCommandTestHelpers
  
  test "should set the caller id if the callerid option is specified" do
    mock_call.should_receive(:set_caller_id).once
    mock_call.dial 123, :caller_id => "1234678901"
  end
  
  test "should raise an exception when a non-numerical callerid is specified" do
    the_following_code {
      mock_call.dial 911, :caller_id => "zomgz"
    }.should.raise ArgumentError
  end
end

context "set_caller_id command" do
  include DialplanCommandTestHelpers

  test "should encapsulate the number with quotes" do
    caller_id = "14445556666"
    mock_call.should_receive(:raw_response).once.with(%(SET CALLERID "#{caller_id}")).and_return true
    mock_call.send(:set_caller_id, caller_id)
  end
end

context "record command" do
  include DialplanCommandTestHelpers
  
  test "executes the command SpeechEngine gives it based on the engine name" do
    mock_speak_command = "returned command doesn't matter"
    flexmock(Adhearsion::VoIP::Asterisk::Commands::SpeechEngines).should_receive(:cepstral).
      once.and_return(mock_speak_command)
    mock_call.should_receive(:execute).once.with(mock_speak_command)
    mock_call.speak "Spoken text doesn't matter", :cepstral
  end
  
  test "raises an InvalidSpeechEngine exception when the engine is 'none'" do
    the_following_code {
      mock_call.speak("o hai!", :none)
    }.should.raise Adhearsion::VoIP::Asterisk::Commands::SpeechEngines::InvalidSpeechEngine
  end
  
  test "should default its engine to :none" do
    the_following_code {
      flexmock(Adhearsion::VoIP::Asterisk::Commands::SpeechEngines).should_receive(:none).once.
        and_raise(Adhearsion::VoIP::Asterisk::Commands::SpeechEngines::InvalidSpeechEngine)
      mock_call.speak "ruby ruby ruby ruby!"
    }.should.raise Adhearsion::VoIP::Asterisk::Commands::SpeechEngines::InvalidSpeechEngine
  end
  
  test "Properly escapes spoken text" # TODO: What are the escaping needs?
  
end

context 'The join command' do
  
  include DialplanCommandTestHelpers
  
  test "should pass the 'd' flag when no options are given" do
    conference_id = "123"
    mock_call.should_receive(:execute).once.with("MeetMe", conference_id, "d", nil)
    mock_call.join conference_id
  end
  
  test "should pass through any given flags with 'd' appended to it if necessary" do
    conference_id, flags = "1000", "zomgs"
    mock_call.should_receive(:execute).once.with("MeetMe", conference_id, flags + "d", nil)
    mock_call.join conference_id, :options => flags
  end
  
  test "should raise an ArgumentError when the pin is not numerical" do
    the_following_code {
      mock_call.should_receive(:execute).never
      mock_call.join 3333, :pin => "letters are bad, mkay?!1"
    }.should.raise ArgumentError
  end
  
  test "should strip out illegal characters from a conference name" do
    bizarre_conference_name = "a-    bc!d&&e--`"
    normal_conference_name = "abcde"
    mock_call.should_receive(:execute).twice.with("MeetMe", normal_conference_name, "d", nil)
    
    mock_call.join bizarre_conference_name
    mock_call.join normal_conference_name
  end
  
  test "should allow textual conference names" do
    the_following_code {
      mock_call.should_receive(:execute).once.with_any_args
      mock_call.join "david bowie's pants"
    }.should.not.raise
  end
  
end

BEGIN {
  module DialplanCommandTestHelpers
    def self.included(test_case)
      test_case.send(:attr_reader, :mock_call, :input, :output)
      
      test_case.before do
        @input      = MockSocket.new
        @output     = MockSocket.new
        @mock_call  = Object.new
        mock_call.extend(Adhearsion::VoIP::Asterisk::Commands)
        flexmock(mock_call) do |call|
          call.should_receive(:from_pbx).and_return(input)
          call.should_receive(:to_pbx).and_return(output)
        end
      end
    end
    
    class MockSocket

      def print(message)
        messages << message
      end

      def read
        messages.shift
      end

      def gets
        read
      end

      def messages
        @messages ||= []
      end
    end
    
    
    private

      def should_pass_control_to_a_context_that_throws(symbol, &block)
        did_the_rescue_block_get_executed = false
        begin
          block.call
        rescue Adhearsion::VoIP::DSL::Dialplan::ControlPassingException => cpe
          did_the_rescue_block_get_executed = true
          cpe.target.should.throw symbol
        rescue => e
          did_the_rescue_block_get_executed = true
          raise e
        ensure
          did_the_rescue_block_get_executed.should.be true
        end
      end

      def should_throw(sym=nil,&block)
        block.should.throw(*[sym].compact)
      end

      def mock_route_calculation_with(*definitions)
        flexmock(Adhearsion::VoIP::DSL::DialingDSL).should_receive(:calculate_routes_for).and_return(definitions)
      end

      def pbx_should_have_been_sent(message)
        output.gets.should.equal message
      end

      def pbx_should_respond_with(message)
        input.print message
      end

      def pbx_should_respond_with_digits(string_of_digits)
        pbx_should_respond_with "200 result=#{string_of_digits}"
      end

      def pbx_should_respond_with_digits_and_timeout(string_of_digits)
        pbx_should_respond_with "200 result=#{string_of_digits} (timeout)"
      end

      def pbx_should_respond_to_timeout(timeout)
        pbx_should_respond_with "200 result=#{timeout}"
      end
      
      def pbx_should_respond_with_value(value)
        pbx_should_respond_with "200 result=1 (#{value})"
      end
      
      def pbx_should_respond_with_success(success_code = nil)
        pbx_should_respond_with pbx_success_response(success_code)
      end

      def pbx_should_respond_with_failure(failure_code = nil)
        pbx_should_respond_with(pbx_failure_response(failure_code))
      end

      def pbx_should_respond_with_successful_background_response(digit=0)
        pbx_should_respond_with_success digit.kind_of?(String) ? digit[0] : digit
      end
      
      def pbx_should_respond_with_a_wait_for_digit_timeout
        pbx_should_respond_with_successful_background_response 0
      end
      
      def pbx_success_response(success_code = nil)
        "200 result=#{success_code || default_success_code}"
      end

      def default_success_code
        '1'
      end

      def pbx_failure_response(failure_code = nil)
        "200 result=#{failure_code || default_failure_code}"
      end

      def default_failure_code
        '0'
      end

      def output_stream_matches(pattern)
        assert_match(pattern, output.gets)
      end

      module OutputStreamMatchers
        def pbx_was_asked_to_play(*audio_files)
          audio_files.each do |audio_file|
            output_stream_matches(/playback #{audio_file}/)
          end
        end

        def pbx_was_asked_for_input(number_of_digits, options={})
          timeout = options[:timeout]
          timeout = (timeout && timeout != -1) ? (timeout * 1000).to_i : -1
          play    = options[:play] || 'beep'
          output_stream_matches(/GET DATA #{play} #{timeout} #{number_of_digits}/)
        end

        def pbx_was_asked_to_play_number(number)
          output_stream_matches(/saynumber #{number}/)
        end    

        def pbx_was_asked_to_play_time(number)
          output_stream_matches(/sayunixtime #{number}/)
        end

        def pbx_was_asked_to_play_tone(tone)
          output_stream_matches(/PlayTones #{Regexp.escape(tone.to_s)}/)
        end
        
        def pbx_was_asked_to_execute(application, *options)
          output_stream_matches(/exec saydigits #{options.join('|')}/i)
        end
      end
      include OutputStreamMatchers

      def assert_success(response)
        response.should.equal pbx_success_response
      end

      def predefined_tones
        Adhearsion::VoIP::Asterisk::Commands::TONES
      end
  end
  
  
module MenuBuilderTestHelper
  def builder_should_match_with_these_quantities_of_calculated_matches(checks)
    checks.each do |check,hash|
      hash.each_pair do |method_name,intended_quantity|
        message = "There were supposed to be #{intended_quantity} #{method_name.to_s.humanize} calculated."
        builder.calculate_matches_for(check).send(method_name).
          should.messaging(message).equal(intended_quantity)
      end
    end
  end
end
  
module MenuTestHelper
  
  def pbx_should_send_digits(*digits)
    digits.each do |digit|
      digit = nil if digit == :timeout
      mock_call.should_receive(:interruptable_play).once.and_return(digit)
    end
  end
end
  
}