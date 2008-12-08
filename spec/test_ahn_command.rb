require File.dirname(__FILE__) + "/test_helper"
require 'adhearsion/cli'

context 'The Ahn Command helper' do
  
  include AhnCommandSpecHelper
  
  test "args are simulated properly" do
    before = ARGV.clone
    simulate_args "create", "/tmp/blah"
    ARGV.should.not.equal before
  end
  
  test "STDOUT should be captured" do
    capture_stdout do
      puts "wee"
    end.should.equal "wee\n"
  end
  
end

context "A simulated use of the 'ahn' command" do
  
  include AhnCommandSpecHelper
  
  test "USAGE is defined" do
    assert Adhearsion::CLI::AhnCommand.const_defined?('USAGE')
  end
  
  test "arguments to 'create' are executed properly" do
    some_path = "/path/somewhere"
    simulate_args "create", some_path
    flexmock(Adhearsion::CLI::AhnCommand::CommandHandler).should_receive(:create).once.with(some_path)
    capture_stdout { Adhearsion::CLI::AhnCommand.execute! }
  end
  
  test "arguments to 'start' are executed properly properly" do
    some_path = "/tmp/blargh"
    simulate_args "start", some_path
    flexmock(Adhearsion::CLI::AhnCommand::CommandHandler).should_receive(:start).once.with(some_path, false, nil)
    Adhearsion::CLI::AhnCommand.execute!
  end
  
  test "should execute arguments to 'start' for daemonizing properly" do
    somewhere = "/tmp/blarghh"
    simulate_args "start", 'daemon', somewhere
    flexmock(Adhearsion::CLI::AhnCommand::CommandHandler).should_receive(:start).once.with(somewhere, true, nil)
    Adhearsion::CLI::AhnCommand.execute!
  end
  
  test 'parse_arguments should recognize start with daemon properly' do
    path = '/path/to/somesuch'
    arguments = ["start", 'daemon', path]
    Adhearsion::CLI::AhnCommand.parse_arguments(arguments).should == [:start, path, true, nil]
  end
  
  test 'should recognize start with daemon and pid file properly' do
    project_path  = '/second/star/on/the/right'
    pid_file_path = '/straight/on/til/morning'
    arguments = ["start", "daemon", project_path, "--pid-file=#{pid_file_path}"]
    Adhearsion::CLI::AhnCommand.parse_arguments(arguments).should == [:start, project_path, true, pid_file_path]
  end
  
  test 'parse_arguments should recognize start without daemon properly' do
    path = '/path/to/somewhere'
    arguments = ['start', path]
    Adhearsion::CLI::AhnCommand.parse_arguments(arguments).should == [:start, path, false, nil]
  end
  
  test "if no path is provided, running Ahn command blows up" do
    the_following_code {
      Adhearsion::CLI::AhnCommand.parse_arguments(['start'])
    }.should.raise Adhearsion::CLI::AhnCommand::CommandHandler::UnknownCommand
  end
  
  test "printing the version" do
    capture_stdout do
      simulate_args 'version'
      Adhearsion::CLI::AhnCommand.execute!
    end.should =~ Regexp.new(Regexp.escape(Adhearsion::VERSION::STRING))
  end
  
  test "printing the help" do
    capture_stdout do
      simulate_args 'help'
      Adhearsion::CLI::AhnCommand.execute!
    end.should =~ Regexp.new(Regexp.escape(Adhearsion::CLI::AhnCommand::USAGE))
  end
  
  test "reacting to unrecognized commands" do
    the_following_code {
      simulate_args "alpha", "beta"
      Adhearsion::CLI::AhnCommand.execute!
    }.should.raise(Adhearsion::CLI::AhnCommand::CommandHandler::UnknownCommand)
  end
  
  test "giving a path that doesn't contain a project raises an exception" do
    the_following_code {
      simulate_args "start", "/asjdfas/sndjfabsdfbqwb/qnjwejqbwh"
      Adhearsion::CLI::AhnCommand.execute!
    }.should.raise(Adhearsion::CLI::AhnCommand::CommandHandler::PathInvalid)
  end
  
