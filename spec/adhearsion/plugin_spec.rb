# encoding: utf-8

require 'spec_helper'
require 'loquacious'

include InitializerStubs

describe Adhearsion::Plugin do

  before :all do
    defined?(FooBar) and Object.send(:remove_const, :"FooBar")
  end

  before do
    allow(Adhearsion::PunchblockPlugin::Initializer).to receive_messages :start => true
  end

  describe "inheritance" do
    after do
      defined?(FooBar) and Object.send(:remove_const, :"FooBar")
    end

    it "should provide the plugin name in a plugin class" do
      ::FooBar = Class.new Adhearsion::Plugin
      expect(::FooBar.plugin_name).to eq("foo_bar")
    end

    it "should provide the plugin name in a plugin instance" do
      ::FooBar = Class.new Adhearsion::Plugin
      expect(::FooBar.new.plugin_name).to eq("foo_bar")
    end

    it "should provide a setter for plugin name" do
      ::FooBar = Class.new Adhearsion::Plugin do
        self.plugin_name = "bar_foo"
      end

      expect(::FooBar.plugin_name).to eq("bar_foo")
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

    describe '#plugin_name' do
      subject { super().plugin_name }
      it { is_expected.to eq(:bar_foo) }
    end

    describe '#config' do
      subject { super().config }
      it { is_expected.to be_instance_of Loquacious::Configuration }
    end

    it "should keep a default configuration and a description" do
      [:name, :password, :host].each do |value|
        expect(subject.config).to respond_to value
      end

      expect(subject.config.name).to     eq("user")
      expect(subject.config.password).to eq("password")
      expect(subject.config.host).to     eq("localhost")
    end

    it "should return a description of configuration options" do
      expect(subject.show_description).to be_kind_of Loquacious::Configuration::Help
    end

    describe "while updating config values" do
      it "should return the updated value" do
        subject.config.name = "usera"
        expect(subject.config.name).to eq("usera")
      end
    end

  end

  describe "add and delete on the air" do
    AhnPluginDemo = Class.new Adhearsion::Plugin

    it "should add plugins on the air" do
      Adhearsion::Plugin.delete_all
      Adhearsion::Plugin.add AhnPluginDemo
      expect(Adhearsion::Plugin.count).to eql 1
    end

    it "should delete plugins on the air" do
      Adhearsion::Plugin.delete_all
      Adhearsion::Plugin.add AhnPluginDemo
      expect(Adhearsion::Plugin.count).to eql 1
      Adhearsion::Plugin.delete AhnPluginDemo
      expect(Adhearsion::Plugin.count).to eql 0
    end
  end

  describe "#count" do
    after(:each) do
      defined?(FooBar) and Object.send(:remove_const, :"FooBar")
    end

    it "should count the number of registered plugins" do
      number = Adhearsion::Plugin.count
      FooBar = Class.new Adhearsion::Plugin
      expect(Adhearsion::Plugin.count).to eql(number + 1)
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
        expect(Adhearsion::Plugin.initializers.size).to eq(1)
        Adhearsion::Plugin.init_plugins
      end

      it "should add a initializer when Plugin defines it" do
        FooBar = Class.new Adhearsion::Plugin do
          init :foo_bar do
            log "foo bar"
          end
          def self.log
          end
        end

        expect(FooBar).to receive(:log).once
        expect(Adhearsion::Plugin.initializers.length).to be 1
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

        expect(FooBar).to receive(:log).exactly(3).times
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

        expect(Adhearsion::Plugin.initializers.tsort.first.name).to eql :foo_bar_baz
        expect(Adhearsion::Plugin.initializers.tsort.last.name).to eql :foo_bar
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

        expect(Adhearsion::Plugin.initializers.length).to eql 3
        expect(Adhearsion::Plugin.initializers.tsort.first.name).to eql :foo_bar
        expect(Adhearsion::Plugin.initializers.tsort.last.name).to eql :foo_bar_baz
      end
    end

    describe "while registering plugins runners" do
      it "should do nothing with a Plugin that has no run method call" do
        FooBar = Class.new Adhearsion::Plugin

        # May become 1 if Punchblock defines a runner.
        expect(Adhearsion::Plugin.runners.size).to eq(0)
        Adhearsion::Plugin.run_plugins
      end

      it "should add a runner when Plugin defines it" do
        FooBar = Class.new Adhearsion::Plugin do
          run :foo_bar do
            log "foo bar"
          end
          def self.log
          end
        end

        expect(FooBar).to receive(:log).once
        expect(Adhearsion::Plugin.runners.length).to be 1
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

        expect(FooBar).to receive(:log).exactly(3).times
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

        expect(Adhearsion::Plugin.runners.tsort.first.name).to eql :foo_bar_baz
        expect(Adhearsion::Plugin.runners.tsort.last.name).to eql :foo_bar
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

        expect(Adhearsion::Plugin.runners.length).to eql 3
        expect(Adhearsion::Plugin.runners.tsort.first.name).to eql :foo_bar
        expect(Adhearsion::Plugin.runners.tsort.last.name).to eql :foo_bar_baz
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
      expect(subject).to be_instance_of Array
    end

    describe '#length' do
      subject { super().length }
      it { is_expected.to eq(0) }
    end

    it "should not load a new task when there is no block in the method call" do
      expect(subject.length).to eq(0)
      FooBar = Class.new Adhearsion::Plugin do
        tasks
      end

      expect(subject.length).to eq(0)
    end

    it "should load a new task when there is a block in the method call" do
      expect(subject.length).to eq(0)
      FooBar = Class.new Adhearsion::Plugin do
        tasks do
          puts "foo bar"
        end
      end
      expect(Adhearsion::Plugin.tasks.length).to eq(1)
    end

    it "should execute the tasks blocks while loading rake tasks" do
      expect(subject.length).to eq(0)
      FooBar = Class.new Adhearsion::Plugin do
        tasks do
          FooBar.foo
        end
        def self.foo
        end
      end
      expect(FooBar).to receive(:foo).once
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

      expect(Adhearsion::Generators.mappings[:gen1]).to be TestGenerator1
      expect(Adhearsion::Generators.mappings[:gen2]).to be TestGenerator2
    end
  end

end
