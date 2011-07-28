require 'spec_helper'
require 'adhearsion/cli'

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
    new_tmp_dir.tap do |dir|
      Dir.mkdir dir
      FileUtils.touch dir + "/.ahnrc"
      Dir.mkdir dir + "/components"
    end
  end

  def execute_ahn_command
    Adhearsion::CLI::AhnCommand.execute!
  end

  def executing_ahn_command_should_fail_with(exception)
    flexmock(Adhearsion::CLI::AhnCommand).should_receive(:fail_and_print_usage).with(exception).once
    execute_ahn_command
  end

end

describe 'The Ahn Command helper' do

  include AhnCommandSpecHelper

  it "args are simulated properly" do
    before = ARGV.clone
    simulate_args "create", "/tmp/blah"
    ARGV.should_not be before
  end

  it "STDOUT should be captured" do
    capture_stdout do
      puts "wee"
    end.should == "wee\n"
  end

end

describe "A simulated use of the 'ahn' command" do

  include AhnCommandSpecHelper

  it "USAGE is defined" do
    Adhearsion::CLI::AhnCommand.const_defined?('USAGE').should be true
  end

  before do
    flexmock Adhearsion::ScriptAhnLoader, :in_ahn_application? => true
  end

  it "arguments to 'create' are executed properly" do
    some_path = "/path/somewhere"
    simulate_args "create", some_path
    flexmock(Adhearsion::CLI::AhnCommand::CommandHandler).should_receive(:create).once.with(some_path)
    capture_stdout { Adhearsion::CLI::AhnCommand.execute! }
  end

  it "arguments to 'start' are executed properly properly" do
    some_path = "/tmp/blargh"
    simulate_args "start", some_path
    flexmock(Adhearsion::CLI::AhnCommand::CommandHandler).should_receive(:start).once.with(some_path, :foreground, nil)
    Adhearsion::CLI::AhnCommand.execute!
  end

  it "should execute arguments to 'start' for daemonizing properly" do
    somewhere = "/tmp/blarghh"
    simulate_args "start", 'daemon', somewhere
    flexmock(Adhearsion::CLI::AhnCommand::CommandHandler).should_receive(:start).once.with(somewhere, :daemon, nil)
    Adhearsion::CLI::AhnCommand.execute!
  end

  it "should execute arguments to 'start' for using a console properly" do
    somewhere = "/tmp/blarghh"
    simulate_args "start", 'console', somewhere
    flexmock(Adhearsion::CLI::AhnCommand::CommandHandler).should_receive(:start).once.with(somewhere, :console, nil)
    Adhearsion::CLI::AhnCommand.execute!
  end

  it 'parse_arguments should recognize start with daemon properly' do
    path = '/path/to/somesuch'
    arguments = ['start', 'daemon', path]
    Adhearsion::CLI::AhnCommand.parse_arguments(arguments).should == [:start, path, :daemon, nil]
  end

  it 'should not allow both daemon and console to be specified' do
    path = '/path/to/somesuch'
    arguments = ['start', 'daemon', 'console', path]
    lambda { Adhearsion::CLI::AhnCommand.parse_arguments(arguments) }.should raise_error Adhearsion::CLI::AhnCommand::CommandHandler::CLIException
  end

  it 'should recognize start with daemon and pid file properly' do
    project_path  = '/second/star/on/the/right'
    pid_file_path = '/straight/on/til/morning'
    arguments = ["start", "daemon", project_path, "--pid-file=#{pid_file_path}"]
    Adhearsion::CLI::AhnCommand.parse_arguments(arguments).should == [:start, project_path, :daemon, pid_file_path]
  end

  it 'should recognize start without daemon and with pid file properly' do
    project_path  = '/second/star/on/the/right'
    pid_file_path = '/straight/on/til/morning'
    arguments = ["start", project_path, "--pid-file=#{pid_file_path}"]
    Adhearsion::CLI::AhnCommand.parse_arguments(arguments).should == [:start, project_path, :foreground, pid_file_path]
  end

  it 'parse_arguments should recognize start without daemon properly' do
    path = '/path/to/somewhere'
    arguments = ['start', path]
    Adhearsion::CLI::AhnCommand.parse_arguments(arguments).should == [:start, path, :foreground, nil]
  end

  it "if no path is provided, running Ahn command blows up" do
    lambda { Adhearsion::CLI::AhnCommand.parse_arguments(['start']) }.should raise_error Adhearsion::CLI::AhnCommand::CommandHandler::CLIException
  end

  it "printing the version" do
    capture_stdout do
      simulate_args 'version'
      Adhearsion::CLI::AhnCommand.execute!
    end.should =~ Regexp.new(Regexp.escape(Adhearsion::VERSION::STRING))
  end

  it "printing the help" do
    capture_stdout do
      simulate_args 'help'
      Adhearsion::CLI::AhnCommand.execute!
    end.should =~ Regexp.new(Regexp.escape(Adhearsion::CLI::AhnCommand::USAGE))
  end

  it "reacting to unrecognized commands" do
    simulate_args "alpha", "beta"
    flexmock(Adhearsion::CLI::AhnCommand).should_receive(:fail_and_print_usage).once.and_return
    Adhearsion::CLI::AhnCommand.execute!
  end

  it "giving a path that doesn't contain a project raises an exception" do
    simulate_args "start", "/asjdfas/sndjfabsdfbqwb/qnjwejqbwh"
    executing_ahn_command_should_fail_with Adhearsion::CLI::AhnCommand::CommandHandler::PathInvalid
  end

end

