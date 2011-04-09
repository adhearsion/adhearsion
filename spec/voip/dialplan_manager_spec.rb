require 'spec_helper'
require 'adhearsion/voip/dsl/dialplan/parser'

module DialplanTestingHelper

  def load(dial_plan_as_string)
    Adhearsion::DialPlan::Loader.load(dial_plan_as_string)
  end

  def mock_dialplan_with(string)
    string_io = StringIO.new(string)
    def string_io.path
      "dialplan.rb"
    end
    flexstub(Adhearsion::AHN_CONFIG).should_receive(:files_from_setting).with("paths", "dialplan").and_return ["dialplan.rb"]
    flexstub(File).should_receive(:new).with("dialplan.rb").and_return string_io
    flexstub(File).should_receive(:read).with('dialplan.rb').and_return string
  end

  def new_manager_with_entry_points_loaded_from_dialplan_contexts
    Adhearsion::DialPlan::Manager.new.tap do |manager|
      manager.dial_plan.entry_points = manager.dial_plan.loader.load_dialplans.contexts
    end
  end

  def executing_dialplan(options)
    call         = options.delete(:call)
    context_name = options.keys.first
    dialplan     = options[context_name]
    call       ||= new_call_for_context context_name

    mock_dialplan_with dialplan

    lambda do
      Adhearsion::DialPlan::Manager.new.handle call
    end
  end

  def new_call_for_context(context)
    Adhearsion::Call.new(StringIO.new, :context => context)
  end
end

describe "Dialplan::Manager handling" do

  include DialplanTestingHelper

  attr_accessor :manager, :call, :context_name, :mock_context

  before :each do
    @context_name = :some_context_name
    @mock_context = flexmock('a context')

    mock_dial_plan_lookup_for_context_name

    flexmock(Adhearsion::DialPlan::Loader).should_receive(:load_dialplans).and_return {
      flexmock("loaded contexts", :contexts => nil)
    }
    @manager = Adhearsion::DialPlan::Manager.new
    @call    = new_call_for_context context_name

    # Sanity check context name being set
    call.context.should be context_name
  end

  it "Given a Call, the manager finds the call's desired entry point based on the originating context" do
    manager.entry_point_for(call).should be mock_context
  end

  it "The manager handles a call by executing the proper context" do
    flexmock(Adhearsion::DialPlan::ExecutionEnvironment).new_instances.should_receive(:run).once
    manager.handle(call)
  end

  it "should raise a NoContextError exception if the targeted context is not found" do
    the_following_code {
      flexmock(manager).should_receive(:entry_point_for).and_return nil
      manager.handle call
    }.should raise_error(Adhearsion::DialPlan::Manager::NoContextError)
  end

  it 'should send :answer to the execution environment if Adhearsion::AHN_CONFIG.automatically_answer_incoming_calls is set' do
    flexmock(Adhearsion::DialPlan::ExecutionEnvironment).new_instances.should_receive(:answer).once.and_throw :answered_call!
    Adhearsion::Configuration.configure do |config|
      config.automatically_answer_incoming_calls = true
    end
    the_following_code {
      manager.handle call
    }.should throw_symbol :answered_call!
  end

  it 'should NOT send :answer to the execution environment if Adhearsion::AHN_CONFIG.automatically_answer_incoming_calls is NOT set' do
    Adhearsion::Configuration.configure do |config|
      config.automatically_answer_incoming_calls = false
    end

    entry_point = Adhearsion::DialPlan::DialplanContextProc.new(:does_not_matter) { "Do nothing" }
    flexmock(manager).should_receive(:entry_point_for).once.with(call).and_return(entry_point)

    execution_env = Adhearsion::DialPlan::ExecutionEnvironment.create(call, nil)
    flexmock(execution_env).should_receive(:entry_point).and_return entry_point
    flexmock(execution_env).should_receive(:answer).never

    flexmock(Adhearsion::DialPlan::ExecutionEnvironment).should_receive(:new).once.and_return execution_env

    Adhearsion::Configuration.configure
    manager.handle call
  end

  private

  def mock_dial_plan_lookup_for_context_name
    flexstub(Adhearsion::DialPlan).new_instances.should_receive(:lookup).with(context_name).and_return(mock_context)
  end

