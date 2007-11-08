require File.dirname(__FILE__) + "/test_helper"
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
  
  def new_tmp_dir(filename=String.random)
    File.join Dir.tmpdir, filename
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

context "A simulated use of the 'ahn' command" do
  
  include AhnCommandSpecHelper
  
  test "USAGE is defined" do
    assert Adhearsion::CLI::AhnCommand.const_defined?('USAGE')
  end
  
  test "arguments to 'create' are executed properly properly" do
    some_path = "/path/somewhere"
    simulate_args "create", some_path
    flexmock(Adhearsion::CLI::AhnCommand::CommandHandler).should_receive(:create).once.with(some_path, :default)
    capture_stdout { Adhearsion::CLI::AhnCommand.execute! }
  end
  
  test "arguments to 'start' are executed properly properly" do
    some_path = "/tmp/blargh"
    simulate_args "start", some_path
    flexmock(Adhearsion::CLI::AhnCommand::CommandHandler).should_receive(:start).once.with(some_path, nil)
    Adhearsion::CLI::AhnCommand.execute!
  end
  
  test "should execute arguments to 'start' for daemonizing properly" do
    somewhere = "/tmp/blarghh"
    simulate_args "start", somewhere, true
    flexmock(Adhearsion::CLI::AhnCommand::CommandHandler).should_receive(:start).once.with(somewhere, true)
    Adhearsion::CLI::AhnCommand.execute!
  end
  
  test "if not path is provided, running Ahn command blows up" do
    the_following_code {
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
  
  test "giving an unrecognized project name raises an exception" do
    the_following_code {
      nonexistent_app_name, nonexistent_path = "a2n8y3gny2", "/tmp/qjweqbwas"
      simulate_args "create:#{nonexistent_app_name}", nonexistent_path
      capture_stdout { Adhearsion::CLI::AhnCommand.execute! }
    }.should.raise Adhearsion::CLI::AhnCommand::CommandHandler::UnknownProject
  end
end

context 'A real use of the "ahn" command' do
  
  include AhnCommandSpecHelper
  
  test "the 'create' command" do
    the_following_code {
      tmp_path = new_tmp_dir
      simulate_args "create", tmp_path
      capture_stdout { Adhearsion::CLI::AhnCommand.execute! }
      File.exists?(File.join(tmp_path, ".ahnrc")).should.be true
    }.should.not.raise
  end
  
end