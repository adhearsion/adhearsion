require 'spec_helper'

include InitializerStubs

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
  end

  describe "metaprogramming" do
    [:dialplan, :rpc, :events].each do |method|
      it "should respond to #{method.to_s}" do
        Adhearsion::Plugin.should respond_to(method)
      end      
      it "should respond to #{method.to_s}_module" do
        Adhearsion::Plugin.should respond_to("#{method.to_s}_module")
      end      
    end
  end

  describe "While configuring plugins" do

    after(:each) do
      defined?(FooBar) and Object.send(:remove_const, :"FooBar")
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
    Adhearsion::Plugin.class_variable_set("@@methods_container", Hash.new{|hash, key| hash[key] = Adhearsion::Plugin::MethodsContainer.new })
  end

  let(:o) do
    o = Object.new
    o.class.send(:define_method, :load_code) do |code|
    end
  end

  let(:dialplan_module) do
    Module.new
  end

  let(:rpc_module) do
    Module.new
  end

  after(:each) do
    Adhearsion::Plugin.initializers.clear
    defined?(FooBar) and Object.send(:remove_const, :"FooBar")
    defined?(FooBarBaz) and Object.send(:remove_const, :"FooBarBaz")
    defined?(FooBarBazz) and Object.send(:remove_const, :"FooBarBazz")
  end

  describe "while registering plugins initializers" do

    it "should do nothing with a Plugin that has no init method call" do
      FooBar = Class.new Adhearsion::Plugin

      Adhearsion::Plugin.initializers.should be_empty
      Adhearsion::Plugin.load
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
      Adhearsion::Plugin.initializers.length.should be(1)
      Adhearsion::Plugin.load
    end

    it "should initialize all Plugin childs, including deep childs" do
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
      Adhearsion::Plugin.load
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

      Adhearsion::Plugin.initializers.tsort.first.name.should eql(:foo_bar_baz)
      Adhearsion::Plugin.initializers.tsort.last.name.should eql(:foo_bar)
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

      Adhearsion::Plugin.initializers.length.should eql(3)
      Adhearsion::Plugin.initializers.tsort.first.name.should eql(:foo_bar)
      Adhearsion::Plugin.initializers.tsort.last.name.should eql(:foo_bar_baz)
    end
  end

  [:rpc, :dialplan].each do |method|
    describe "Plugin subclass with #{method.to_s}_method definition" do
      it "should add a method defined using #{method.to_s} method" do
        FooBar = Class.new Adhearsion::Plugin do
          self.method(method).call(:foo) 
          
          def self.foo(call)
            "bar"
          end
        end
        
        flexmock(Adhearsion::Plugin).should_receive("#{method.to_s}_module".to_sym).once.and_return(send("#{method.to_s}_module".to_sym))
        Adhearsion::Plugin.load
        send("#{method.to_s}_module".to_sym).instance_methods.include?(:foo).should be true
      end

      it "should add an instance method defined using #{method.to_s} method" do
        FooBar = Class.new Adhearsion::Plugin do
          self.method(method).call(:foo) 
          def foo(call)
            call
          end
        end
        
        flexmock(Adhearsion::Plugin).should_receive("#{method.to_s}_module".to_sym).once.and_return(send("#{method.to_s}_module".to_sym))
        Adhearsion::Plugin.load
        send("#{method.to_s}_module".to_sym).instance_methods.include?(:foo).should be true
      end

      it "should add an array of methods defined using #{method.to_s} method" do
        FooBar = Class.new Adhearsion::Plugin do
          self.method(method).call([:foo, :bar])

          def self.foo(call)
            call
          end

          def self.bar(call)
            "foo"
          end
        end
        
        flexmock(Adhearsion::Plugin).should_receive("#{method.to_s}_module".to_sym).twice.and_return(send("#{method.to_s}_module".to_sym))
        Adhearsion::Plugin.load
        [:foo, :bar].each do |_method|
          send("#{method.to_s}_module".to_sym).instance_methods.include?(_method).should be true
        end
      end
      
      it "should add an array of instance methods defined using #{method.to_s} method" do
        FooBar = Class.new Adhearsion::Plugin do
          self.method(method).call([:foo, :bar])
          def foo(call)
            call
          end

          def bar(call)
            call
          end
        end
        
        flexmock(Adhearsion::Plugin).should_receive("#{method.to_s}_module".to_sym).twice.and_return(send("#{method.to_s}_module".to_sym))
        Adhearsion::Plugin.load
        [:foo, :bar].each do |_method|
          send("#{method.to_s}_module".to_sym).instance_methods.include?(_method).should be true
        end
      end
    
      it "should add an array of instance and singleton methods defined using #{method.to_s} method" do
        FooBar = Class.new Adhearsion::Plugin do
          self.method(method).call([:foo, :bar])
          def self.foo(call)
            call
          end

          def bar(call)
            call
          end
        end
        
        flexmock(Adhearsion::Plugin).should_receive("#{method.to_s}_module".to_sym).twice.and_return(send("#{method.to_s}_module".to_sym))
        Adhearsion::Plugin.load
        [:foo, :bar].each do |_method|
          send("#{method.to_s}_module".to_sym).instance_methods.include?(_method).should be true
        end
      end

      it "should add a method defined using #{method.to_s} method with a specific block" do
        FooBar = Class.new Adhearsion::Plugin do
          self.method(method).call(:foo) do |call|
            puts call
          end
        end
        
        flexmock(Adhearsion::Plugin).should_receive("#{method.to_s}_module".to_sym).once.and_return(send("#{method.to_s}_module".to_sym))
        Adhearsion::Plugin.load
        send("#{method.to_s}_module".to_sym).instance_methods.include?(:foo).should be true
      end
    end
  end

  describe "Plugin subclass with rpc_method and dialplan_method definitions" do
    it "should add a method defined using rpc and a method defined using dialplan" do
      FooBar = Class.new Adhearsion::Plugin do
        rpc :foo
        dialplan :foo
        
        def self.foo(call)
          "bar"
        end
      end
      
      flexmock(Adhearsion::Plugin).should_receive(:dialplan_module).once.and_return(dialplan_module)
      flexmock(Adhearsion::Plugin).should_receive(:rpc_module).once.and_return(rpc_module)
      Adhearsion::Plugin.load
      rpc_module.instance_methods.include?(:foo).should be true
      dialplan_module.instance_methods.include?(:foo).should be true
    end
  end
  
end

describe "Initializing Adhearsion" do
  it "should load the new dial plans" do
    flexmock(Adhearsion::Initializer::Logging).should_receive(:start).once.and_return('')
    flexmock(::Logging::Appenders::File).should_receive(:assert_valid_logfile).and_return(true)
    flexmock(::Logging::Appenders).should_receive(:file).and_return(nil)

    #say_hello = AhnPluginDemo::SayText.new("value")
    #flexmock(say_hello).should_receive(:start).once.and_return(true)
    #flexmock(AhnPluginDemo).should_receive(:create_say_text).once.and_return(say_hello)

    stub_behavior_for_initializer_with_no_path_changing_behavior do
      ahn = Adhearsion::Initializer.start "/path"
    end
  end
end
