require File.dirname(__FILE__) + "/../../test_helper"
require 'adhearsion/voip/asterisk'

context "The AGI server's serve() method" do
  
  include AgiServerTestHelper
  
  attr_reader :server_class, :server
  before :each do
    @server_class = Adhearsion::VoIP::Asterisk::AGI::Server::RubyServer
    @server       = @server_class.new(:port,:host)
  end
  
  test 'should instantiate a new Call with the IO object it receives' do
    stub_before_call_hooks!
    io_mock   = flexmock "Mock IO object that's passed to the serve() method"
    call_mock = flexmock "A Call mock that's returned by Adhearsion#receive_call_from", :variable => {}
    flexstub(server_class).should_receive(:ahn_log)
    the_following_code {
      flexmock(Adhearsion).should_receive(:receive_call_from).once.with(io_mock).and_throw :created_call!
      server.serve(io_mock)
    }.should.throw :created_call!
  end
  
  test 'should hand the call off to a new Manager if the request is agi://IP_ADDRESS_HERE' do
    stub_before_call_hooks!
    call_mock = flexmock 'A new mock call that will be passed to the manager', :variables => {}
    
    flexmock(Adhearsion).should_receive(:receive_call_from).once.and_return call_mock
    manager_mock = flexmock 'a mock dialplan manager'
    manager_mock.should_receive(:handle).once.with(call_mock)
    flexmock(Adhearsion::DialPlan::Manager).should_receive(:new).once.and_return manager_mock
    server.serve(nil)
  end
  
  test 'should hand off a call to a ConfirmationManager if the request begins with confirm!' do
    confirm_options = Adhearsion::DialPlan::ConfirmationManager.encode_hash_for_dial_macro_argument :timeout => 20, :key => "#"
    call_mock = flexmock "a call that has network_script as a variable", :variables => {:network_script => "confirm!#{confirm_options[/^M\(\^?(.+)\)$/,1]}"}
    manager_mock = flexmock 'a mock ConfirmationManager'
    
    the_following_code {
      flexstub(Adhearsion).should_receive(:receive_call_from).once.and_return(call_mock)
      flexmock(Adhearsion::DialPlan::ConfirmationManager).should_receive(:confirmation_call?).once.with(call_mock).and_return true
      flexmock(Adhearsion::DialPlan::ConfirmationManager).should_receive(:handle).once.with(call_mock).and_throw :handled_call!
      server.serve(nil)
    }.should.throw :handled_call!
  end
  
  test 'calling the serve() method invokes any BeforeCall hooks' do
    flexmock(Adhearsion::Hooks::BeforeCall).should_receive(:trigger_hooks).once.and_throw :before_call_hooks_executed
    assert_throws :before_call_hooks_executed do
      server.serve nil
    end
  end
  
  test 'should execute the OnHungupCall hooks when a HungupExtensionCallException is raised' do
    call_mock = flexmock 'a bogus call', :hungup_call? => true, :variables => {:extension => "h"}
    mock_env  = flexmock "A mock execution environment which gets passed along in the HungupExtensionCallException"
    
    stub_confirmation_manager!
    flexstub(Adhearsion).should_receive(:receive_call_from).once.and_return(call_mock)
    flexmock(Adhearsion::DialPlan::Manager).should_receive(:handle).once.and_raise Adhearsion::HungupExtensionCallException.new(mock_env)
    flexmock(Adhearsion::Hooks::OnHungupCall).should_receive(:trigger_hooks).once.with(mock_env).and_throw :hungup_call
    
    the_following_code { server.serve nil }.should.throw :hungup_call
  end
  
  test 'should execute the OnFailedCall hooks when a FailedExtensionCallException is raised' do
    call_mock = flexmock 'a bogus call', :failed_call? => true, :variables => {:extension => "failed"}
    mock_env  = flexmock "A mock execution environment which gets passed along in the HungupExtensionCallException", :failed_reason => "does not matter" 
    
    server = Adhearsion::VoIP::Asterisk::AGI::Server::RubyServer.new :port, :host
    
    flexmock(Adhearsion).should_receive(:receive_call_from).once.and_return(call_mock)
    flexmock(Adhearsion::DialPlan::Manager).should_receive(:handle).once.and_raise Adhearsion::FailedExtensionCallException.new(mock_env)
    flexmock(Adhearsion::Hooks::OnFailedCall).should_receive(:trigger_hooks).once.with(mock_env).and_throw :failed_call
    the_following_code { server.serve nil }.should.throw :failed_call
  end
  
