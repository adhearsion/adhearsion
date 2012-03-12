# encoding: utf-8

require 'spec_helper'

include InitializerStubs

describe Adhearsion::Plugin do

  before :all do
    defined?(FooBar) and Object.send(:remove_const, :"FooBar")
  end

  describe "inheritance" do
    after do
      defined?(FooBar) and Object.send(:remove_const, :"FooBar")
    end

    it "should provide the plugin name in a plugin class" do
      ::FooBar = Class.new Adhearsion::Plugin
      ::FooBar.plugin_name.should be == "foo_bar"
    end

    it "should provide the plugin name in a plugin instance" do
      ::FooBar = Class.new Adhearsion::Plugin
      ::FooBar.new.plugin_name.should be == "foo_bar"
    end

    it "should provide a setter for plugin name" do
      ::FooBar = Class.new Adhearsion::Plugin do
        self.plugin_name = "bar_foo"
      end

      ::FooBar.plugin_name.should be == "bar_foo"
    end
  end

  describe "While configuring plugins" do
    after(:each) do
      defined?(FooBar) and Object.send(:remove_const, :"FooBar")
    end

    subject {
      Class.new Adhearsion::Plugin do
        config :bar_foo do
          name     "user"     , :desc => "name to authenticate user"
          password "password" , :desc => "authentication password"
          host     "localhost", :desc => "valid IP or hostname"
        end
      end
    }

    its(:plugin_name) { should be == :bar_foo }

    its(:config) { should be_instance_of Loquacious::Configuration }

    it "should keep a default configuration and a description" do
      [:name, :password, :host].each do |value|
        subject.config.should respond_to value
      end

      subject.config.name.should     be == "user"
      subject.config.password.should be == "password"
      subject.config.host.should     be == "localhost"
    end

    it "should return a description of configuration options" do
      subject.show_description.should be_kind_of Loquacious::Configuration::Help
    end

    describe "while updating config values" do
      it "should return the updated value" do
        subject.config.name = "usera"
        subject.config.name.should be == "usera"
      end
    end

  end

  describe "add and delete on the air" do
    AhnPluginDemo = Class.new Adhearsion::Plugin

    it "should add plugins on the air" do
      Adhearsion::Plugin.delete_all
      Adhearsion::Plugin.add AhnPluginDemo
      Adhearsion::Plugin.count.should eql 1
    end

    it "should delete plugins on the air" do
      Adhearsion::Plugin.delete_all
      Adhearsion::Plugin.add AhnPluginDemo
      Adhearsion::Plugin.count.should eql 1
      Adhearsion::Plugin.delete AhnPluginDemo
      Adhearsion::Plugin.count.should eql 0
    end
  end

  describe "#count" do
    after(:each) do
      defined?(FooBar) and Object.send(:remove_const, :"FooBar")
    end

    it "should count the number of registered plugins" do
      number = Adhearsion::Plugin.count
      FooBar = Class.new Adhearsion::Plugin
      Adhearsion::Plugin.count.should eql(number + 1)
    end
  end

  describe "Adhearsion::Plugin.init_plugins" do
    before(:all) do
      Adhearsion::Plugin.class_eval do
        def self.reset_methods_scope
          @methods_scope = Hash.new { |hash, key| hash[key] = Module.new }
        end

        def self.reset_subclasses
          @subclasses = nil
        end
      end
    end

    before do
      Adhearsion::Plugin.reset_methods_scope
      Adhearsion::Plugin.reset_subclasses
    end

    after do
      Adhearsion::Plugin.initializers.clear
      Adhearsion::Plugin.runners.clear
      defined?(FooBar) and Object.send(:remove_const, :"FooBar")
      defined?(FooBarBaz) and Object.send(:remove_const, :"FooBarBaz")
      defined?(FooBarBazz) and Object.send(:remove_const, :"FooBarBazz")
    end

    describe "while registering plugins initializers" do
      it "should do nothing with a Plugin that has no init method call" do
        FooBar = Class.new Adhearsion::Plugin

        # 1 => Punchblock. Must be empty once punchblock initializer is an external Plugin
        Adhearsion::Plugin.initializers.should have(1).initializers
        flexmock(Adhearsion::PunchblockPlugin::Initializer).should_receive(:start).and_return true
        Adhearsion::Plugin.init_plugins
      end

      it "should add a initializer when Plugin defines it" do
        FooBar = Class.new Adhearsion::Plugin do
          init :foo_bar do
            FooBar.log "foo bar"
          end
          def self.log
          end
        end

        flexmock(FooBar).should_receive(:log).once
        Adhearsion::Plugin.initializers.length.should be 1
        flexmock(Adhearsion::PunchblockPlugin::Initializer).should_receive(:start).and_return true
        Adhearsion::Plugin.init_plugins
      end

      it "should initialize all Plugin children, including deep childs" do
        FooBar = Class.new Adhearsion::Plugin do
          init :foo_bar do
            FooBar.log "foo bar"
          end

          def self.log
          end
        end

        FooBarBaz = Class.new FooBar do
          init :foo_bar_baz do
            FooBar.log "foo bar baz"
          end
        end
        FooBarBazz = Class.new FooBar do
          init :foo_bar_bazz do
            FooBar.log "foo bar bazz"
          end
        end

        flexmock(FooBar).should_receive(:log).times(3)
        flexmock(Adhearsion::PunchblockPlugin::Initializer).should_receive(:start).and_return true
        Adhearsion::Plugin.init_plugins
      end

      it "should allow to include an initializer before another one" do
        FooBar = Class.new Adhearsion::Plugin do
          init :foo_bar do
            FooBar.log "foo bar"
          end

          def self.log
          end
        end

        FooBarBaz = Class.new FooBar do
          init :foo_bar_baz, :before => :foo_bar do
            FooBar.log "foo bar baz"
          end
        end

        Adhearsion::Plugin.initializers.tsort.first.name.should eql :foo_bar_baz
        Adhearsion::Plugin.initializers.tsort.last.name.should eql :foo_bar
      end

      it "should allow to include an initializer after another one" do
        FooBar = Class.new Adhearsion::Plugin do
          init :foo_bar do
            FooBar.log "foo bar"
          end

          def self.log
          end
        end

        FooBarBaz = Class.new FooBar do
          init :foo_bar_baz, :after => :foo_bar_bazz do
            FooBar.log "foo bar baz"
          end
        end

        FooBarBazz = Class.new FooBar do
          init :foo_bar_bazz do
            FooBar.log "foo bar bazz"
          end
        end

        Adhearsion::Plugin.initializers.length.should eql 3
        Adhearsion::Plugin.initializers.tsort.first.name.should eql :foo_bar
        Adhearsion::Plugin.initializers.tsort.last.name.should eql :foo_bar_baz
      end
    end

    describe "while registering plugins runners" do
      it "should do nothing with a Plugin that has no run method call" do
        FooBar = Class.new Adhearsion::Plugin

        # May become 1 if Punchblock defines a runner.
        Adhearsion::Plugin.runners.should have(0).runners
        flexmock(Adhearsion::PunchblockPlugin::Initializer).should_receive(:start).and_return true
        Adhearsion::Plugin.run_plugins
      end

      it "should add a runner when Plugin defines it" do
        FooBar = Class.new Adhearsion::Plugin do
          run :foo_bar do
            FooBar.log "foo bar"
          end
          def self.log
          end
        end

        flexmock(FooBar).should_receive(:log).once
        Adhearsion::Plugin.runners.length.should be 1
        flexmock(Adhearsion::PunchblockPlugin::Initializer).should_receive(:start).and_return true
        Adhearsion::Plugin.run_plugins
      end

      it "should run all Plugin children, including deep childs" do
        FooBar = Class.new Adhearsion::Plugin do
          run :foo_bar do
            FooBar.log "foo bar"
          end

          def self.log
          end
        end

        FooBarBaz = Class.new FooBar do
          run :foo_bar_baz do
            FooBar.log "foo bar baz"
          end
        end
        FooBarBazz = Class.new FooBar do
          run :foo_bar_bazz do
            FooBar.log "foo bar bazz"
          end
        end

        flexmock(FooBar).should_receive(:log).times(3)
        flexmock(Adhearsion::PunchblockPlugin::Initializer).should_receive(:start).and_return true
        Adhearsion::Plugin.run_plugins
      end

      it "should allow to execute one runner before another one" do
        FooBar = Class.new Adhearsion::Plugin do
          run :foo_bar do
            FooBar.log "foo bar"
          end

          def self.log
          end
        end

        FooBarBaz = Class.new FooBar do
          run :foo_bar_baz, :before => :foo_bar do
            FooBar.log "foo bar baz"
          end
        end

        Adhearsion::Plugin.runners.tsort.first.name.should eql :foo_bar_baz
        Adhearsion::Plugin.runners.tsort.last.name.should eql :foo_bar
      end

      it "should allow to include an runner after another one" do
        FooBar = Class.new Adhearsion::Plugin do
          run :foo_bar do
            FooBar.log "foo bar"
          end

          def self.log
          end
        end

        FooBarBaz = Class.new FooBar do
          run :foo_bar_baz, :after => :foo_bar_bazz do
            FooBar.log "foo bar baz"
          end
        end

        FooBarBazz = Class.new FooBar do
          run :foo_bar_bazz do
            FooBar.log "foo bar bazz"
          end
        end

        Adhearsion::Plugin.runners.length.should eql 3
        Adhearsion::Plugin.runners.tsort.first.name.should eql :foo_bar
        Adhearsion::Plugin.runners.tsort.last.name.should eql :foo_bar_baz
      end
    end
  end

  describe "while loading rake tasks" do

    after do
      Adhearsion::Plugin.reset_rake_tasks
      defined?(FooBar) and Object.send(:remove_const, :"FooBar")
    end

    subject { Adhearsion::Plugin.tasks }

    it "should return an Array" do
      subject.should be_instance_of Array
    end

    its(:length) { should be == 0 }

    it "should not load a new task when there is no block in the method call" do
      subject.length.should be == 0
      FooBar = Class.new Adhearsion::Plugin do
        tasks
      end

      subject.length.should be == 0
    end

    it "should load a new task when there is a block in the method call" do
      subject.length.should be == 0
      FooBar = Class.new Adhearsion::Plugin do
        tasks do
          puts "foo bar"
        end
      end
      Adhearsion::Plugin.tasks.length.should be == 1
    end

    it "should execute the tasks blocks while loading rake tasks" do
      subject.length.should be == 0
      FooBar = Class.new Adhearsion::Plugin do
        tasks do
          FooBar.foo
        end
        def self.foo
        end
      end
      flexmock(FooBar).should_receive(:foo).once
      Adhearsion::Plugin.load_tasks
    end

  end

  describe "registering generators" do
    TestGenerator1 = Class.new Adhearsion::Generators::Generator
    TestGenerator2 = Class.new Adhearsion::Generators::Generator

    after do
      defined?(FooBar) and Object.send(:remove_const, :"FooBar")
    end

    it "should add the generator to the index" do
      FooBar = Class.new Adhearsion::Plugin do
        generators :gen1 => TestGenerator1, :gen2 => TestGenerator2
      end

      Adhearsion::Generators.mappings[:gen1].should be TestGenerator1
      Adhearsion::Generators.mappings[:gen2].should be TestGenerator2
    end
  end

end