describe "Component-related commands" do

  include AhnCommandSpecHelper


  it "should move a folder from the components/disabled/ folder of an app to the components/ directory if it exists" do
    sandbox      = create_component_sandbox
    disabled_dir = "#{sandbox}/components/disabled/foobar"
    enabled_dir  = "#{sandbox}/components/foobar"

    FileUtils.mkdir_p disabled_dir
    FileUtils.touch disabled_dir + "/foobar.rb"

    flexmock(Dir).should_receive(:pwd).once.and_return disabled_dir

    simulate_args "enable", "component", "foobar"
    capture_stdout { execute_ahn_command }

    File.directory?(disabled_dir).should_not be true
    File.exists?(enabled_dir + "/foobar.rb").should be true
  end

  it "should raise a ComponentError exception if there is no disabled folder" do
    sandbox = create_component_sandbox

    flexmock(Dir).should_receive(:pwd).once.and_return sandbox

    simulate_args "enable", "component", "foo"

    executing_ahn_command_should_fail_with Adhearsion::CLI::AhnCommand::CommandHandler::ComponentError
  end

  it "should raise an exception if the disabled component exists and there's an enabled component of the same name" do
    sandbox = create_component_sandbox

    flexmock(Dir).should_receive(:pwd).once.and_return sandbox

    FileUtils.mkdir_p sandbox + "/disabled/lolcats"
    FileUtils.mkdir_p sandbox + "/lolcats"

    simulate_args "enable", "component", "foo"

    executing_ahn_command_should_fail_with Adhearsion::CLI::AhnCommand::CommandHandler::ComponentError
  end

  it "should raise a PathInvalid error if the current directory does not belong to an Adhearsion app" do
    flexmock(Dir).should_receive("pwd").and_return "/"
    simulate_args "enable", "component", "foo"
    executing_ahn_command_should_fail_with Adhearsion::CLI::AhnCommand::CommandHandler::PathInvalid
  end

  it "should properly create the disabled folder if it doesn't exist when disabling a component" do
    sandbox = create_component_sandbox
    flexmock(Dir).should_receive(:pwd).once.and_return sandbox

    FileUtils.mkdir_p sandbox + "/components/rickroller"

    simulate_args 'disable', 'component', 'rickroller'
    capture_stdout { execute_ahn_command }
    File.directory?(sandbox + "/components/disabled/rickroller").should be true
    File.directory?(sandbox + "/components/rickroller").should be false
  end

  it "should raise an UnknownCommand error when trying to enable a kind of feature which doesn't exist" do
    simulate_args "enable", "bonobo"
    executing_ahn_command_should_fail_with Adhearsion::CLI::AhnCommand::CommandHandler::UnknownCommand
  end

  it "should raise an UnknownCommand error when trying to disable a kind of feature which doesn't exist" do
    simulate_args "disable", "thanksgiving_dinner"
    executing_ahn_command_should_fail_with Adhearsion::CLI::AhnCommand::CommandHandler::UnknownCommand
  end

  it "should raise a ComponentError when the component to disable doesn't exist" do
    sandbox = create_component_sandbox
    flexmock(Dir).should_receive(:pwd).once.and_return sandbox

    simulate_args "disable", "component", "monkeybars"
    executing_ahn_command_should_fail_with Adhearsion::CLI::AhnCommand::CommandHandler::ComponentError
  end

  it "should raise an exception when disabling a component and the component's disabled directory already exists" do
    sandbox = create_component_sandbox

    flexmock(Dir).should_receive(:pwd).once.and_return sandbox

    FileUtils.mkdir_p sandbox + "/disabled/lolcats"
    FileUtils.mkdir_p sandbox + "/lolcats"

    simulate_args "disable", "component", "foo"
    executing_ahn_command_should_fail_with Adhearsion::CLI::AhnCommand::CommandHandler::ComponentError
  end

end

describe 'The "create" command' do

  include AhnCommandSpecHelper

  it "creating a project" do
    the_following_code {
      tmp_path = new_tmp_dir
      simulate_args "create", tmp_path
      RubiGen::Base.default_options.merge! :quiet => true
      # capture_stdout { Adhearsion::CLI::AhnCommand.execute! }
      execute_ahn_command
      File.exists?(File.join(tmp_path, ".ahnrc")).should be true
    }.should_not raise_error
  end

  it "should raise an UnknownCommand if running create with no arguments" do
    simulate_args "create"
    executing_ahn_command_should_fail_with Adhearsion::CLI::AhnCommand::CommandHandler::UnknownCommand
  end

  it "should raise a ComponentError if the name of the component is not a valid Ruby symbol name" do
    bad_names = ["!))", "37signals", "foo bar", "*"]
    bad_names.each do |bad_name|
      simulate_args "create", "component", bad_name
      executing_ahn_command_should_fail_with Adhearsion::CLI::AhnCommand::CommandHandler::ComponentError
    end
  end

  it "should raise a ComponentError if the component name already exists in the folder" do
    sandbox = create_component_sandbox
    Dir.mkdir sandbox + "/components/blehhh"
    flexmock(Dir).should_receive(:pwd).once.and_return sandbox
    simulate_args "create", "component", "blehhh"

    executing_ahn_command_should_fail_with Adhearsion::CLI::AhnCommand::CommandHandler::ComponentError
  end

  it "should create a folder with matching .rb file and .yml file when all guards pass" do
    sandbox = create_component_sandbox
    flexmock(Dir).should_receive(:pwd).once.and_return sandbox

    simulate_args "create", "component", "ohai"
    capture_stdout { execute_ahn_command }

    File.exists?(sandbox + "/components/ohai/lib/ohai.rb").should be true
    File.exists?(sandbox + "/components/ohai/config/ohai.yml").should be true
  end

end
