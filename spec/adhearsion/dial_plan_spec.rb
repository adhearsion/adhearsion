require 'spec_helper'

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
