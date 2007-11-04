require File.dirname(__FILE__) + '/../../test_helper'

require 'adhearsion/voip/dsl/dialplan/parser'

describe "The Adhearsion VoIP dialplan parser" do
  
  test "should return a list of dialplans properly from dialplan code" do
    file = "foobar.rb"
    flexmock(Adhearsion::Paths).should_receive(:manager_for?).and_return true
    flexmock(Adhearsion::VoIP::DSL::Dialplan::DialplanParser).
      should_receive(:all_dialplans).and_return [file]
      
    flexmock(File).should_receive(:exists?).with(file).and_return true
    flexmock(File).should_receive(:read).once.with(file).and_return <<-DIALPLAN
      internal {
        play "hello-world"
      }
      monkeys {
        play "tt-monkeys"
      }
    DIALPLAN
    contexts = Adhearsion::VoIP::DSL::Dialplan::DialplanParser.get_contexts
    contexts.keys.size.should.equal(2)
    contexts.keys.should.include(:internal)
    contexts.keys.should.include(:monkeys)
    contexts.each_pair do |context, struct|
      struct.should.be.kind_of(OpenStruct)
      %w"file name block".each do |method|
        struct.should.respond_to(method)
      end
    end
  end
  
  test "should raise an error when no dialplan paths were in the .ahnrc file" do
    lambda do
      # Not loading it here is the same as it not existing in the "paths" sub-Hash
      Adhearsion::Paths.manager_for?("dialplans").once.and_return false
      Adhearsion::VoIP::DSL::Dialplan::DialplanParser.get_contexts
    end.should.raise NoMethodError
  end
  
  test "should warn() when no dialplan files exist but return an empty Hash" #do
  #   Adhearsion::Paths.should_receive(:manager_for?).with("dialplans").and_return true
  #   Adhearsion::Paths.
  #   Adhearsion::Logging::LoggingMethods.should_receive(:warn)
  #   
  # end
  
  test "should warn() when no contexts were found but return an empty Hash" do
    
  end
  
end

describe "The Adhearsion VoIP dialplan interpreter" do
  
  test "should make dialplan contexts available within the context's block" do    
    file = "contexts_from_code_helper_pseudo_dialplan.rb"
    flexmock(Adhearsion::Paths).should_receive(:manager_for?).once.with("dialplans").and_return true
    flexmock(Adhearsion::VoIP::DSL::Dialplan::DialplanParser).
      should_receive(:all_dialplans).and_return [file]
        
    flexmock(File).should_receive(:exists?).with(file).and_return true
    flexmock(File).should_receive(:read).with(file).and_return "foo { cool_method }"
    
    contexts = Adhearsion::VoIP::DSL::Dialplan::DialplanParser.get_contexts
    
    contexts.each_pair do |name, struct|
      contexts.meta_def(name) { struct.code }
    end
    
    # Simulate incoming request
    contexts = contexts.clone
    
    call_variables = { "callerid" => "14445556666", "context"  => "foo" }
    
    call_variables.each_pair do |key, value|
      contexts.meta_def(key) { value }
      contexts.instance_variable_set "@#{key}", value
    end
    
    # TODO
    # dispatcher = DSL::Dialplan::CommandDispatcher.new 
    
  end
  
end
