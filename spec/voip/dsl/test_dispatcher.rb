require File.dirname(__FILE__) + '/dispatcher_spec_helper'
require 'adhearsion/voip/dsl/dialplan/dispatcher'


describe "A EventCommand" do

  it "should allow a block that's set to response_block()" do
    block = lambda {}
    cmd = Adhearsion::VoIP::DSL::Dialplan::EventCommand.new "foo", &block
    cmd.response_block.should be(block)
  end

  it "should return specified return type with returns()" do
    return_type = Numeric
    cmd = Adhearsion::VoIP::DSL::Dialplan::EventCommand.new "foo", :returns => return_type
    cmd.returns.should be(return_type)
  end

end

describe "The abstract CommandDispatcher" do

  it "should make an attribute reader for context()" do
    context = "foo"
    d = Adhearsion::VoIP::DSL::Dialplan::CommandDispatcher.new String, context
    d.context.should be(context)
  end

  it "should instantiate a new instance of the specified factory" do
    d = Adhearsion::VoIP::DSL::Dialplan::CommandDispatcher.new Hash
    d.factory.should be_a_kind_of(Hash)
  end

  it "should pass the context to the factory when instantiating it" do
    context = "shazbot"
    klass = flexmock "a class that has one argument in its constructor"
    klass.should_receive(:new).with(context)
    d = Adhearsion::VoIP::DSL::Dialplan::CommandDispatcher.new klass, context
  end

  it "should not allow calling dispatch!() directly" do
    dispatcher = Adhearsion::VoIP::DSL::Dialplan::CommandDispatcher.new MyFactory
    lambda do
      dispatcher.dispatch! nil
    end.should raise_error(NotImplementedError)
  end

  it "should pass a method and any args onto its CommandFactory" do

    weird_args = [1, 2, ["foo", nil], Object.new, 12.3..13.4]

    bogus_command = Adhearsion::VoIP::DSL::Dialplan::EventCommand.new "123"

    dispatcher = NilDispatcher.new MyFactory
    flexmock(dispatcher.factory).should_receive(:monkey).with(*weird_args).and_return bogus_command
    dispatcher.monkey(*weird_args)

  end

  it "should continue executing response_blocks until nil is returned" do
    actual_executions, target_executions = 0, 5
    response = Adhearsion::VoIP::DSL::Dialplan::EventCommand.new "1" do |response|
      if response > target_executions
        nil
      else
        actual_executions += 1
        Adhearsion::VoIP::DSL::Dialplan::EventCommand.new(response + 1)
      end
    end
    mock_factory_class = Class.new do
      def initialize(*args)
      end
      def testplz
        response
      end
    end
    dispatcher = EvalDispatcher.new(mock_factory_class)
    flexmock(dispatcher.factory).should_receive(:testplz).and_return(response)
    dispatcher.testplz
    actual_executions.should be(target_executions)
  end
end
