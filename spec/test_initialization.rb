require File.dirname(__FILE__) + '/test_helper'

context "Adhearsion::Initializer" do
  
  include InitializerStubs
  # TODO: create a specification for aliases
  
  before :each do
    Adhearsion.send(:remove_const, 'AHN_CONFIG') if Adhearsion.const_defined? 'AHN_CONFIG'
    Adhearsion::AHN_CONFIG = Adhearsion::Configuration.new
  end
  
  test "initialization will start with only a path given" do
    stub_behavior_for_initializer_with_no_path_changing_behavior do
      Adhearsion::Initializer.start path
    end
  end
 
  test "should create a pid file in the app's path when given 'true' as the pid_file hash key argument" do
    stub_behavior_for_initializer_with_no_path_changing_behavior do
       flexmock(File).should_receive(:open).with(File.join(path, 'adhearsion.pid'), 'w', Proc).at_least.once
       ahn = Adhearsion::Initializer.start path, :pid_file => true
       ahn.pid_file[0, path.length].should.equal(path)
    end
  end
  
  test "should NOT create a pid file in the app's path when given 'false' as the pid_file hash key argument" do
    stub_behavior_for_initializer_with_no_path_changing_behavior do
      ahn = Adhearsion::Initializer.start path, :pid_file => false
      assert_nil ahn.pid_file
    end
  end
  
  test "should create a pid file in the app's path by default when daemonizing" do
    stub_behavior_for_initializer_with_no_path_changing_behavior do
      flexmock(File).should_receive(:open).once.with(File.join(path, 'adhearsion.pid'), 'w', Proc)
      ahn = Adhearsion::Initializer.start path, :daemon => true
      ahn.pid_file[0, path.size].should.equal(path)
    end
  end
  
  test "should NOT create a pid file in the app's path when daemonizing and :pid_file is given as false" do
    stub_behavior_for_initializer_with_no_path_changing_behavior do
      ahn = Adhearsion::Initializer.start path, :daemon => true, :pid_file => false
      assert_nil ahn.pid_file
    end
  end
  
  test "should execute gem when .ahnrc contains gem names" do
    stub_behavior_for_initializer_with_no_path_changing_behavior do
      ahn_rc = {
        "gems" => {
          "activerecord" => { "version" => ">= 1.2.0" },
          "twitter" => nil
        },
        # Paths are unnecessary except to make the other part of bootstrap_rc happy.
        "paths"=>{"dialplan"=>"dialplan.rb", "init"=>"config/startup.rb", "events"=>"events.rb",
            "models"=>{"directory"=>"models", "pattern"=>"*.rb"}}
      }
      ahn = Adhearsion::Initializer.new path
      flexmock(Adhearsion::Initializer).should_receive(:get_rules_from).once.and_return ahn_rc
      flexmock(ahn).should_receive(:gem).once.with("activerecord", ">= 1.2.0")
      flexmock(ahn).should_receive(:gem).once.with("twitter")
      ahn.start
    end
  end
  
  test "should require() the lib when .ahnrc contains a require section with one name" do
    stub_behavior_for_initializer_with_no_path_changing_behavior do
      ahn_rc = {
        "gems" => {
          "twitter" => {
            "require" => "sometwitterstuffs"
          }
        },
        # Paths are unnecessary except to make the other part of bootstrap_rc happy.
        "paths"=>{"dialplan"=>"dialplan.rb", "init"=>"config/startup.rb", "events"=>"events.rb",
            "models"=>{"directory"=>"models", "pattern"=>"*.rb"}}
      }
      ahn = Adhearsion::Initializer.new path
      flexmock(Adhearsion::Initializer).should_receive(:get_rules_from).once.and_return ahn_rc
      flexstub(ahn).should_receive(:gem).once.with("twitter")
      flexmock(ahn).should_receive(:require).once.with("sometwitterstuffs")
      flexmock(ahn).should_receive(:require).at_least.once.with(String)
      ahn.start
    end
  end
  
  test "should create a designated pid file when supplied a String path as :pid_file" do
    random_file = "/tmp/AHN_TEST_#{rand 100000}.pid"
    stub_behavior_for_initializer_with_no_path_changing_behavior do
      ahn = Adhearsion::Initializer.start path, :pid_file => random_file
      ahn.pid_file.should.equal(random_file)
      assert File.exists?(random_file)
      File.delete random_file
    end
  end
  
  test "should initialze events properly" do
    require 'theatre'
    events_rb = Tempfile.new "events.rb"
    initializer = Adhearsion::Initializer.new("/does/not/matter")
    flexmock(Adhearsion::AHN_CONFIG).should_receive(:files_from_setting).once.with("paths", "events").
        and_return([events_rb.path])
    flexmock(Theatre::Theatre).new_instances.should_receive(:load_events_file).once.with events_rb.path
    flexmock(Adhearsion::Events.framework_theatre).should_receive(:start!).once
    initializer.send(:init_events)
  end
  
  private
    def path
      '/any/ole/path'
    end
end

context "AHN_ROOT" do
  include InitializerStubs
  setup do
    Object.send(:remove_const, :AHN_ROOT) if defined? AHN_ROOT
  end
  
  test "initializing will create the AHN_ROOT" do
    stub_behavior_for_initializer_with_no_path_changing_behavior do
      ahn = Adhearsion::Initializer.start path
      assert Object.constants.include?("AHN_ROOT")
    end
  end
  
  test "swapping out the base_path for the duration of the block" do
    original_base_path = '.'
    temporary_base     = '/foo'
    
    path = Adhearsion::PathString.new(original_base_path)
    path.should.equal original_base_path
    
    path.using_base_path temporary_base do
      path.should.equal temporary_base
    end
    path.should.equal original_base_path
  end

  test "creating the AHN_ROOT will set defaults" do
    stub_behavior_for_initializer_with_no_path_changing_behavior do
      flexstub(Adhearsion::Initializer).new_instances.should_receive(:load).and_return
      ahn = Adhearsion::Initializer.start path
      full_path = File.expand_path(path)
      AHN_ROOT.to_s.should.equal(full_path)
      AHN_ROOT.component_path.should.equal(File.join(full_path, "components"))
      AHN_ROOT.log_path.should.equal(File.join(full_path, "logs"))
      AHN_ROOT.dialplan_path.should.equal(full_path)
    end
  end
  private
    def path
      '/any/ole/path'
    end
end