end

context "Component-related commands" do
  
  include AhnCommandSpecHelper
  
  test "should move a folder from the components/disabled/ folder of an app to the components/ directory if it exists" do
    sandbox      = create_component_sandbox
    disabled_dir = "#{sandbox}/components/disabled/foobar"
    enabled_dir  = "#{sandbox}/components/foobar"
    
    FileUtils.mkdir_p disabled_dir
    FileUtils.touch disabled_dir + "/foobar.rb"
    
    flexmock(Dir).should_receive(:pwd).once.and_return disabled_dir
    
    simulate_args "enable", "component", "foobar"
    capture_stdout { Adhearsion::CLI::AhnCommand.execute! }
    
    File.directory?(disabled_dir).should.not.equal true
    File.exists?(enabled_dir + "/foobar.rb").should.equal true
  end
  
  test "should raise a ComponentError exception if there is no disabled folder" do
    sandbox = create_component_sandbox
    
    flexmock(Dir).should_receive(:pwd).once.and_return sandbox
    
    simulate_args "enable", "component", "foo"
    
    the_following_code {
      Adhearsion::CLI::AhnCommand.execute!
    }.should.raise Adhearsion::CLI::AhnCommand::CommandHandler::ComponentError
  end
  
  test "should raise an exception if the disabled component exists and there's an enabled component of the same name" do
    sandbox = create_component_sandbox
    
    flexmock(Dir).should_receive(:pwd).once.and_return sandbox
    
    FileUtils.mkdir_p sandbox + "/disabled/lolcats"
    FileUtils.mkdir_p sandbox + "/lolcats"
    
    simulate_args "enable", "component", "foo"
    
    the_following_code {
      Adhearsion::CLI::AhnCommand.execute!
    }.should.raise Adhearsion::CLI::AhnCommand::CommandHandler::ComponentError
  end
  
  test "should raise a PathInvalid error if the current directory does not belong to an Adhearsion app" do
    flexmock(Dir).should_receive("pwd").and_return "/"
    simulate_args "enable", "component", "foo"
    the_following_code {
      Adhearsion::CLI::AhnCommand.execute!
    }.should.raise Adhearsion::CLI::AhnCommand::CommandHandler::PathInvalid
  end 
  
  test "should properly create the disabled folder if it doesn't exist when disabling a component" do
    sandbox = create_component_sandbox
    flexmock(Dir).should_receive(:pwd).once.and_return sandbox
    
    FileUtils.mkdir_p sandbox + "/components/rickroller"
    
    simulate_args 'disable', 'component', 'rickroller'
    capture_stdout { Adhearsion::CLI::AhnCommand.execute! }
    File.directory?(sandbox + "/components/disabled/rickroller").should.equal true
    File.directory?(sandbox + "/components/rickroller").should.equal false
  end
  
  test "should raise an UnknownCommand error when trying to enable a kind of feature which doesn't exist" do
    simulate_args "enable", "bonobo"
    the_following_code {
      Adhearsion::CLI::AhnCommand.execute!
    }.should.raise Adhearsion::CLI::AhnCommand::CommandHandler::UnknownCommand
  end
  
  test "should raise an UnknownCommand error when trying to disable a kind of feature which doesn't exist" do
    simulate_args "disable", "thanksgiving_dinner"
    the_following_code {
      Adhearsion::CLI::AhnCommand.execute!
    }.should.raise Adhearsion::CLI::AhnCommand::CommandHandler::UnknownCommand
  end
  
  test "should raise a ComponentError when the component to disable doesn't exist" do
    sandbox = create_component_sandbox
    flexmock(Dir).should_receive(:pwd).once.and_return sandbox
    
    simulate_args "disable", "component", "monkeybars"
    the_following_code {
      Adhearsion::CLI::AhnCommand.execute!
    }.should.raise Adhearsion::CLI::AhnCommand::CommandHandler::ComponentError
  end
  
  test "should raise an exception when disabling a component and the component's disabled directory already exists" do
    sandbox = create_component_sandbox
    
    flexmock(Dir).should_receive(:pwd).once.and_return sandbox
    
    FileUtils.mkdir_p sandbox + "/disabled/lolcats"
    FileUtils.mkdir_p sandbox + "/lolcats"
    
    simulate_args "disable", "component", "foo"
    
    the_following_code {
      Adhearsion::CLI::AhnCommand.execute!
    }.should.raise Adhearsion::CLI::AhnCommand::CommandHandler::ComponentError
  end
  