end

describe "DialPlan::Manager's handling a failed call" do

  include DialplanTestingHelper

  it 'should check if the call has failed and then instruct it to extract the reason from the environment' do
    flexmock(Adhearsion::DialPlan::ExecutionEnvironment).new_instances.should_receive(:variable).with("REASON").once.and_return '3'
    call = Adhearsion::Call.new(nil, {'extension' => "failed"})
    call.failed_call?.should be true
    flexmock(Adhearsion::DialPlan).should_receive(:new).once.and_return flexmock("bogus DialPlan which should never be used")
    begin
      Adhearsion::DialPlan::Manager.handle(call)
    rescue Adhearsion::FailedExtensionCallException => error
      error.call.failed_reason.should == Adhearsion::Call::ASTERISK_FRAME_STATES[3]
    end
  end
end

describe "Call tagging" do

  include DialplanTestingHelper

  after :all do
    Adhearsion.active_calls.clear!
  end

  it 'tagging a call with a single Symbol' do
    the_following_code {
      call = new_call_for_context "roflcopter"
      call.tag :moderator
    }.should_not raise_error
  end

  it 'tagging a call with multiple Symbols' do
    the_following_code {
      call = new_call_for_context "roflcopter"
      call.tag :moderator
      call.tag :female
    }.should_not raise_error
  end

  it 'Call#tagged_with? with one tag' do
    call = new_call_for_context "roflcopter"
    call.tag :guest
    call.tagged_with?(:guest).should be true
    call.tagged_with?(:authorized).should be false
  end

  it "Call#remove_tag" do
    call = new_call_for_context "roflcopter"
    call.tag :moderator
    call.tag :female
    call.remove_tag :female
    call.tag :male
    call.tags.should == [:moderator, :male]
  end

  it 'Call#tagged_with? with many tags' do
    call = new_call_for_context "roflcopter"
    call.tag :customer
    call.tag :authorized
    call.tagged_with?(:customer).should be true
    call.tagged_with?(:authorized).should be true
  end

  it 'tagging a call with a non-Symbol, non-String object' do
    bad_objects = [123, Object.new, 888.88, nil, true, false, StringIO.new]
    bad_objects.each do |bad_object|
      the_following_code {
        new_call_for_context("roflcopter").tag bad_object
      }.should raise_error ArgumentError
    end
  end

  it "finding calls by a tag" do
    Adhearsion.active_calls.clear!

    calls = Array.new(5) { new_call_for_context "roflcopter" }
    calls.each { |call| Adhearsion.active_calls << call }

    tagged_call = calls.last
    tagged_call.tag :moderator

    Adhearsion.active_calls.with_tag(:moderator).should == [tagged_call]
  end

end

describe "DialPlan::Manager's handling a hungup call" do

  include DialplanTestingHelper

  it 'should check if the call was a hangup meta-AGI call and then raise a HangupExtensionCallException' do
    call = Adhearsion::Call.new(nil, {'extension' => "h"})
    call.hungup_call?.should be true
    flexmock(Adhearsion::DialPlan).should_receive(:new).once.and_return flexmock("bogus DialPlan which should never be used")
    the_following_code {
      Adhearsion::DialPlan::Manager.handle(call)
    }.should raise_error Adhearsion::HungupExtensionCallException
  end

end