end

context "Active Calls" do
  include CallVariableTestHelper
  attr_accessor :typical_call
  
  before do
    @mock_io      = StringIO.new
    @typical_call = Adhearsion::Call.new(@mock_io, typical_call_variables_hash)
  end
  
  after do
    Adhearsion::active_calls.clear!
  end
  
  test 'A Call object can be instantiated with a hash of attributes' do
    the_following_code {
      Adhearsion::Call.new(@mock_io, {})
    }.should.not.raise
  end
  
  test 'Attributes passed into initialization of call object are accessible as attributes on the object' do
    Adhearsion::Call.new(@mock_io, {:channel => typical_call_variables_hash[:channel]}).channel.should == typical_call_variables_hash[:channel]
  end
  
  test 'Attributes passed into initialization of call object are accessible in the variables() Hash' do
    Adhearsion::Call.new(@mock_io, typical_call_variables_hash).variables.should.equal typical_call_variables_hash
  end
  
  test 'Can add a call to the active calls list' do
    Adhearsion.active_calls.should.not.be.any
    Adhearsion.active_calls << typical_call 
    Adhearsion.active_calls.size.should == 1
  end
  
  test 'A hungup call removes itself from the active calls' do
    mock_io = flexmock typical_call_variable_io
    mock_io.should_receive(:close).once
    
    size_before = Adhearsion.active_calls.size
    
    call = Adhearsion.receive_call_from mock_io
    Adhearsion.active_calls.size.should.be > size_before
    call.hangup!
    Adhearsion.active_calls.size.should == size_before
  end
  
  test 'Can find active call by unique ID' do
    Adhearsion.active_calls << typical_call
    assert_not_nil Adhearsion.active_calls.find_by_unique_id(typical_call_variables_hash[:uniqueid])
  end
  
  test 'A call can store the IO associated with the PBX/switch connection' do
    Adhearsion::Call.new(@mock_io, {}).should.respond_to(:io)
  end
  
  test 'A call can be instantiated given a PBX/switch IO' do
    call = Adhearsion::Call.receive_from(typical_call_variable_io)
    call.should.be.kind_of(Adhearsion::Call)
    call.channel.should == typical_call_variables_hash[:channel]
  end
  
  test 'A call with an extension of "t" raises a UselessCallException' do
    the_following_code {
      Adhearsion::Call.new(@mock_io, typical_call_variables_hash.merge(:extension => 't'))
    }.should.raise(Adhearsion::UselessCallException)
  end
  
  test 'Can create a call and add it via a top-level method on the Adhearsion module' do
    assert !Adhearsion.active_calls.any?
    call = Adhearsion.receive_call_from(typical_call_variable_io)
    call.should.be.kind_of(Adhearsion::Call)
    Adhearsion.active_calls.size.should == 1
  end
  
  test 'A call can identify its originating voip platform' do
    call = Adhearsion::receive_call_from(typical_call_variable_io)
    call.originating_voip_platform.should.equal(:asterisk)
  end
  
end

context 'A new Call object' do
  
  include CallVariableTestHelper
  
  test "it should have an @inbox object that's a synchronized Queue" do
    new_call = Adhearsion::Call.new(nil, {})
    new_call.inbox.should.be.kind_of Queue
    new_call.should.respond_to :<<
  end
  
  test 'the unique_identifier() method should return the "uniqueid" variable for :asterisk calls' do
    variables = typical_call_variables_hash
    new_call = Adhearsion::Call.new(nil, typical_call_variables_hash)
    flexmock(new_call).should_receive(:originating_voip_platform).and_return :asterisk
    new_call.unique_identifier.should == variables[:uniqueid]
  end
  
  test "Call#define_singleton_accessor_with_pair should define a singleton method, not a class method" do
    control    = Adhearsion::Call.new(nil, {})
    experiment = Adhearsion::Call.new(nil, {})
    
    experiment.send(:define_singleton_accessor_with_pair, "ohai", 123)
    experiment.should.respond_to "ohai"
    control.should.not.respond_to "ohai"
  end
  
end