end

context 'The "create" command' do
  
  include AhnCommandSpecHelper
  
  test "creating a project" do
    the_following_code {
      tmp_path = new_tmp_dir
      simulate_args "create", tmp_path
      RubiGen::Base.default_options.merge! :quiet => true
      # capture_stdout { Adhearsion::CLI::AhnCommand.execute! }
      Adhearsion::CLI::AhnCommand.execute!
      File.exists?(File.join(tmp_path, ".ahnrc")).should.equal true
    }.should.not.raise
  end
  
  test "should raise a PathInvalid error if the given directory does not belong to an Adhearsion app" do
    simulate_args "create", "component", "foo"
    the_following_code {
      Adhearsion::CLI::AhnCommand.execute!
    }.should.raise Adhearsion::CLI::AhnCommand::CommandHandler::PathInvalid
  end
  
  test "should raise an UnknownCommand if running create with no arguments" do
    simulate_args "create"
    the_following_code {
      Adhearsion::CLI::AhnCommand.execute!
    }.should.raise Adhearsion::CLI::AhnCommand::CommandHandler::UnknownCommand
  end
  
  test "should raise a ComponentError if the name of the component is not a valid Ruby symbol name" do
    bad_names = ["!))", "37signals", "foo bar", "*"]
    bad_names.each do |bad_name|
      simulate_args "create", "component", bad_name
      the_following_code {
        Adhearsion::CLI::AhnCommand.execute!
      }.should.raise Adhearsion::CLI::AhnCommand::CommandHandler::ComponentError
    end
  end
  
  test "should raise a ComponentError if the component name already exists in the folder" do
    sandbox = create_component_sandbox
    Dir.mkdir sandbox + "/components/blehhh"
    flexmock(Dir).should_receive(:pwd).once.and_return sandbox
    simulate_args "create", "component", "blehhh"
    the_following_code {
      Adhearsion::CLI::AhnCommand.execute!
    }.should.raise Adhearsion::CLI::AhnCommand::CommandHandler::ComponentError
  end
  
  test "should create a folder with matching .rb file and a config.yml file when all guards pass" do
    sandbox = create_component_sandbox
    flexmock(Dir).should_receive(:pwd).once.and_return sandbox
    
    simulate_args "create", "component", "ohai"
    Adhearsion::CLI::AhnCommand.execute!
    
    File.exists?(sandbox + "/components/ohai/ohai.rb").should.equal true
    File.exists?(sandbox + "/components/ohai/config.yml").should.equal true
  end
  
end

BEGIN {
  module AhnCommandSpecHelper
    
    def simulate_args(*args)
      ARGV.clear
      ARGV.concat args
    end
    
    def capture_stdout(&block)
      old = $stdout
      $stdout = io = StringIO.new
      yield
    ensure
      $stdout = old
      return io.string
    end

    def new_tmp_dir(filename=new_guid)
      File.join Dir.tmpdir, filename
    end
 
    def create_component_sandbox
      returning new_tmp_dir do |dir|
        Dir.mkdir dir
        FileUtils.touch dir + "/.ahnrc"
        Dir.mkdir dir + "/components"
      end
    end
    
  end
}
