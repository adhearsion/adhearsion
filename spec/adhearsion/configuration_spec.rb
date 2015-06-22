# encoding: utf-8

require 'spec_helper'
require 'loquacious'

describe Adhearsion::Configuration do

  describe "when initializing the config instance" do
    subject do
      Adhearsion::Configuration.new
    end

    it "should have an empty configuration for the core" do
      expect(subject).to respond_to :core
    end

    it "should have a core configuration object" do
      expect(subject.core).to be_instance_of Loquacious::Configuration
    end

    it "should initialize root to nil" do
      expect(subject.core.root).to be_nil
    end

    it "should initialize logging to level info" do
      expect(subject.core.logging.level).to eq(:info)
    end

    it "should allow to update a config value" do
      expect(subject.core.logging.level).to eq(:info)
      subject.core.logging.level = :error
      expect(subject.core.logging.level).to eq(:error)
    end

    it "should allow to create new config values" do
      subject.core.bar = "foo"
      expect(subject.core.bar).to eq("foo")
    end
  end

  describe "when initializing the config instance with specific values" do
    subject do
      Adhearsion::Configuration.new do
        root "foo", :desc => "Adhearsion application root folder"
      end
    end

    it "should return the root value" do
      expect(subject.core.root).to eq("foo")
    end

    it "should return a description for the core configuration" do
      expect(Adhearsion.config.description(:core)).to be_instance_of String
    end

    it "should allow to update a config value" do
      expect(subject.core.root).to eq("foo")
      subject.core.root = "bar"
      expect(subject.core.root).to eq("bar")
    end

    it "should allow to create new config values" do
      subject.core.bar = "bazz"
      expect(subject.core.bar).to eq("bazz")
    end
  end

  describe "when configuring a non existing object" do
    it "should raise a ConfigurationError" do
      expect {
        Adhearsion.config.foo.bar = "bazz"
      }.to raise_error Adhearsion::Configuration::ConfigurationError, "Invalid plugin foo"
    end
  end

  describe "when accessing the core configuration" do
    after do
      Adhearsion.config = nil
    end

    subject{ Adhearsion.config[:core] }

    it "should return the valid core configuration object" do
      expect(subject).to be_instance_of ::Loquacious::Configuration
    end

    it "should allow to retrieve any core configuration value" do
      expect(subject.type).to eq(:xmpp)
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
          env.core.my_level = 0
        end
        config_object.development do |env|
          env.core.my_level = 1
        end
        config_object.staging do |env|
          env.core.my_level = 2
        end
        config_object.test do |env|
          env.core.my_level = 3
        end
        config_object
      end

      it "should return by default the development value" do
        expect(subject.core.my_level).to eq(1)
      end

      [:staging, :production, :test].each do |env|
        it "should return the #{env.to_s} value when environment set to #{env.to_s}" do
          config_object.core.environment = env
          expect(subject.core.my_level).to eq(env_values[env])
        end
      end
    end
  end

  describe "while defining the environment" do

    before do
      Adhearsion.config = nil
    end

    after do
      ENV['AHN_ENV'] = nil
      Adhearsion.config = nil
    end

    it "should return 'development' by default" do
      expect(Adhearsion.config.core.environment).to eq(:development)
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
          expect(Adhearsion.config.core.environment).to eq(env)
        end
      end
    end

    it "should not override the default environment with the ENV value if valid" do
      ENV['AHN_ENV'] = "invalid_value"
      expect(Adhearsion.config.core.environment).to eq(:development)
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

    it "should retrieve a string with the core configuration" do
      desc = subject.description :core, :show_values => false
      expect(desc.length).to be > 0
      expect(desc).to match(/^.*root.*$/)
    end

    it "should retrieve a string with the core configuration and values" do
      desc = subject.description :core
      expect(desc.length).to be > 0
      expect(desc).to match(/^.*type.*:xmpp.*$/)
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
              Adhearsion.config.core.environment = env
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

      it "should retrieve both core and plugin configuration" do
        desc = subject.description :all
        expect(desc.length).to be > 0
        expect(desc).to match(/^.*root.*$/)
        expect(desc).to match(/^.*name.*user.*$/)
        expect(desc).to match(/^.*password.*password.*$/)
        expect(desc).to match(/^.*host.*localhost.*$/)
      end

      it "should retrieve both core and plugin configuration with no values" do
        desc = subject.description :all, :show_values => false
        expect(desc.length).to be > 0
        expect(desc).to match(/^.*Configuration for core.*$/)
        expect(desc).to match(/^.*root.*$/)
        expect(desc).to match(/^.*Configuration for my_plugin.*$/)
        expect(desc).to match(/^.*name.*$/)
        expect(desc).to match(/^.*password.*$/)
        expect(desc).to match(/^.*host.*$/)
      end
    end

  end
end
