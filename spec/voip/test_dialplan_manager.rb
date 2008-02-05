require File.dirname(__FILE__) + "/../test_helper"
require 'adhearsion/voip/dsl/dialplan/parser'

context "Dialplan::Manager handling" do
  
  include DialplanTestingHelper
  
  attr_accessor :manager, :call, :context_name, :mock_context
  
  before do
    @context_name = :some_context_name
    @mock_context = flexmock('a context')
    
    hack_to_work_around_parser_coupling
    mock_dial_plan_lookup_for_context_name
    flexmock(Adhearsion::DialPlan::Loader).should_receive(:load_dial_plan).and_return{flexmock("loaded contexts", :contexts => nil)}
    @manager = Adhearsion::DialPlan::Manager.new
    @call    = new_call_for_context context_name
    
    # Sanity check context name being set
    call.context.should.equal context_name
  end
  
  test "Given a Call, the manager finds the call's desired entry point/context" do
    manager.entry_point_for(call).should.equal mock_context
  end
  
  test "The manager handles a call by executing the proper context" do
    flexmock(Adhearsion::DialPlan::ExecutionEnvironment).new_instances.should_receive(:run).once  
    manager.handle(call)
  end
  
  test "should raise a NoContextError exception if the targeted context is not found" do
    the_following_code {
      # manager = flexmock Adhearsion::DialPlan::Manager.new
      flexmock(manager).should_receive(:entry_point_for).and_return nil
      manager.handle call
    }.should.raise(Adhearsion::DialPlan::Manager::NoContextError)
  end
  
  private
    def hack_to_work_around_parser_coupling
      flexmock(Adhearsion::Paths).should_receive(:manager_for?).and_return(true)
      flexmock(Adhearsion::VoIP::DSL::Dialplan::DialplanParser).should_receive(:all_dialplans).and_return([])
    end
    
    def mock_dial_plan_lookup_for_context_name
      flexmock(Adhearsion::DialPlan).new_instances.should_receive(:lookup).with(context_name).and_return(mock_context)
    end
end

context "DialPlan" do
  
  attr_accessor :loader, :loader_instance, :dial_plan
  
  before do
    @loader = Adhearsion::DialPlan::Loader
    @loader_instance = @loader.new
    flexmock(Adhearsion::DialPlan::Loader).should_receive(:load_dial_plan).once.and_return(@loader_instance)
    @dial_plan   = Adhearsion::DialPlan.new(Adhearsion::DialPlan::Loader)
  end
  
  test "When a dial plan is instantiated, the dialplans are loaded and stored for lookup" do
    dial_plan.instance_variable_get("@entry_points").should.not.be.nil
  end
  
  test "Can look up an entry point from a dial plan" do
    context_name = 'this_context_is_better_than_your_context'
    loader_instance.contexts[context_name] = lambda { puts "o hai" }
    dial_plan.lookup(context_name).should.not.be.nil
  end
end

context "DialPlan loader" do
  
  include DialplanTestingHelper
  
  test "loading a single context" do
    loader = load(<<-DIAL_PLAN)
      one {
        raise 'this block should not be evaluated'
      }
    DIAL_PLAN
    
    loader.contexts.keys.size.should.equal 1
    loader.contexts.keys.first.should.equal :one
  end
  
  test "loading multiple contexts loads all contexts" do
    loader = load(<<-DIAL_PLAN)
      one {
        raise 'this block should not be evaluated'
      }
      
      two {
        raise 'this other block should not be evaluated either'
      }
    DIAL_PLAN
    
    loader.contexts.keys.size.should.equal 2
    loader.contexts.keys.map(&:to_s).sort.should.equal %w(one two)
  end
  
  test "loading a dial plan from a file" do
    loader = nil
    # The assumption is that only the "dial_plan.rb" file will be loaded from fixtures/dial_plans
    the_following_code {
      AHN_ROOT.using_base_path(File.expand_path(File.dirname(__FILE__) + '/../fixtures')) do
        loader = Adhearsion::DialPlan::Loader.load_dial_plan
      end
    }.should.not.raise
    
    loader.contexts.keys.size.should.equal 1
    loader.contexts.keys.first.should.equal :sample_context
  end
  
end

