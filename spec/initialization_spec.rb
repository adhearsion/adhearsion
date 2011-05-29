require 'spec_helper'

describe "Adhearsion::Initializer" do

  include InitializerStubs
  # TODO: create a specification for aliases

  before :each do
    Adhearsion.send(:remove_const, 'AHN_CONFIG') if Adhearsion.const_defined? 'AHN_CONFIG'
    Adhearsion::AHN_CONFIG = Adhearsion::Configuration.new
  end

  after :each do
    Adhearsion::Events.reinitialize_theatre!
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

  it "should execute gem when .ahnrc contains gem names" do
    stub_behavior_for_initializer_with_no_path_changing_behavior do
      ahn_rc = {
        "gems" => {
          "activerecord" => { "version" => ">= 1.2.0" },
          "twitter" => nil
        },
        # Paths are unnecessary except to make the other part of bootstrap_rc happy.
        "paths"=>{"dialplan"=>"dialplan.rb", "init"=>"config/startup.rb", "events"=>"events.rb",
            "models"=> "models/*.rb"}
      }
      ahn = Adhearsion::Initializer.new path
      flexmock(Adhearsion::Initializer).should_receive(:get_rules_from).once.and_return ahn_rc
      flexmock(ahn).should_receive(:gem).once.with("activerecord", ">= 1.2.0")
      flexmock(ahn).should_receive(:gem).once.with("twitter")
      ahn.start
    end
  end

  it "should require() the lib when .ahnrc contains a require section with one name" do
    stub_behavior_for_initializer_with_no_path_changing_behavior do
      ahn_rc = {
        "gems" => {
          "twitter" => {
            "require" => "sometwitterstuffs"
          }
        },
        # Paths are unnecessary except to make the other part of bootstrap_rc happy.
        "paths"=>{"dialplan"=>"dialplan.rb", "init"=>"config/startup.rb", "events"=>"events.rb",
            "models"=>"models/*.rb"}
      }
      ahn = Adhearsion::Initializer.new path
      flexmock(Adhearsion::Initializer).should_receive(:get_rules_from).once.and_return ahn_rc
      flexstub(ahn).should_receive(:gem).once.with("twitter")
      flexmock(ahn).should_receive(:require).once.with("sometwitterstuffs")
      flexmock(ahn).should_receive(:require).at_least.once.with(String)
      ahn.start
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

  it "should initialze events properly" do
    require 'theatre'
    events_rb = Tempfile.new "events.rb"
    initializer = Adhearsion::Initializer.new("/does/not/matter")
    flexmock(Adhearsion::AHN_CONFIG).should_receive(:files_from_setting).at_least.once.with("paths", "events").
        and_return([events_rb.path])
    flexmock(Adhearsion::Events.framework_theatre).should_receive(:load_events_file).once.with events_rb.path
    flexmock(Adhearsion::Events.framework_theatre).should_receive(:start!).once

    initializer.send :init_events_subsystem
    initializer.send :init_events_file
  end

  private
    def path
      '/any/ole/path'
    end
end

describe "AHN_ROOT" do
  include InitializerStubs
  before(:each) do
    Object.send(:remove_const, :AHN_ROOT) if defined? AHN_ROOT
  end

  it "initializing will create the AHN_ROOT" do
    stub_behavior_for_initializer_with_no_path_changing_behavior do
      ahn = Adhearsion::Initializer.start path
      Object.constants.map(&:to_s).include?("AHN_ROOT").should be true
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

  it "creating the AHN_ROOT will set defaults" do
    stub_behavior_for_initializer_with_no_path_changing_behavior do
      flexstub(Adhearsion::Initializer).new_instances.should_receive(:load).and_return
      ahn = Adhearsion::Initializer.start path
      full_path = File.expand_path(path)
      AHN_ROOT.to_s.should == full_path
      AHN_ROOT.component_path.should == File.join(full_path, "components")
      AHN_ROOT.log_path.should == File.join(full_path, "logs")
      AHN_ROOT.dialplan_path.should == full_path
    end
  end
  private
    def path
      '/any/ole/path'
    end
end
