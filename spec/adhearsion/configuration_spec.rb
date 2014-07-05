# encoding: utf-8

require 'spec_helper'
require 'loquacious'

describe Adhearsion::Configuration do

  describe "when initializing the config instance" do
    subject do
      Adhearsion::Configuration.new
    end

    it "should have an empty configuration for the platform" do
      expect(subject).to respond_to :platform
    end

    it "should have a platform configuration object" do
      expect(subject.platform).to be_instance_of Loquacious::Configuration
    end

    it "should initialize root to nil" do
      expect(subject.platform.root).to be_nil
    end

    it "should initialize logging to level info" do
      expect(subject.platform.logging.level).to eq(:info)
    end

    it "should allow to update a config value" do
      expect(subject.platform.environment).to eq(:development)
      subject.platform.environment = :production
      expect(subject.platform.environment).to eq(:production)
    end

    it "should allow to create new config values" do
      subject.platform.bar = "foo"
      expect(subject.platform.bar).to eq("foo")
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
      expect(subject.platform.root).to eq("foo")
    end

    it "should return the environment value" do
      expect(subject.platform.environment).to eq(:development)
    end

    it "should return a description for the platform configuration" do
      expect(Adhearsion.config.description(:platform)).to be_instance_of String
    end

    it "should allow to update a config value" do
      expect(subject.platform.environment).to eq(:development)
      subject.platform.environment = :production
      expect(subject.platform.environment).to eq(:production)
    end

    it "should allow to create new config values" do
      subject.platform.bar = "bazz"
      expect(subject.platform.bar).to eq("bazz")
    end
  end

  describe "when configuring a non existing object" do
    it "should raise a ConfigurationError" do
      expect {
        Adhearsion.config.foo.bar = "bazz"
      }.to raise_error Adhearsion::Configuration::ConfigurationError, "Invalid plugin foo"
    end
  end

  describe "when accessing the platform configuration" do
    after do
      Adhearsion.config = nil
    end

    subject{ Adhearsion.config[:platform] }

    it "should return the valid platform configuration object" do
      expect(subject).to be_instance_of ::Loquacious::Configuration
    end

    it "should allow to retrieve any platform configuration value" do
      expect(subject.environment).to eq(:development)
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
        expect(subject.platform.my_level).to eq(1)
      end

      [:staging, :production, :test].each do |env|
        it "should return the #{env.to_s} value when environment set to #{env.to_s}" do
          config_object.platform.environment = env
          expect(subject.platform.my_level).to eq(env_values[env])
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
      expect(Adhearsion.config.platform.environment).to eq(:development)
    end

    [:development, :production, :staging, :test].each do |env|
      it "should respond to #{env.to_s}" do
        expect(Adhearsion.config).to respond_to(env)
      end
    end

    context "when the ENV value is valid" do
      [:production, :staging, :test].each do |env|
        it "should override the environment value with #{env.to_s} when set in ENV value" do
          ENV['AHN_ENV'] = env.to_s
          expect(Adhearsion.config.platform.environment).to eq(env)
        end
      end
    end

    it "should not override the default environment with the ENV value if valid" do
      ENV['AHN_ENV'] = "invalid_value"
      expect(Adhearsion.config.platform.environment).to eq(:development)
    end

    it "should allow to add a new environment" do
      expect(Adhearsion.config.valid_environment?(:another_environment)).to eq(false)
      Adhearsion.environments << :another_environment
      expect(Adhearsion.config.valid_environment?(:another_environment)).to eq(true)
    end

  end

  describe "while retrieving configuration descriptions" do
    before do
      Adhearsion.config = nil
    end

    subject { Adhearsion.config }

    it "should retrieve a string with the platform configuration" do
      desc = subject.description :platform, :show_values => false
      expect(desc.length).to be > 0
      expect(desc).to match(/^.*environment.*$/)
      expect(desc).to match(/^.*root.*$/)
    end

    it "should retrieve a string with the platform configuration and values" do
      desc = subject.description :platform
      expect(desc.length).to be > 0
      expect(desc).to match(/^.*environment.*:development.*$/)
      expect(desc).to match(/^.*root.*$/)
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
            expect(subject[:name]).to eq('user')
            expect(subject[:password]).to eq('password')
            expect(subject[:host]).to eq('localhost')
          end
        end

        context "using the hash accessor syntax" do
          subject { Adhearsion.config[:my_plugin] }

          it "should have the correct values" do
            expect(subject[:name]).to eq('user')
            expect(subject[:password]).to eq('password')
            expect(subject[:host]).to eq('localhost')
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
            expect(subject.name).to eq("development")
          end

          [:development, :staging, :production, :test].each do |env|
            it "should return the #{env.to_s} value when environment is set to #{env.to_s}" do
              Adhearsion.config.platform.environment = env
              expect(subject.name).to eq(env.to_s)
            end
          end
        end
      end

      it "should retrieve a valid plugin description" do
        desc = subject.description :my_plugin
        expect(desc.length).to be > 0
        expect(desc).to match(/^.*name.*user.*$/)
        expect(desc).to match(/^.*password.*password.*$/)
        expect(desc).to match(/^.*host.*localhost.*$/)
      end

      it "should retrieve a valid plugin description with no values" do
        desc = subject.description :my_plugin, :show_values => false
        expect(desc.length).to be > 0
        expect(desc).to match(/^.*name.*$/)
        expect(desc).to match(/^.*password.*$/)
        expect(desc).to match(/^.*host.*$/)
      end

      it "should retrieve both platform and plugin configuration" do
        desc = subject.description :all
        expect(desc.length).to be > 0
        expect(desc).to match(/^.*environment.*:development.*$/)
        expect(desc).to match(/^.*root.*$/)
        expect(desc).to match(/^.*name.*user.*$/)
        expect(desc).to match(/^.*password.*password.*$/)
        expect(desc).to match(/^.*host.*localhost.*$/)
      end

      it "should retrieve both platform and plugin configuration with no values" do
        desc = subject.description :all, :show_values => false
        expect(desc.length).to be > 0
        expect(desc).to match(/^.*Configuration for platform.*$/)
        expect(desc).to match(/^.*environment.*$/)
        expect(desc).to match(/^.*root.*$/)
        expect(desc).to match(/^.*Configuration for my_plugin.*$/)
        expect(desc).to match(/^.*name.*$/)
        expect(desc).to match(/^.*password.*$/)
        expect(desc).to match(/^.*host.*$/)
      end
    end

  end
end