context "ExecutionEnvironemnt" do
  attr_accessor :call, :entry_point
  
  include DialplanTestingHelper

  before do
    variables = { :context => "zomgzlols", :caller_id => "Ponce de Leon" }
    @call = Adhearsion::Call.new(nil, variables)
    @entry_point = lambda {}
  end
  
  test "On initialization, ExecutionEnvironments extend themselves with behavior specific to the voip platform which originated the call" do
    Adhearsion::DialPlan::ExecutionEnvironment.included_modules.should.not.include(Adhearsion::VoIP::Asterisk::Commands)
    execution_environent = Adhearsion::DialPlan::ExecutionEnvironment.new(call, entry_point)
    execution_environent.metaclass.included_modules.should.include(Adhearsion::VoIP::Asterisk::Commands)
  end
  
  test "An executed context should raise a NameError error when a missing constant is referenced" do
    the_following_code do
      call = new_call_for_context :context_with_missing_constant
      mock_dialplan_with "context_with_missing_constant { ThisConstantDoesntExist }"
      manager = new_manager_with_entry_points_loaded_from_dialplan_contexts
      manager.handle call
    end.should.raise NameError
    
  end
  
  test "should define variables accessors within itself" do
    environment = Adhearsion::DialPlan::ExecutionEnvironment.new(@call, entry_point)
    call.variables.should.not.be.empty
    call.variables.each do |key, value|
      environment.send(key).should.equal value
    end
  end
  
  test "should define accessors for other contexts in the dialplan" do
    call = new_call_for_context :am_not_for_kokoa!
    bogus_dialplan = <<-DIALPLAN
      am_not_for_kokoa! {}
      icanhascheezburger? {}
      these_context_names_do_not_really_matter {}
    DIALPLAN
    
    mock_dialplan_with bogus_dialplan
    manager = Adhearsion::DialPlan::Manager.new
    manager.dial_plan.entry_points = manager.dial_plan.loader.load_dial_plan.contexts
    manager.dial_plan.entry_points.should.not.be.empty
    
    manager.handle call
    
    %w(these_context_names_do_not_really_matter icanhascheezburger? am_not_for_kokoa!).each do |context_name|
      manager.context.respond_to?(context_name).should.equal true
    end
  end
  
end

context "Dialplan control statements" do
  
  include DialplanTestingHelper
  
  test "Manager should catch ControlPassingExceptions" do
    dialplan = %{
      foo { raise Adhearsion::VoIP::DSL::Dialplan::ControlPassingException.new(bar) }
      bar {}
    }
    executing_dialplan(:foo => dialplan).should.not.raise
  end
  
  test "Proc#+@ should not return to its originating context" do
    dialplan = %{
      andere {}
      zuerst {
        +andere
        throw :after_control_statement
      }
    }
    executing_dialplan(:zuerst => dialplan).should.not.throw
  end
  test "All dialplan contexts should be available at context execution time" do
    dialplan = %{
      context_defined_first {
        throw :i_see_it if context_defined_second
      }
      context_defined_second {}
    }
    executing_dialplan(:context_defined_first => dialplan).should.throw :i_see_it
  end
  test "Proc#+@ should execute the other context" do
    dialplan = %{
      eins {
        +zwei
        throw :eins
      }
      zwei {
        throw :zwei
      }
    }
    executing_dialplan(:eins => dialplan).should.throw :zwei
  end
end

context "VoIP platform operations" do
  test "can map a platform name to a module which holds its platform-specific operations" do
    Adhearsion::VoIP::Commands.for(:asterisk).should == Adhearsion::VoIP::Asterisk::Commands
  end
end

BEGIN {
module DialplanTestingHelper
  def load(dial_plan_as_string)
    Adhearsion::DialPlan::Loader.load(dial_plan_as_string)
  end
  
  def mock_dialplan_with(string)
    flexmock(Adhearsion::DialPlan::Loader).should_receive(:read_dialplan_file).
        at_least.once.and_return(string)
  end
  
  def new_manager_with_entry_points_loaded_from_dialplan_contexts
    returning Adhearsion::DialPlan::Manager.new do |manager|
      manager.dial_plan.entry_points = manager.dial_plan.loader.load_dial_plan.contexts
    end
  end
  
  def executing_dialplan(options)
    context_name = options.keys.first
    dialplan     = options[context_name]
    
    mock_dialplan_with dialplan
    lambda do
      Adhearsion::DialPlan::Manager.new.handle new_call_for_context(context_name)
    end
  end
  
  def new_call_for_context(context)
    Adhearsion::Call.new(StringIO.new, :context => context)
  end
end
}
