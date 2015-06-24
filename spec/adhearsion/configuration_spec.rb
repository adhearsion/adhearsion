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
      let(:env) { :development }

      subject do
        Adhearsion::Configuration.new env do
          my_level(-1, :desc => "An index to check the environment value is being retrieved")
        end
      end

      before do
        subject.production do |env|
          env.core.my_level = 0
        end
        subject.development do |env|
          env.core.my_level = 1
        end
        subject.staging do |env|
          env.core.my_level = 2
        end
        subject.test do |env|
          env.core.my_level = 3
        end
      end

      it "should return by default the development value" do
        expect(subject.core.my_level).to eq(1)
      end

      {
        production: 0,
        development: 1,
        staging: 2,
        test: 3,
      }.each do |env, value|
        describe "in #{env} environment" do
          let(:env) { env }

          it "should return the #{env} value" do
            expect(subject.core.my_level).to eq(value)
          end
        end
      end
    end
  end

  describe "while defining the environment" do

    before do
      Adhearsion.config = nil
    end

    after do
      Adhearsion.environment = nil
      Adhearsion.config = nil
    end

    [:development, :production, :staging, :test].each do |env|
      it "should respond to #{env}" do
        expect(Adhearsion.config).to respond_to(env)
      end
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
          let(:env) { :development }

          let(:config) do
            Adhearsion::Configuration.new env do
              my_level(-1, :desc => "An index to check the environment value is being retrieved")
            end
          end

          before do
            config.production do |env|
              env.my_plugin.name = "production"
            end
            config.development do |env|
              env.my_plugin.name = "development"
            end
            config.staging do |env|
              env.my_plugin.name = "staging"
            end
            config.test do |env|
              env.my_plugin.name = "test"
            end
          end

          subject do
            config.my_plugin
          end

          it "should return by default the development value" do
            expect(subject.name).to eq("development")
          end

          [:production, :development, :staging, :test].each do |env, value|
            describe "in #{env} environment" do
              let(:env) { env }

              it "should return the #{env} value" do
                expect(subject.name).to eq(env.to_s)
              end
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
