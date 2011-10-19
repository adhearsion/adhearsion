require 'spec_helper'

# If you have a Gemfile, require the gems listed there, including any gems
# This is done by config/environment.rb in a real app


describe Adhearsion::Plugin do

  describe "inheritance" do

    after(:each) do
      defined?(FooBar) and Object.send(:remove_const, :"FooBar")
    end

    it "should provide the plugin name in a plugin class" do
      ::FooBar = Class.new Adhearsion::Plugin
      ::FooBar.plugin_name.should eql("foo_bar")
    end

    it "should provide the plugin name in a plugin instance" do
      ::FooBar = Class.new Adhearsion::Plugin
      ::FooBar.new.plugin_name.should eql("foo_bar")
    end

    it "should provide a setter for plugin name" do

      ::FooBar = Class.new Adhearsion::Plugin do
        self.plugin_name = "bar_foo"
      end

      ::FooBar.plugin_name.should eql("bar_foo")
    end

    it "should provide access to a config mechanism" do
      FooBar = Class.new Adhearsion::Plugin
      FooBar.config.should be_kind_of(Adhearsion::Plugin::Configuration)
    end

    it "should provide a config empty variable" do
      FooBar = Class.new Adhearsion::Plugin
      FooBar.config.length.should be(0)
    end

    it "should allow to set a new config value" do
      FooBar = Class.new Adhearsion::Plugin do
        config.foo = "bar"
      end
      FooBar.config.foo.should eql("bar")
    end

    it "should allow to get a config value using []" do
      FooBar = Class.new Adhearsion::Plugin do
        config.foo = "bar"
      end
      FooBar.config[:foo].should eql("bar")
    end

    it "should allow to set a config value using [:name] = value" do
      FooBar = Class.new Adhearsion::Plugin do
        config[:foo] = "bar"
      end
      FooBar.config.foo.should eql("bar")
      FooBar.config.length.should eql(1)
    end
  end

  describe "add and delete on the air" do
    it "should add plugins on the air" do
      Adhearsion::Plugin.delete_all
      Adhearsion::Plugin.add(AhnPluginDemo)
      Adhearsion::Plugin.count.should eql(1)
    end

    it "should delete plugins on the air" do
      Adhearsion::Plugin.delete_all
      Adhearsion::Plugin.add(AhnPluginDemo)
      Adhearsion::Plugin.count.should eql(1)
      Adhearsion::Plugin.delete(AhnPluginDemo)
      Adhearsion::Plugin.count.should eql(0)
    end

  end

  describe "Adhearsion::Plugin.count" do

    after(:each) do
      defined?(FooBar) and Object.send(:remove_const, :"FooBar")
    end
  
    it "should count the number of registered plugins" do
      number = Adhearsion::Plugin.count
      FooBar = Class.new Adhearsion::Plugin
      Adhearsion::Plugin.count.should eql(number + 1)
    end

  end

end

describe "Adhearsion::Plugin.load" do

  before(:each) do
    Adhearsion::Plugin.send(:subclasses=, nil)
  end

  after(:each) do
    defined?(FooBar) and Object.send(:remove_const, :"FooBar")
  end

  it "should initialize all Plugin childs" do
    FooBar = Class.new Adhearsion::Plugin

    flexmock(FooBar).should_receive(:init).once
    Adhearsion::Plugin.load
  end

  it "should initialize all Plugin childs, including deep childs" do
    FooBar = Class.new Adhearsion::Plugin
    FooBarBaz = Class.new FooBar
    FooBarBazz = Class.new FooBarBaz

    flexmock(FooBar).should_receive(:init).once
    flexmock(FooBarBaz).should_receive(:init).once
    flexmock(FooBarBazz).should_receive(:init).once

    Adhearsion::Plugin.load
  end
end

describe "Initializing Adhearsion" do
  it "should load the new dial plans" do
    
  end
end