describe "DialPlan" do

  attr_accessor :loader, :loader_instance, :dial_plan

  before do
    @loader = Adhearsion::DialPlan::Loader
    @loader_instance = @loader.new
    flexmock(Adhearsion::DialPlan::Loader).should_receive(:load_dialplans).once.and_return(@loader_instance)
    @dial_plan = Adhearsion::DialPlan.new(@loader)
  end

  it "When a dial plan is instantiated, the dialplans are loaded and stored for lookup" do
    dial_plan.instance_variable_get("@entry_points").should_not be nil
  end

  it "Can look up an entry point from a dial plan" do
    context_name = 'this_context_is_better_than_your_context'
    loader_instance.contexts[context_name] = lambda { puts "o hai" }
    dial_plan.lookup(context_name).should_not be nil
  end
end

describe "DialPlan loader" do

  include DialplanTestingHelper

  it "loading a single context" do
    loader = load(<<-DIAL_PLAN)
      one {
        raise 'this block should not be evaluated'
      }
    DIAL_PLAN

    loader.contexts.keys.size.should be 1
    loader.contexts.keys.first.should be :one
  end

  it "loading multiple contexts loads all contexts" do
    loader = load(<<-DIAL_PLAN)
      one {
        raise 'this block should not be evaluated'
      }

      two {
        raise 'this other block should not be evaluated either'
      }
    DIAL_PLAN

    loader.contexts.keys.size.should be 2
    loader.contexts.keys.map(&:to_s).sort.should == %w(one two)
  end

  it 'loading a dialplan with a syntax error' do
    the_following_code {
      load "foo { &@(*!&(*@*!@^!^%@%^! }"
    }.should raise_error SyntaxError
  end

  it "loading a dial plan from a file" do
    loader = nil
    Adhearsion::AHN_CONFIG.ahnrc = {"paths" => {"dialplan" => "dialplan.rb"}}
    the_following_code {
      AHN_ROOT.using_base_path(File.expand_path(File.dirname(__FILE__) + '/../fixtures')) do
        loader = Adhearsion::DialPlan::Loader.load_dialplans
      end
    }.should_not raise_error

    loader.contexts.keys.size.should be 1
    loader.contexts.keys.first.should be :sample_context
  end

end

describe "The inbox-related dialplan methods" do

  include DialplanTestingHelper

  it "with_next_message should execute its block with the message from the inbox" do
    mock_call = new_call_for_context :entrance
    [:one, :two, :three].each { |message| mock_call.inbox << message }

    dialplan = %{ entrance {  with_next_message { |message| throw message } } }
    executing_dialplan(:entrance => dialplan, :call => mock_call).should throw_symbol :one
  end

  it "messages_waiting? should return false if the inbox is empty" do
    mock_call = new_call_for_context :entrance
    dialplan = %{ entrance { throw messages_waiting? ? :yes : :no } }
    executing_dialplan(:entrance => dialplan, :call => mock_call).should throw_symbol :no
  end

  it "messages_waiting? should return false if the inbox is not empty" do
    mock_call = new_call_for_context :entrance
    mock_call.inbox << Object.new
    dialplan = %{ entrance { throw messages_waiting? ? :yes : :no } }
    executing_dialplan(:entrance => dialplan, :call => mock_call).should throw_symbol :yes
  end

end


