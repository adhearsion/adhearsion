require 'spec_helper'

class Example
  attr_reader :name, :yaml, :metadata, :file

  def initialize(name)
    @name = name.to_sym
    @file = File.expand_path(File.dirname(__FILE__) + "/dsl_examples/#{name}.rb")
    @yaml = file_contents[/=begin YAML\n(.+?)\n=end/m, 1]
    @metadata = @yaml.nil? ? nil : YAML.load(@yaml)
  end

  def file_contents
    File.read @file
  end

  def register_namespaces_on(obj)
    obj = obj.namespace_manager if obj.kind_of? Theatre::Theatre
    namespaces = metadata["namespaces"]
    if namespaces && namespaces.kind_of?(Array) && namespaces.any?
      namespaces.each do |namespace|
        obj.register_namespace_name namespace
      end
    end
    obj
  end
end

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
