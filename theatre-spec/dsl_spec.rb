require 'spec_helper'

describe "CallbackDefinitionContainer" do

  it "should successfully load the :simple_before_call example" do
    example = Example.new(:simple_before_call)
    theatre = Theatre::Theatre.new
    example.register_namespaces_on theatre

    flexmock(theatre.namespace_manager).should_receive(:register_callback_at_namespace).
        with([:asterisk, :before_call], Proc).once

    loader  = Theatre::CallbackDefinitionLoader.new(theatre)
    loader.load_events_file example.file
  end

  it "should let you override the recorder method name" do
    theatre = Theatre::Theatre.new
    theatre.namespace_manager.register_namespace_name "/foo/bar/qaz"
    flexmock(theatre.namespace_manager).should_receive(:register_callback_at_namespace).
        with([:foo, :bar, :qaz], Proc).once

    loader = Theatre::CallbackDefinitionLoader.new(theatre, :roflcopter)
    loader.roflcopter.foo.bar.qaz.each {}
  end

end

# High level specs to test the entire library.

describe "Misuses of the Theatre" do

  it "should not allow callbacks to be registered for namespaces which have not been registered" do
    theatre = Theatre::Theatre.new
    example = Example.new(:simple_before_call)

    loader = Theatre::CallbackDefinitionLoader.new(theatre)
    lambda do
      loader.events.foo.each {}
    end.should raise_error(Theatre::NamespaceNotFound)
  end

end
