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
      allow(::Logging::Appenders).to receive_messages(:file => nil)
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

    it "should resolve the log file path to daemonize" do
      stub_behavior_for_initializer_with_no_path_changing_behavior do
        ahn = Adhearsion::Initializer.start
        expect(ahn.resolve_log_file_path).to eq(path + Adhearsion.config.platform.logging.outputters[0])
      end
    end

    it "should resolve the log file path to daemonize when outputters is an Array" do
      Adhearsion.config.platform.logging.outputters = ["log/my_application.log", "log/adhearsion.log"]
      stub_behavior_for_initializer_with_no_path_changing_behavior do
        ahn = Adhearsion::Initializer.start
        expect(ahn.resolve_log_file_path).to eq(path + Adhearsion.config.platform.logging.outputters[0])
      end
    end

    it "should return a valid appenders array" do
      stub_behavior_for_initializer_with_no_path_changing_behavior do
        ahn = Adhearsion::Initializer.start
        appenders = ahn.init_get_logging_appenders
        expect(appenders.size).to eq(2)
        expect(appenders[1]).to be_instance_of Logging::Appenders::Stdout
      end
    end

    it "should initialize properly the log paths" do
      ahn = stub_behavior_for_initializer_with_no_path_changing_behavior do
        Adhearsion::Initializer.start
      end
      expect(Dir).to receive(:mkdir).with("log/")
      ahn.initialize_log_paths
    end

    it "should initialize properly the log paths when outputters is an array" do
      Adhearsion.config.platform.logging.outputters = ["log/my_application.log", "log/test/adhearsion.log"]
      ahn = stub_behavior_for_initializer_with_no_path_changing_behavior do
        Adhearsion::Initializer.start
      end
      expect(Dir).to receive(:mkdir).with("log/").twice
      expect(Dir).to receive(:mkdir).with("log/test/").once
      ahn.initialize_log_paths
    end

    it "should set the adhearsion proc name" do
      stub_behavior_for_initializer_with_no_path_changing_behavior do
        expect(Adhearsion::LinuxProcName).to receive(:set_proc_name).with(Adhearsion.config.platform.process_name)
        Adhearsion::Initializer.start
      end
    end

    it "should update the adhearsion proc name" do
      stub_behavior_for_initializer_with_no_path_changing_behavior do
        Adhearsion::Initializer.start
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
        expect(Adhearsion::Logging).to receive(:start).once.with(kind_of(Array), :info, nil).and_return('')
        Adhearsion::Initializer.start
      end
    end
  end

  describe "#load_lib_folder" do
    before do
      Adhearsion.root = path
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
      allow(File).to receive_messages directory?: true
      expect(Dir).to receive(:chdir).with(File.join(path, "foo")).and_return []
      Adhearsion::Initializer.new.load_lib_folder
    end
  end
end