context 'the Calls collection' do
  test 'the #<< method should add a Call to the Hash with its unique_id' do
    id = rand
    collection = Adhearsion::Calls.new
    call = Adhearsion::Call.new(nil, {})
    flexmock(call).should_receive(:unique_identifier).and_return id
    collection << call
    hash = collection.instance_variable_get("@calls")
    hash.should.not.be.empty
    hash[id].should.equal call
  end
  
  test '#size should return the size of the Hash' do
    collection = Adhearsion::Calls.new
    collection.size.should.equal 0
    collection << Adhearsion::Call.new(nil, {})
    collection.size.should.equal 1
  end
  
  test '#remove_inactive_call should delete the call in the Hash' do
    collection = Adhearsion::Calls.new
    
    number_of_calls = 10
    unique_ids = Array.new(number_of_calls) { rand }
    calls = unique_ids.map { |id| Adhearsion::Call.new(nil, {:uniqueid => id}) }
    calls.each { |call| collection << call }
    
    deleted_call = calls[number_of_calls / 2]
    collection.remove_inactive_call deleted_call
    collection.size.should.equal number_of_calls - 1
  end
  
  test '#find_by_unique_id should pull the Call from the Hash using the unique_id' do
    id = rand
    call_database = flexmock "a mock Hash in which calls are stored"
    call_database.should_receive(:[]).once.with(id)
    collection = Adhearsion::Calls.new
    flexmock(collection).should_receive(:calls).once.and_return(call_database)
    collection.find_by_unique_id(id)
  end
  
end

context 'Typical call variable parsing with typical data that has no special treatment' do
  include CallVariableTestHelper
  attr_reader :variables, :io              
              
  setup do
    @io        = typical_call_variable_io
    @variables = parsed_call_variables_from(io)
  end
  
  # test "listing all variable names" do
  #   parser.variable_names.map(&:to_s).sort.should == typical_call_variables_hash.keys.map(&:to_s).sort
  # end
  
  test "extracts call variables into a Hash" do
    assert variables.kind_of?(Hash)
  end
  
  test "extracting and converting variables and their values to a hash" do
    variables.should == typical_call_variables_hash
  end
end

context 'Call variable parsing with data that is treated specially' do
  include CallVariableTestHelper
  test "callington is renamed to type_of_calling_number" do
    variables = parsed_call_variables_from typical_call_variable_io
    variables[:type_of_calling_number].should == :unknown
    variables.has_key?(:callington).should    == false
  end
  test "normalizes the context to be a valid Ruby method name"
  test "value of 'no' converts to false" do
    merged_hash_with_call_variables(:foo => "no")[:foo].should.equal(false)
  end
  test "value of 'yes' converts to true"
  test "value of 'unknown' converts to nil"
  test 'separate_line_into_key_value_pair parses values with spaces in them' do
    key, value = Adhearsion::Call::Variables::Parser.separate_line_into_key_value_pair("foo: My Name")
    value.should == 'My Name'
  end
end

context 'Typical call variable line parsing with a typical line that is not treated specially' do
  include CallVariableTestHelper
  attr_reader :parser, :line
  
  setup do
    @line   = 'agi_channel: SIP/marcel-b58046e0'
    @key, @value = Adhearsion::Call::Variables::Parser.separate_line_into_key_value_pair line
  end
  
  test "raw name is extracted correctly" do
    @key.should == 'agi_channel'
  end
  
  test "raw value is extracted correctly" do
    @value.should == 'SIP/marcel-b58046e0'
  end
end

context 'Call variable line parsing with a line that is treated specially' do
  include CallVariableTestHelper
  attr_reader :key, :value, :line
  
  setup do
    @line   = 'agi_request: agi://10.0.0.152'
    @key, @value = Adhearsion::Call::Variables::Parser.separate_line_into_key_value_pair line
  end
  
  test "splits out name and value correctly even if the value contains a semicolon (i.e. the same character that is used as the name/value separators)" do
    @key.should   == 'agi_request'
    @value.should == 'agi://10.0.0.152'
  end
  
end

context "Extracting the query from the request URI" do
  include CallVariableTestHelper
  attr_reader :parser
  
  setup do
    # We don't want this Call::Variables::Parser to call parse because we only care about handling the request
    # variable which we mock here.
    @parser = Adhearsion::Call::Variables::Parser.new(StringIO.new('This argument does not matter'))
  end
  
  test "an empty hash is returned if there is no query string" do
    parsed_call_variables_with_query('').should == {}
  end
  
  test "a key and value for parameter is returned when there is one query string parameter" do
    parsed_call_variables_with_query('?foo=bar').should == {'foo' => 'bar'}
  end
  
  test "both key/value pairs are returned when there are a pair of query string parameters" do
    parsed_call_variables_with_query('?foo=bar&baz=quux').should == {'foo' => 'bar', 'baz' => 'quux'}
  end
  
  test "all key/value pairs are returned when there are more than a pair of query string parameters" do
    parsed_call_variables_with_query('?foo=bar&baz=quux&name=marcel').should == {'foo' => 'bar', 'baz' => 'quux', 'name' => 'marcel'}
  end
  
