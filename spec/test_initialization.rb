require File.dirname(__FILE__) + '/test_helper'

context "Adhearsion::Initializer" do
  include InitializerStubs
  # TODO: create a specification for aliases
  
  before :each do
    Adhearsion.send(:remove_const, 'AHN_CONFIG') if Adhearsion.const_defined? 'AHN_CONFIG'
    Adhearsion::AHN_CONFIG = Adhearsion::Configuration.new
  end
  
  test "initialization will start with only a path given" do
    with_new_initializer_with_no_path_changing_behavior do
      Adhearsion::Initializer.new path
    end
  end
 
  test "should create a pid file in the app's path when given 'true' as the pid_file hash key argument" do
    with_new_initializer_with_no_path_changing_behavior do
       flexmock(File).should_receive(:open).once.with(File.join(path, 'adhearsion.pid'), File::CREAT|File::WRONLY, Proc)
       ahn = Adhearsion::Initializer.new path, :pid_file => true
       ahn.pid_file[0, path.length].should.equal(path)
     end
   end
   
   test "should NOT create a pid file in the app's path when given 'false' as the pid_file hash key argument" do
     with_new_initializer_with_no_path_changing_behavior do
       ahn = Adhearsion::Initializer.new path, :pid_file => false
       assert_nil ahn.pid_file
     end
   end
   
   test "should create a pid file in the app's path by default when daemonizing" do
     with_new_initializer_with_no_path_changing_behavior do
       flexmock(File).should_receive(:open).once.with(File.join(path, 'adhearsion.pid'), File::CREAT|File::WRONLY, Proc)
       ahn = Adhearsion::Initializer.new path, :daemon => true
       ahn.pid_file[0, path.size].should.equal(path)
     end
   end
   
   test "should NOT create a pid file in the app's path when daemonizing and :pid_file is given as false" do
     with_new_initializer_with_no_path_changing_behavior do
       ahn = Adhearsion::Initializer.new path, :daemon => true, :pid_file => false
       assert_nil ahn.pid_file
     end
   end
   
   test "should create a designated pid file when supplied a String path as :pid_file" do
     random_file = "/tmp/AHN_TEST_#{rand 100000}.pid"
     with_new_initializer_with_no_path_changing_behavior do
       ahn = Adhearsion::Initializer.new path, :pid_file => random_file
       ahn.pid_file.should.equal(random_file)
       assert File.exists?(random_file)
       File.delete random_file
     end
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
    with_new_initializer_with_no_path_changing_behavior do
      ahn = Adhearsion::Initializer.new path
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
    with_new_initializer_with_no_path_changing_behavior do
      ahn = Adhearsion::Initializer.new path
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