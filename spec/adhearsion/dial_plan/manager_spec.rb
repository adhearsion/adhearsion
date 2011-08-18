require 'spec_helper'

describe "Dialplan::Manager handling" do

  include DialplanTestingHelper

  attr_accessor :manager, :call, :context_name, :mock_context

  before :each do
    pending
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
    pending
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
    pending
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
    pending
    call = Adhearsion::Call.new(nil, {'extension' => "h"})
    call.hungup_call?.should be true
    flexmock(Adhearsion::DialPlan).should_receive(:new).once.and_return flexmock("bogus DialPlan which should never be used")
    the_following_code {
      Adhearsion::DialPlan::Manager.handle(call)
    }.should raise_error Adhearsion::HungupExtensionCallException
  end

end

describe "The inbox-related dialplan methods" do

  include DialplanTestingHelper

  before { pending }

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

describe "Dialplan control statements" do

  include DialplanTestingHelper

  before { pending }

  it "Manager should catch ControlPassingExceptions" do
    flexmock(Adhearsion::AHN_CONFIG).should_receive(:automatically_answer_incoming_calls).and_return false
    dialplan = %{
      foo { raise Adhearsion::DSL::Dialplan::ControlPassingException.new(bar) }
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
