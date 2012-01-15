require 'spec_helper'

describe Adhearsion::Initializer do

  include InitializerStubs
  # TODO: create a specification for aliases

  let :path do
    '/any/ole/path/'
  end

  before do
    Adhearsion::Logging.reset
    flexmock(Adhearsion::Initializer::Logging).should_receive(:start).once.and_return('')
    flexmock(::Logging::Appenders::File).should_receive(:assert_valid_logfile).and_return(true)
    flexmock(::Logging::Appenders).should_receive(:file).and_return(nil)
    Adhearsion.config = nil
  end

  after do
    Adhearsion::Events.reinitialize_queue!
  end

  after :all do
    Adhearsion::Logging.reset
    Adhearsion::Initializer::Logging.start
    Adhearsion::Logging.silence!
  end

  it "initialization will start with only a path given" do
    stub_behavior_for_initializer_with_no_path_changing_behavior do
      Adhearsion::Initializer.start path
    end
  end

  it "should create a pid file in the app's path when given 'true' as the pid_file hash key argument" do
    stub_behavior_for_initializer_with_no_path_changing_behavior do
       flexmock(File).should_receive(:open).with(File.join(path, 'adhearsion.pid'), 'w', Proc).at_least.once
       ahn = Adhearsion::Initializer.start path, :pid_file => true
       ahn.pid_file[0, path.length].should == path
    end
  end

  it "should NOT create a pid file in the app's path when given 'false' as the pid_file hash key argument" do
    stub_behavior_for_initializer_with_no_path_changing_behavior do
      ahn = Adhearsion::Initializer.start path, :pid_file => false
      ahn.pid_file.should be nil
    end
  end

  it "should create a pid file in the app's path by default when daemonizing" do
    stub_behavior_for_initializer_with_no_path_changing_behavior do
      flexmock(File).should_receive(:open).once.with(File.join(path, 'adhearsion.pid'), 'w', Proc)
      ahn = Adhearsion::Initializer.start path, :mode => :daemon
      ahn.pid_file[0, path.size].should == path
    end
  end

  it "should NOT create a pid file in the app's path when daemonizing and :pid_file is given as false" do
    stub_behavior_for_initializer_with_no_path_changing_behavior do
      ahn = Adhearsion::Initializer.start path, :daemon => true, :pid_file => false
      ahn.pid_file.should be nil
    end
  end

  it "should create a designated pid file when supplied a String path as :pid_file" do
    random_file = "/tmp/AHN_TEST_#{rand 100000}.pid"
    stub_behavior_for_initializer_with_no_path_changing_behavior do
      ahn = Adhearsion::Initializer.start path, :pid_file => random_file
      ahn.pid_file.should be(random_file)
      File.exists?(random_file).should be true
      File.delete random_file
    end
  end

  it "should resolve the log file path to daemonize" do
    stub_behavior_for_initializer_with_no_path_changing_behavior do
       flexmock(File).should_receive(:open).with(File.join(path, 'adhearsion.pid'), 'w', Proc).at_least.once
       ahn = Adhearsion::Initializer.start path, :pid_file => true
       ahn.resolve_log_file_path.should == path + Adhearsion.config.platform.logging.outputters[0]
    end
  end

  it "should resolve the log file path to daemonize when outputters is an Array" do
    Adhearsion.config.platform.logging.outputters = ["log/my_application.log", "log/adhearsion.log"]
    stub_behavior_for_initializer_with_no_path_changing_behavior do
       flexmock(File).should_receive(:open).with(File.join(path, 'adhearsion.pid'), 'w', Proc).at_least.once
       ahn = Adhearsion::Initializer.start path, :pid_file => true
       ahn.resolve_log_file_path.should == path + Adhearsion.config.platform.logging.outputters[0]
    end
  end

  it "should return a valid appenders array" do
    stub_behavior_for_initializer_with_no_path_changing_behavior do
       flexmock(File).should_receive(:open).with(File.join(path, 'adhearsion.pid'), 'w', Proc).at_least.once
       ahn = Adhearsion::Initializer.start path, :pid_file => true
       appenders = ahn.init_get_logging_appenders
       appenders.should have(2).items
       appenders[1].should be_instance_of Logging::Appenders::Stdout
    end
  end

  it "should initialize properly the log paths" do
    ahn = stub_behavior_for_initializer_with_no_path_changing_behavior do
      flexmock(File).should_receive(:open).with(File.join(path, 'adhearsion.pid'), 'w', Proc).at_least.once
      Adhearsion::Initializer.start path, :pid_file => true
    end
    flexmock(Dir).should_receive(:mkdir).with("log/")
    ahn.initialize_log_paths
  end

  it "should initialize properly the log paths when outputters is an array" do
    Adhearsion.config.platform.logging.outputters = ["log/my_application.log", "log/test/adhearsion.log"]
    ahn = stub_behavior_for_initializer_with_no_path_changing_behavior do
      flexmock(File).should_receive(:open).with(File.join(path, 'adhearsion.pid'), 'w', Proc).at_least.once
      Adhearsion::Initializer.start path, :pid_file => true
    end
    flexmock(Dir).should_receive(:mkdir).with("log/").twice
    flexmock(Dir).should_receive(:mkdir).with("log/test/").once
    ahn.initialize_log_paths
  end
