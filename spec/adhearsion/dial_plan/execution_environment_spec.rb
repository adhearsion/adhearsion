require 'spec_helper'

describe "ExecutionEnvironment" do

  attr_accessor :call, :entry_point

  include DialplanTestingHelper

  before do
    pending
    variables = { :context => "zomgzlols", :caller_id => "Ponce de Leon" }
    @call = Adhearsion::Call.new(nil, variables)
    @entry_point = lambda {}
  end

  it "On initialization, ExecutionEnvironments extend themselves with behavior specific to the voip platform which originated the call" do
    Adhearsion::DialPlan::ExecutionEnvironment.included_modules.should_not include(Adhearsion::Asterisk::Commands)
    execution_environent = Adhearsion::DialPlan::ExecutionEnvironment.create(call, entry_point)
    execution_environent.metaclass.included_modules.should include(Adhearsion::Asterisk::Commands)
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
