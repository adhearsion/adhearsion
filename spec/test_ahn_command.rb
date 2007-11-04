require File.dirname(__FILE__) + "/test_helper"
require 'adhearsion/cli'

module AhnCommandSpecHelper
  def simulate_args(*args)
    ARGV.clear
    args.each {|a| ARGV << a }
  end
  
  def capture_stdout(&block)
    old = $stdout
    $stdout = io = StringIO.new
    yield
    $stdout = old
    io.string
  end
end

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

context "The ahn command" do
  
  include AhnCommandSpecHelper
  
  test "USAGE is defined" do
    assert Adhearsion::CLI::AhnCommand.const_defined?('USAGE')
  end
  
  test "arguments to 'create' are executed properly properly" do
    some_path = "/path/somewhere"
    simulate_args "create", some_path
    flexmock(Adhearsion::CLI::AhnCommand::CommandHandler).should_receive(:create).with(some_path, :default)
    Adhearsion::CLI::AhnCommand.execute!
  end
  
  test "arguments to 'start' are executed properly properly" do
    some_path = "/tmp/blargh"
    simulate_args "start", some_path
    flexmock(Adhearsion::CLI::AhnCommand::CommandHandler).should_receive(:start).with(some_path, nil)
    Adhearsion::CLI::AhnCommand.execute!
  end
  
  test "should execute arguments to 'start' for daemonizing properly" do
    somewhere = "/tmp/blarghh"
    simulate_args "start", somewhere, true
    flexmock(Adhearsion::CLI::AhnCommand::CommandHandler).should_receive(:start).with(somewhere, true)
    Adhearsion::CLI::AhnCommand.execute!
  end
  
  test "if not path is provided, running Ahn command blows up" do
    lambda {
      simulate_args "start"
      Adhearsion::CLI::AhnCommand.execute!
    }.should.raise(NoMethodError)
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
    lambda {
      simulate_args "alpha", "beta"
      Adhearsion::CLI::AhnCommand::CommandHandler
      Adhearsion::CLI::AhnCommand.execute!
    }.should.raise(Adhearsion::CLI::AhnCommand::CommandHandler::UnknownCommand)
  end
  
  test "giving a path that doesn't contain a project raises an exception" do
    lambda {
      simulate_args "start", "/asjdfas/sndjfabsdfbqwb/qnjwejqbwh"
      Adhearsion::CLI::AhnCommand.execute!
    }.should.raise(Adhearsion::CLI::AhnCommand::CommandHandler::PathInvalid)
  end
  
  test "giving an unrecognized project name raises an exception" do
    lambda {
      simulate_args "create:a2n8y3gny2", "/tmp/qjweqbwas"
      Adhearsion::CLI::AhnCommand.execute!
    }.should.raise(Adhearsion::CLI::AhnCommand::CommandHandler::UnknownProject)
  end
end

context 'The "ahn create" command' do
  disabled_test ".svn folders should not be copied"
end
