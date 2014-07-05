# encoding: utf-8

require 'spec_helper'

describe Adhearsion::Initializer do

  include InitializerStubs
  # TODO: create a specification for aliases

  let(:path) { "#{Dir.pwd}/" }

  describe "#start" do
    before do
      ::Logging.reset
      expect(Adhearsion::Logging).to receive(:start).once.and_return('')
      ::Logging::Appenders.stub(:file => nil)
      Adhearsion.config = nil
    end

    after do
      Adhearsion::Events.reinitialize_queue!
    end

    after :all do
      ::Logging.reset
      Adhearsion::Logging.start
      Adhearsion::Logging.silence!
    end

    it "initialization will start with no options" do
      stub_behavior_for_initializer_with_no_path_changing_behavior do
        Adhearsion::Initializer.start
      end
    end

    it "should start the stats aggregator" do
      expect(Adhearsion).to receive(:statistics).at_least(:once)
      stub_behavior_for_initializer_with_no_path_changing_behavior do
        Adhearsion::Initializer.start
      end
    end

    it "should create a pid file in the app's path when given 'true' as the pid_file hash key argument" do
      stub_behavior_for_initializer_with_no_path_changing_behavior do
        expect(File).to receive(:open).with(File.join(path, 'adhearsion.pid'), 'w').at_least(:once)
        ahn = Adhearsion::Initializer.start :pid_file => true
        expect(ahn.pid_file[0, path.length]).to eq(path)
      end
    end

    it "should NOT create a pid file in the app's path when given 'false' as the pid_file hash key argument" do
      stub_behavior_for_initializer_with_no_path_changing_behavior do
        ahn = Adhearsion::Initializer.start :pid_file => false
        expect(ahn.pid_file).to be nil
      end
    end

    it "should create a pid file in the app's path by default when daemonizing" do
      stub_behavior_for_initializer_with_no_path_changing_behavior do
        expect(Adhearsion::CustomDaemonizer).to receive(:daemonize).and_yield '123'
        expect(File).to receive(:open).once.with(File.join(path, 'adhearsion.pid'), 'w')
        ahn = Adhearsion::Initializer.start :mode => :daemon
        expect(ahn.pid_file[0, path.size]).to eq(path)
      end
    end

    it "should NOT create a pid file in the app's path when daemonizing and :pid_file is given as false" do
      stub_behavior_for_initializer_with_no_path_changing_behavior do
        expect(Adhearsion::CustomDaemonizer).to receive(:daemonize).and_yield '123'
        ahn = Adhearsion::Initializer.start :mode => :daemon, :pid_file => false
        expect(ahn.pid_file).to be nil
      end
    end

    it "should create a designated pid file when supplied a String path as :pid_file" do
      random_file = "/tmp/AHN_TEST_#{rand 100000}.pid"
      stub_behavior_for_initializer_with_no_path_changing_behavior do
        ahn = Adhearsion::Initializer.start :pid_file => random_file
        expect(ahn.pid_file).to eq(random_file)
        expect(File.exists?(random_file)).to be true
        File.delete random_file
      end
    end

    it "should resolve the log file path to daemonize" do
      stub_behavior_for_initializer_with_no_path_changing_behavior do
        expect(File).to receive(:open).with(File.join(path, 'adhearsion.pid'), 'w').at_least(:once)
        ahn = Adhearsion::Initializer.start :pid_file => true
        expect(ahn.resolve_log_file_path).to eq(path + Adhearsion.config.platform.logging.outputters[0])
      end
    end

    it "should resolve the log file path to daemonize when outputters is an Array" do
      Adhearsion.config.platform.logging.outputters = ["log/my_application.log", "log/adhearsion.log"]
      stub_behavior_for_initializer_with_no_path_changing_behavior do
        expect(File).to receive(:open).with(File.join(path, 'adhearsion.pid'), 'w').at_least(:once)
        ahn = Adhearsion::Initializer.start :pid_file => true
        expect(ahn.resolve_log_file_path).to eq(path + Adhearsion.config.platform.logging.outputters[0])
      end
    end

    it "should return a valid appenders array" do
      stub_behavior_for_initializer_with_no_path_changing_behavior do
        expect(File).to receive(:open).with(File.join(path, 'adhearsion.pid'), 'w').at_least(:once)
        ahn = Adhearsion::Initializer.start :pid_file => true
        appenders = ahn.init_get_logging_appenders
        expect(appenders.size).to eq(2)
        expect(appenders[1]).to be_instance_of Logging::Appenders::Stdout
      end
    end

    it "should initialize properly the log paths" do
      ahn = stub_behavior_for_initializer_with_no_path_changing_behavior do
        expect(File).to receive(:open).with(File.join(path, 'adhearsion.pid'), 'w').at_least(:once)
        Adhearsion::Initializer.start :pid_file => true
      end
      expect(Dir).to receive(:mkdir).with("log/")
      ahn.initialize_log_paths
    end

    it "should initialize properly the log paths when outputters is an array" do
      Adhearsion.config.platform.logging.outputters = ["log/my_application.log", "log/test/adhearsion.log"]
      ahn = stub_behavior_for_initializer_with_no_path_changing_behavior do
        expect(File).to receive(:open).with(File.join(path, 'adhearsion.pid'), 'w').at_least(:once)
        Adhearsion::Initializer.start :pid_file => true
      end
      expect(Dir).to receive(:mkdir).with("log/").twice
      expect(Dir).to receive(:mkdir).with("log/test/").once
      ahn.initialize_log_paths
    end

    it "should set the adhearsion proc name" do
      stub_behavior_for_initializer_with_no_path_changing_behavior do
        expect(File).to receive(:open).with(File.join(path, 'adhearsion.pid'), 'w').at_least(:once)
        expect(Adhearsion::LinuxProcName).to receive(:set_proc_name).with(Adhearsion.config.platform.process_name)
        Adhearsion::Initializer.start :pid_file => true
      end
    end

    it "should update the adhearsion proc name" do
      stub_behavior_for_initializer_with_no_path_changing_behavior do
        Adhearsion::Initializer.start :pid_file => true
      end
      expect($0).to eq(Adhearsion.config.platform.process_name)
    end
  end

  describe "Initializing logger" do
    before do
      ::Logging.reset
      expect(::Logging::Appenders).to receive(:file).and_return(nil)
      Adhearsion.config = nil
    end

    after :all do
      ::Logging.reset
      Adhearsion::Logging.start
      Adhearsion::Logging.silence!
      Adhearsion::Events.reinitialize_queue!
    end

    it "should start logging with valid parameters" do
      stub_behavior_for_initializer_with_no_path_changing_behavior do
        expect(File).to receive(:open).with(File.join(path, 'adhearsion.pid'), 'w').at_least(:once)
        expect(Adhearsion::Logging).to receive(:start).once.with(kind_of(Array), :info, nil).and_return('')
        Adhearsion::Initializer.start :pid_file => true
      end
    end
  end

  describe "#load_lib_folder" do
    before do
      Adhearsion.ahn_root = path
    end

    it "should load the contents of lib directory" do
      expect(Dir).to receive(:chdir).with(File.join(path, "lib")).and_return []
      Adhearsion::Initializer.new.load_lib_folder
    end

    it "should return false if folder does not exist" do
      Adhearsion.config.platform.lib = "my_random_lib_directory"
      expect(Adhearsion::Initializer.new.load_lib_folder).to eq(false)
    end

    it "should return false and not load any file if config folder is set to nil" do
      Adhearsion.config.platform.lib = nil
      expect(Adhearsion::Initializer.new.load_lib_folder).to eq(false)
    end

    it "should load the contents of the preconfigured directory" do
      Adhearsion.config.platform.lib = "foo"
      File.stub directory?: true
      expect(Dir).to receive(:chdir).with(File.join(path, "foo")).and_return []
      Adhearsion::Initializer.new.load_lib_folder
    end
  end