end

BEGIN {
  module CallVariableTestHelper
    def parsed_call_variables_from(io)
      Adhearsion::Call::Variables::Parser.parse(io).variables
    end
  
    def coerce_call_variables(variables)
      Adhearsion::Call::Variables::Parser.coerce_variables(variables)
    end
    
    def merged_hash_with_call_variables(new_hash)
      call_variables_with_new_query = typical_call_variables_hash.merge new_hash
      coerce_call_variables call_variables_with_new_query
    end
    
    def parsed_call_variables_with_query(query_string)  
      request_string = "agi://10.0.0.0/#{query_string}"
      merged_hash_with_call_variables({:request => request_string})[:query]
    end
    
    def typical_call_variable_io
      StringIO.new(typical_call_variable_section)
    end

    def typical_call_variable_section
      <<-VARIABLES
agi_network: yes
agi_request: agi://10.0.0.152/monkey?foo=bar&qaz=qwerty
agi_channel: SIP/marcel-b58046e0
agi_language: en
agi_type: SIP
agi_uniqueid: 1191245124.16
agi_callerid: 011441234567899
agi_calleridname: unknown
agi_callingpres: 0
agi_callingani2: 0
agi_callington: 0
agi_callingtns: 0
agi_dnid: 911
agi_rdnis: unknown
agi_context: adhearsion
agi_extension: 911
agi_priority: 1
agi_enhanced: 0.0
agi_accountcode: 

      VARIABLES
    end

    # TODO:
    #  - "unknown" should be converted to nil
    #  - "yes" or "no" should be converted to true or false
    #  - numbers beginning with a 0 MUST be converted to a NumericalString
    #  - Look up why there are so many zeroes. They're likely reprentative of some PRI definition.

    def typical_call_variables_hash
      uncoerced_variable_map                = expected_uncoerced_variable_map

      uncoerced_variable_map[:request]      = URI.parse(uncoerced_variable_map[:request])
      uncoerced_variable_map[:extension]    = 911 # Adhearsion::VoIP::DSL::PhoneNumber.new(uncoerced_variable_map[:extension]) # 
      uncoerced_variable_map[:callerid]     = Adhearsion::VoIP::DSL::NumericalString.new(uncoerced_variable_map[:callerid])
      
      uncoerced_variable_map[:network]      = true
      uncoerced_variable_map[:calleridname] = nil
      uncoerced_variable_map[:callingpres]  = 0
      uncoerced_variable_map[:callingani2]  = 0
      uncoerced_variable_map[:callingtns]   = 0
      uncoerced_variable_map[:dnid]         = 911
      uncoerced_variable_map[:rdnis]        = nil
      uncoerced_variable_map[:priority]     = 1
      uncoerced_variable_map[:enhanced]     = 0.0
      uncoerced_variable_map[:uniqueid]     = 1191245124.16
      
      uncoerced_variable_map[:type_of_calling_number] = Adhearsion::VoIP::Constants::Q931_TYPE_OF_NUMBER[uncoerced_variable_map.delete(:callington).to_i]

      coerced_variable_map = uncoerced_variable_map
      coerced_variable_map[:query] = {"foo" => "bar", "qaz" => "qwerty"}
      coerced_variable_map
    end

    def expected_uncoerced_variable_map
      {:network      => 'yes',
       :request      => 'agi://10.0.0.152/monkey?foo=bar&qaz=qwerty',
       :channel      => 'SIP/marcel-b58046e0',
       :language     => 'en',
       :type         => 'SIP',
       :uniqueid     => '1191245124.16',
       :callerid     => '011441234567899',
       :calleridname => 'unknown',
       :callingpres  => '0',
       :callingani2  => '0',
       :callington   => '0',
       :callingtns   => '0',
       :dnid         => '911',
       :rdnis        => 'unknown',
       :context      => 'adhearsion',
       :extension    => '911',
       :priority     => '1',
       :enhanced     => '0.0',
       :accountcode  => ''}
    end
  end
  
  module AgiServerTestHelper
    def stub_before_call_hooks!
      flexstub(Adhearsion::Hooks::BeforeCall).should_receive :trigger_hooks
    end
    
    def stub_confirmation_manager!
      flexstub(Adhearsion::DialPlan::ConfirmationManager).should_receive(:confirmation_call?).and_return false
    end
  end
}