describe "ExecutionEnvironment" do

  attr_accessor :call, :entry_point

  include DialplanTestingHelper

  before do
    variables = { :context => "zomgzlols", :caller_id => "Ponce de Leon" }
    @call = Adhearsion::Call.new(nil, variables)
    @entry_point = lambda {}
  end

  it "On initialization, ExecutionEnvironments extend themselves with behavior specific to the voip platform which originated the call" do
    Adhearsion::DialPlan::ExecutionEnvironment.included_modules.should_not include(Adhearsion::VoIP::Asterisk::Commands)
    execution_environent = Adhearsion::DialPlan::ExecutionEnvironment.create(call, entry_point)
    execution_environent.metaclass.included_modules.should include(Adhearsion::VoIP::Asterisk::Commands)
  end

  it "An executed context should raise a NameError error when a missing constant is referenced" do
    the_following_code do
      flexmock(Adhearsion::AHN_CONFIG).should_receive(:automatically_answer_incoming_calls).and_return false
      context = :context_with_missing_constant
      call = new_call_for_context context
      mock_dialplan_with "#{context} { ThisConstantDoesntExist }"
      Adhearsion::DialPlan::Manager.new.handle call
    end.should raise_error NameError

  end

  it "should define variables accessors within itself" do
    environment = Adhearsion::DialPlan::ExecutionEnvironment.create(@call, entry_point)
    call.variables.empty?.should be false
    call.variables.each do |key, value|
      environment.send(key).should be value
    end
  end

  it "should define accessors for other contexts in the dialplan" do
    call = new_call_for_context :am_not_for_kokoa!
    bogus_dialplan = <<-DIALPLAN
      am_not_for_kokoa! {}
      icanhascheezburger? {}
      these_context_names_do_not_really_matter {}
    DIALPLAN

    mock_dialplan_with bogus_dialplan

    manager = Adhearsion::DialPlan::Manager.new
    manager.dial_plan.entry_points.empty?.should_not be true

    manager.handle call

    %w(these_context_names_do_not_really_matter icanhascheezburger? am_not_for_kokoa!).each do |context_name|
      manager.context.respond_to?(context_name).should be true
    end

  end

end

describe "Dialplan control statements" do

  include DialplanTestingHelper

  it "Manager should catch ControlPassingExceptions" do
    flexmock(Adhearsion::AHN_CONFIG).should_receive(:automatically_answer_incoming_calls).and_return false
    dialplan = %{
      foo { raise Adhearsion::VoIP::DSL::Dialplan::ControlPassingException.new(bar) }
      bar {}
    }
    executing_dialplan(:foo => dialplan).should_not raise_error
  end

  it "All dialplan contexts should be available at context execution time" do
    dialplan = %{
      context_defined_first {
        throw :i_see_it if context_defined_second
      }
      context_defined_second {}
    }
    executing_dialplan(:context_defined_first => dialplan).should throw_symbol :i_see_it
  end

  test_dialplan_inclusions = true
  if Object.const_defined?("JRUBY_VERSION")
    require 'adhearsion/version'
    curver = Adhearsion::PkgVersion.new(JRUBY_VERSION)
    minver = Adhearsion::PkgVersion.new("1.6.0")
    if curver < minver
      # JRuby contains a bug that breaks some of the menu functionality
      # See: https://adhearsion.lighthouseapp.com/projects/5871/tickets/92-menu-method-under-jruby-does-not-appear-to-work
      test_dialplan_inclusions = false
    end
  end

  if test_dialplan_inclusions
    it "Proc#+@ should execute the other context" do
      dialplan = %{
        eins {
          +zwei
          throw :eins
        }
        zwei {
          throw :zwei
        }
      }
      executing_dialplan(:eins => dialplan).should throw_symbol :zwei
    end

    it "Proc#+@ should not return to its originating context" do
    dialplan = %{
      andere {}
      zuerst {
        +andere
        throw :after_control_statement
      }
    }
    executing_dialplan(:zuerst => dialplan).should_not raise_error
  end
  end


  it "new constants should still be accessible within the dialplan" do
    flexmock(Adhearsion::AHN_CONFIG).should_receive(:automatically_answer_incoming_calls).and_return false
    ::Jicksta = :Jicksta
    dialplan = %{
      constant_test {
        Jicksta.should == :Jicksta
      }
    }
    executing_dialplan(:constant_test => dialplan).should_not raise_error
  end

end

describe "VoIP platform operations" do
  it "can map a platform name to a module which holds its platform-specific operations" do
    Adhearsion::VoIP::Commands.for(:asterisk).should == Adhearsion::VoIP::Asterisk::Commands
  end
end

describe 'DialPlan::Loader' do
  it '::build should raise a SyntaxError when the dialplan String contains one' do
    the_following_code {
      Adhearsion::DialPlan::Loader.load "foo { ((((( *@!^*@&*^!^@ }"
    }.should raise_error SyntaxError
  end
end