end

describe "Updating RAILS_ENV variable" do
  include InitializerStubs

  before do
    ::Logging.reset
    expect(Adhearsion::Logging).to receive(:start).once.and_return('')
    expect(::Logging::Appenders).to receive(:file).and_return(nil)
    Adhearsion.config = nil
  end

  before do
    ENV['RAILS_ENV'] = nil
    ENV['AHN_ENV'] = nil
  end

  after :all do
    ENV['RAILS_ENV'] = nil
    ENV['AHN_ENV'] = nil
  end

  describe "when neither RAILS_ENV nor AHN_ENV are set" do
    [:development, :production, :staging, :test].each do |env|
      it "should set the RAILS_ENV to #{env.to_s} when Adhearsion environment is set to #{env.to_s}" do
        ahn = nil
        stub_behavior_for_initializer_with_no_path_changing_behavior do
          Adhearsion.config.platform.environment = env
          ahn = Adhearsion::Initializer.start
        end
        ahn.update_rails_env_var
        expect(ENV['RAILS_ENV']).to eq(env.to_s)
      end
    end
  end

  context "when RAILS_ENV is set" do
    before do
      ENV['RAILS_ENV'] = "test"
    end

    context "if AHN_ENV is set" do
      it "should preserve the RAILS_ENV value" do
        ENV['AHN_ENV'] = "production"
        ahn = nil
        stub_behavior_for_initializer_with_no_path_changing_behavior do
          ahn = Adhearsion::Initializer.start
        end
        ahn.update_rails_env_var
        expect(ENV['RAILS_ENV']).to eq("test")
      end
    end

    context "if AHN_ENV is unset" do
      it "should preserve the RAILS_ENV value" do
        ahn = nil
        stub_behavior_for_initializer_with_no_path_changing_behavior do
          ahn = Adhearsion::Initializer.start
        end
        ahn.update_rails_env_var
        expect(ENV['RAILS_ENV']).to eq("test")
      end
    end
  end

  context "when RAILS_ENV is unset and AHN_ENV is set" do
    before do
      ENV['AHN_ENV'] = "production"
    end

    it "should define the RAILS_ENV value with the AHN_ENV value" do
      ahn = nil
      stub_behavior_for_initializer_with_no_path_changing_behavior do
        ahn = Adhearsion::Initializer.start
      end
      ahn.update_rails_env_var
      expect(ENV['RAILS_ENV']).to eq("production")
    end
  end

end
