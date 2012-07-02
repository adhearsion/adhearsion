# encoding: utf-8

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
      subject.platform.logging.level.should be == :info
    end

    it "should allow to update a config value" do
      subject.platform.environment.should be == :development
      subject.platform.environment = :production
      subject.platform.environment.should be == :production
    end

    it "should allow to create new config values" do
      subject.platform.bar = "foo"
      subject.platform.bar.should be == "foo"
    end
  end

  describe "when initializing the config instance with specific values" do
    subject do
      Adhearsion::Configuration.new do
        root "foo", :desc => "Adhearsion application root folder"
        environment :development, :desc => "Active environment. Supported values: development, production, staging, test"
      end
    end

    it "should return the root value" do
      subject.platform.root.should be == "foo"
    end

    it "should return the environment value" do
      subject.platform.environment.should be == :development
    end

    it "should return a description for the platform configuration" do
      Adhearsion.config.description(:platform).should be_instance_of String
    end

    it "should allow to update a config value" do
      subject.platform.environment.should be == :development
      subject.platform.environment = :production
      subject.platform.environment.should be == :production
    end

    it "should allow to create new config values" do
      subject.platform.bar = "bazz"
      subject.platform.bar.should be == "bazz"
    end
  end

  describe "when configuring a non existing object" do
    it "should raise a ConfigurationError" do
      lambda {
        Adhearsion.config.foo.bar = "bazz"
      }.should raise_error Adhearsion::Configuration::ConfigurationError, "Invalid plugin foo"
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
      subject.environment.should be == :development
    end

    describe "if configuration has a named environment" do

      let :config_obj do
        Adhearsion::Configuration.new
      end

      let :env_values do
        config_obj.valid_environments.inject({}) do |hash, k|
          hash[k] = hash.keys.length
          hash
        end
      end

      let :config_object do
        config_obj do
          my_level(-1, :desc => "An index to check the environment value is being retrieved")
        end
      end

      subject do
        config_object.production do |env|
          env.platform.my_level = 0
        end
        config_object.development do |env|
          env.platform.my_level = 1
        end
        config_object.staging do |env|
          env.platform.my_level = 2
        end
        config_object.test do |env|
          env.platform.my_level = 3
        end
        config_object
      end

      it "should return by default the development value" do
        subject.platform.my_level.should be == 1
      end

      [:staging, :production, :test].each do |env|
        it "should return the #{env.to_s} value when environment set to #{env.to_s}" do
          config_object.platform.environment = env
          subject.platform.my_level.should be == env_values[env]
        end
      end
    end
  end

  describe "while defining the environment" do

    after do
      ENV['AHN_ENV'] = nil
      Adhearsion.config = nil
    end

    it "should return 'development' by default" do
      Adhearsion.config.platform.environment.should be == :development
    end

    [:development, :production, :staging, :test].each do |env|
      it "should respond to #{env.to_s}" do
        Adhearsion.config.should respond_to(env)
      end
    end

    context "when the ENV value is valid" do
      [:production, :staging, :test].each do |env|
        it "should override the environment value with #{env.to_s} when set in ENV value" do
          ENV['AHN_ENV'] = env.to_s
          Adhearsion.config.platform.environment.should be == env
        end
      end
    end

    it "should not override the default environment with the ENV value if valid" do
      ENV['AHN_ENV'] = "invalid_value"
      Adhearsion.config.platform.environment.should be == :development
    end

    it "should allow to add a new environment" do
      Adhearsion.config.valid_environment?(:another_environment).should be == false
      Adhearsion.environments << :another_environment
      Adhearsion.config.valid_environment?(:another_environment).should be == true
    end

  end

  describe "while retrieving configuration descriptions" do
    before do
      Adhearsion.config = nil
    end

    subject { Adhearsion.config }

    it "should retrieve a string with the platform configuration" do
      desc = subject.description :platform, :show_values => false
      desc.length.should be > 0
      desc.should match(/^.*environment.*$/)
      desc.should match(/^.*root.*$/)
    end

    it "should retrieve a string with the platform configuration and values" do
      desc = subject.description :platform
      desc.length.should be > 0
      desc.should match(/^.*environment.*:development.*$/)
      desc.should match(/^.*root.*$/)
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
            subject[:name].should be == 'user'
            subject[:password].should be == 'password'
            subject[:host].should be == 'localhost'
          end
        end

        context "using the hash accessor syntax" do
          subject { Adhearsion.config[:my_plugin] }

          it "should have the correct values" do
            subject[:name].should be == 'user'
            subject[:password].should be == 'password'
            subject[:host].should be == 'localhost'
          end
        end

        context "when config has named environments" do
          subject do
            Adhearsion.config do |c|
              c.production do |env|
                env.my_plugin.name = "production"
              end
              c.development do |env|
                env.my_plugin.name = "development"
              end
              c.staging do |env|
                env.my_plugin.name = "staging"
              end
              c.test do |env|
                env.my_plugin.name = "test"
              end
            end
            Adhearsion.config[:my_plugin]
          end

          it "should return the development value by default" do
            Adhearsion.config # initialize
            subject.name.should be == "development"
          end

          [:development, :staging, :production, :test].each do |env|
            it "should return the #{env.to_s} value when environment is set to #{env.to_s}" do
              Adhearsion.config.platform.environment = env
              subject.name.should be == env.to_s
            end
          end
        end
      end

      it "should retrieve a valid plugin description" do
        desc = subject.description :my_plugin
        desc.length.should be > 0
        desc.should match(/^.*name.*user.*$/)
        desc.should match(/^.*password.*password.*$/)
        desc.should match(/^.*host.*localhost.*$/)
      end

      it "should retrieve a valid plugin description with no values" do
        desc = subject.description :my_plugin, :show_values => false
        desc.length.should be > 0
        desc.should match(/^.*name.*$/)
        desc.should match(/^.*password.*$/)
        desc.should match(/^.*host.*$/)
      end

      it "should retrieve both platform and plugin configuration" do
        desc = subject.description :all
        desc.length.should be > 0
        desc.should match(/^.*environment.*:development.*$/)
        desc.should match(/^.*root.*$/)
        desc.should match(/^.*name.*user.*$/)
        desc.should match(/^.*password.*password.*$/)
        desc.should match(/^.*host.*localhost.*$/)
      end

      it "should retrieve both platform and plugin configuration with no values" do
        desc = subject.description :all, :show_values => false
        desc.length.should be > 0
        desc.should match(/^.*Configuration for platform.*$/)
        desc.should match(/^.*environment.*$/)
        desc.should match(/^.*root.*$/)
        desc.should match(/^.*Configuration for my_plugin.*$/)
        desc.should match(/^.*name.*$/)
        desc.should match(/^.*password.*$/)
        desc.should match(/^.*host.*$/)
      end
    end

  end
end
