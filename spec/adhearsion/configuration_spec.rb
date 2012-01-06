require 'spec_helper'

describe Adhearsion::Configuration do

  describe "when initializing the config instance" do
    subject do
      Adhearsion::Configuration.new
    end

    it "should have an empty configuration for the platform" do
      subject.should respond_to :platform
    end

    it "should have a platform configuration object" do
      subject.platform.should be_instance_of Loquacious::Configuration
    end

    it "should initialize root to nil" do
      subject.platform.root.should be_nil
    end

    it "should initialize logging to level info" do
      subject.platform.logging.level.should == :info
    end

    it "should allow to update a config value" do
      subject.platform.automatically_accept_incoming_calls.should == true
      subject.platform.automatically_accept_incoming_calls = false
      subject.platform.automatically_accept_incoming_calls.should == false
    end

    it "should allow to create new config values" do
      subject.platform.bar = "foo"
      subject.platform.bar.should == "foo"
    end
  end

  describe "when initializing the config instance with specific values" do
    subject do
      Adhearsion::Configuration.new do
        root "foo", :desc => "Adhearsion application root folder"
        automatically_accept_incoming_calls false, :desc => "Adhearsion will not accept automatically any inbound call"
      end
    end

    it "should return the root value" do
      subject.platform.root.should == "foo"
    end
    
    it "should return the automatically_accept_incoming_calls value" do
      subject.platform.automatically_accept_incoming_calls.should == false
    end

    it "should return a description for the platform configuration" do
      Adhearsion.config.description(:platform).should be_instance_of String
    end

    it "should allow to update a config value" do
      subject.platform.automatically_accept_incoming_calls.should == false
      subject.platform.automatically_accept_incoming_calls = true      
      subject.platform.automatically_accept_incoming_calls.should == true
    end

    it "should allow to create new config values" do
      subject.platform.bar = "bazz"
      subject.platform.bar.should == "bazz"
    end
  end

  describe "when configuring a non existing object" do
    it "should raise a ConfigurationError" do
      lambda {
        Adhearsion.config.foo.bar = "bazz"
      }.should raise_error Adhearsion::ConfigurationError, "Invalid plugin foo"
    end
  end

  describe "when accessing the platform configuration" do
    after do
      Adhearsion.config = nil
    end

    subject{ Adhearsion.config[:platform] }

    it "should return the valid platform configuration object" do
      subject.should be_instance_of ::Loquacious::Configuration
    end

    it "should allow to retrieve any platform configuration value" do
      subject.automatically_accept_incoming_calls.should == true
    end

  end

  describe "while retrieving configuration descriptions" do
    before do
      Adhearsion.config = nil
    end

    subject { Adhearsion.config }
    
    it "should retrieve a string with the platform configuration" do
      desc = subject.description :platform, :show_values => false
      desc.length.should > 0
      desc.should match /^.*automatically_accept_incoming_calls.*$/
      desc.should match /^.*root.*$/
    end

    it "should retrieve a string with the platform configuration and values" do
      desc = subject.description :platform      
      desc.length.should > 0
      desc.should match /^.*automatically_accept_incoming_calls.*true.*$/
      desc.should match /^.*root.*$/
    end

    describe "if there are plugins installed" do
      before do
        Adhearsion::Logging.silence!

        Class.new Adhearsion::Plugin do
          config :my_plugin do
            name     "user"     , :desc => "name to authenticate user"
            password "password" , :desc => "authentication password"
            host     "localhost", :desc => "valid IP or hostname"
          end
        end
      end

      describe "retrieving configuration for the plugin" do
        context "via a method" do
          subject { Adhearsion.config.my_plugin }

          it "should have the correct values" do
            subject[:name].should == 'user'
            subject[:password].should == 'password'
            subject[:host].should == 'localhost'
          end
        end

        context "using the hash accessor syntax" do
          subject { Adhearsion.config[:my_plugin] }

          it "should have the correct values" do
            subject[:name].should == 'user'
            subject[:password].should == 'password'
            subject[:host].should == 'localhost'
          end
        end
      end

      it "should retrieve a valid plugin description" do
        desc = subject.description :my_plugin
        desc.length.should > 0
        desc.should match /^.*name.*user.*$/
        desc.should match /^.*password.*password.*$/
        desc.should match /^.*host.*localhost.*$/
      end

      it "should retrieve a valid plugin description with no values" do
        desc = subject.description :my_plugin, :show_values => false 
        desc.length.should > 0
        desc.should match /^.*name.*$/
        desc.should match /^.*password.*$/
        desc.should match /^.*host.*$/
      end

      it "should retrieve both platform and plugin configuration" do
        desc = subject.description :all
        desc.length.should > 0
        desc.should match /^.*automatically_accept_incoming_calls.*true.*$/
        desc.should match /^.*root.*$/
        desc.should match /^.*name.*user.*$/
        desc.should match /^.*password.*password.*$/
        desc.should match /^.*host.*localhost.*$/
      end

      it "should retrieve both platform and plugin configuration with no values" do
        desc = subject.description :all, :show_values => false
        desc.length.should > 0
        desc.should match /^.*Configuration for platform.*$/
        desc.should match /^.*automatically_accept_incoming_calls.*$/
        desc.should match /^.*root.*$/
        desc.should match /^.*Configuration for my_plugin.*$/
        desc.should match /^.*name.*$/
        desc.should match /^.*password.*$/
        desc.should match /^.*host.*$/
      end
    end

  end
end
