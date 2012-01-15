require 'spec_helper'
require 'adhearsion/cli'

describe Adhearsion::CLI::AhnCommand do

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

  def new_tmp_dir(filename = UUID.new.generate)
    File.join Dir.tmpdir, filename
  end

  def create_component_sandbox
    new_tmp_dir.tap do |dir|
      Dir.mkdir dir
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

  before { pending }

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
    end.should =~ Regexp.new(Regexp.escape(Adhearsion::VERSION))
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

  describe 'The "create" command' do
    it "creating a project" do
      the_following_code {
        tmp_path = new_tmp_dir
        simulate_args "create", tmp_path
        # capture_stdout { Adhearsion::CLI::AhnCommand.execute! }
        execute_ahn_command
      }.should_not raise_error
    end

    it "should raise an UnknownCommand if running create with no arguments" do
      simulate_args "create"
      executing_ahn_command_should_fail_with Adhearsion::CLI::AhnCommand::CommandHandler::UnknownCommand
    end
  end
end
