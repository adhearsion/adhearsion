require 'spec_helper'

module NamespaceHelper
  class BeValidNamespace

    def matches?(target)
      @target = target
      Theatre::ActorNamespaceManager.valid_namespace_path? target
    end

    def failure_message
      "expected #{@target.inspect} to be a valid namespace"
    end

    def negative_failure_message
      "expected #{@target.inspect} not to be a valid namespace"
    end

  end

  def be_valid_actor_event_namespace
    BeValidNamespace.new
  end

end

describe "ActorNamespaceManager" do

  it "should make a registered namespace findable once registered" do
    nm = Theatre::ActorNamespaceManager.new
    nm.register_namespace_name "/foo/bar/qaz"
    nm.search_for_namespace("/foo/bar/qaz").should be_kind_of(Theatre::ActorNamespaceManager::NamespaceNode)
  end

  it "should return the new namespace when registering it" do

  end

  it "#search_for_namespace should raise a NamespaceNotFound exception if a namespace one level deep was not found" do
    nm = Theatre::ActorNamespaceManager.new
    lambda do
      nm.search_for_namespace "/foo"
    end.should raise_error(Theatre::NamespaceNotFound)
  end

  it "#search_for_namespace should raise a NamespaceNotFound exception if a namespace two levels deep was not found" do
    nm = Theatre::ActorNamespaceManager.new
    lambda do
      nm.search_for_namespace "/foo/bar"
    end.should raise_error(Theatre::NamespaceNotFound)
  end

  describe '::normalize_path_to_array' do
    it "should split a standard path properly" do
      Theatre::ActorNamespaceManager.normalize_path_to_array("/foo/bar/qaz").should == [:foo, :bar, :qaz]
    end

    it "should split out Array()'d form of a String path properly" do
      Theatre::ActorNamespaceManager.normalize_path_to_array(["/jay/thomas/phillips"]).should == [:jay,:thomas,:phillips]
    end
  end

end

describe "NamespaceNode" do

  it "when registering a new namespace, the new NamespaceNode should be returned" do
    node = Theatre::ActorNamespaceManager::NamespaceNode.new "foobar"
    node.register_namespace_name("foobar").should be_instance_of(Theatre::ActorNamespaceManager::NamespaceNode)
  end

  it "should not blow away an existing callback when registering a new one with the same name" do
    name = "blah"
    node = Theatre::ActorNamespaceManager::NamespaceNode.new name
    node.register_namespace_name name
    before = node.child_named(name)
    before.should be_instance_of(Theatre::ActorNamespaceManager::NamespaceNode)
    node.register_namespace_name name
    before.should eql(node.child_named(name))
  end

  describe '#register_namespace_name' do
    it "should return the NamespaceNode" do
      Theatre::ActorNamespaceManager::NamespaceNode.new("foo").register_namespace_name("bar").should \
          be_instance_of(Theatre::ActorNamespaceManager::NamespaceNode)
    end
  end

end

describe "Valid namespace segments" do

  include NamespaceHelper

  describe "a valid namespace path" do

    it "should require a namespace path start with a /" do
      "/foo".   should     be_valid_actor_event_namespace
      "foo".    should_not be_valid_actor_event_namespace
      "foo/bar".should_not be_valid_actor_event_namespace
    end

    it "should allow multiple namespace segments" do
      "/foo_foo/bar".should be_valid_actor_event_namespace
    end

    it "should not allow a trailing forward slash" do
      "/foo/bar/".should_not be_valid_actor_event_namespace
    end

    it "should not allow backslashes" do
      '\foo'.should_not be_valid_actor_event_namespace
      '\foo\bar'.should_not be_valid_actor_event_namespace
      'foo\bar'.should_not be_valid_actor_event_namespace
      '\bar\\'.should_not be_valid_actor_event_namespace
    end

    it "should not allow weird characters" do
      %w[ ! @ # $ % ^ & * ( ) { } | ' : ? > < - = ].each do |bad_character|
        "/foo#{bad_character}foo/bar".should_not be_valid_actor_event_namespace
      end
    end

  end
end