end

describe "Initializing logger" do
  include InitializerStubs
  let :path do
    '/any/ole/path/'
  end

  before do
    Adhearsion::Logging.reset
    flexmock(::Logging::Appenders::File).should_receive(:assert_valid_logfile).and_return(true)
    flexmock(::Logging::Appenders).should_receive(:file).and_return(nil)
    Adhearsion.config = nil
  end

  after :all do
    Adhearsion::Logging.reset
    Adhearsion::Initializer::Logging.start
    Adhearsion::Logging.silence!
    Adhearsion::Events.reinitialize_queue!
  end

  it "should start logging with valid parameters" do
    stub_behavior_for_initializer_with_no_path_changing_behavior do
      flexmock(File).should_receive(:open).with(File.join(path, 'adhearsion.pid'), 'w', Proc).at_least.once
      flexmock(Adhearsion::Initializer::Logging).should_receive(:start).once.with(Array, :info, nil).and_return('')
      Adhearsion::Initializer.start path, :pid_file => true
    end
  end
end

describe "Adhearsion::Initializer#load_lib_folder" do

  let :path do
    '/any/ole/path'
  end

  before do
    Adhearsion.ahn_root = path
  end

  it "should load the contents of lib directory" do
    flexmock(Dir).should_receive(:chdir).with("/any/ole/path/lib", Proc).and_return []
    Adhearsion::Initializer.new(path).load_lib_folder
  end

  it "should return false if folder does not exist" do
    Adhearsion::Initializer.new(path).load_lib_folder.should == false
  end

  it "should return false and not load any file if config folder is set to nil" do
    Adhearsion.config.platform.lib = nil
    Adhearsion::Initializer.new(path).load_lib_folder.should == false
  end

  it "should load the contents of the preconfigured directory" do
    Adhearsion.config.platform.lib = "foo"
    flexmock(Dir).should_receive(:chdir).with("/any/ole/path/foo", Proc).and_return []
    Adhearsion::Initializer.new(path).load_lib_folder
  end
end

describe "Adhearsion.ahn_root" do

  include InitializerStubs

  before do
    Adhearsion.ahn_root = nil
  end

  it "initializing will create the ahn_root" do
    flexmock(Adhearsion::Initializer::Logging).should_receive(:start).once.and_return('')
    flexmock(::Logging::Appenders::File).should_receive(:assert_valid_logfile).and_return(true)
    flexmock(::Logging::Appenders).should_receive(:file).and_return(nil)

    stub_behavior_for_initializer_with_no_path_changing_behavior do
      ahn = Adhearsion::Initializer.start path
      Adhearsion.config.root.should_not be_nil
    end
  end

  it "swapping out the base_path for the duration of the block" do
    original_base_path = '.'
    temporary_base     = '/foo'

    path = Adhearsion::PathString.new(original_base_path)
    path.should == original_base_path

    path.using_base_path temporary_base do
      path.should == temporary_base
    end
    path.should == original_base_path
  end

  it "creating the Adhearsion.config.root will set defaults" do
    flexmock(Adhearsion::Initializer::Logging).should_receive(:start).once.and_return('')
    flexmock(::Logging::Appenders::File).should_receive(:assert_valid_logfile).and_return(true)
    flexmock(::Logging::Appenders).should_receive(:file).and_return(nil)

    stub_behavior_for_initializer_with_no_path_changing_behavior do
      flexstub(Adhearsion::Initializer).new_instances.should_receive(:load).and_return
      ahn = Adhearsion::Initializer.start path
      full_path = File.expand_path(path)
      Adhearsion.config.root.to_s.should == full_path
      Adhearsion.config.root.component_path.should == File.join(full_path, "components")
      Adhearsion.config.root.log_path.should == File.join(full_path, "logs")
      Adhearsion.config.root.dialplan_path.should == full_path
    end
  end
  private
    def path
      '/any/ole/path'
    end
end
