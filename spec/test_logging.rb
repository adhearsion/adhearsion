require 'test_helper'
require 'stringio'

module LoggingSpecHelper
  def mock_logger
    returning flexmock("logger") do |obj|
      Adhearsion::Logging::SEVERITIES.each do |meth|
        obj.should_receive meth
      end
    end
  end
  def capturer() @output = StringIO.new end
end

module StandardLoggerBehavior
  def test_standard_logger_behavior
    Adhearsion::Logging::SEVERITIES.each do |meth|
      @logger.should.respond_to(meth)
      #@logger.method(meth).arity.should eql(1)
    end
  end
end

describe "Adhearsion::Logging" do
  
  include LoggingSpecHelper
  include InitializerStubs
  
  # Unregister the default logger for each test (or allow it to be specified)
  clear = lambda { Adhearsion::Logging.remove_logger :all }
  before :all, &clear
  after :each, &clear
  
  test "should allow the removal of the default logger after initialization" do
    assert Adhearsion::Logging.registered_loggers.empty?
    with_new_initializer_with_no_path_changing_behavior    
    assert_equal 1, Adhearsion::Logging.registered_loggers.size
    Adhearsion::Logging.remove_logger :default
    assert Adhearsion::Logging.registered_loggers.empty?
  end
  
  test "should properly register a logger" do
    b4 = Adhearsion::Logging.registered_loggers.size
    logger = Adhearsion::Logging.register_logger Adhearsion::Logging::StandardLogger.new
    Adhearsion::Logging.registered_loggers.size.should.equal(b4 + 1)
  end
  
  test "should log properly to a specified IO object." do
    io = StringIO.new
    Adhearsion::Logging.remove_logger :all
    Adhearsion::Logging.register_logger Adhearsion::Logging::StandardLogger.new(io)
    
    Adhearsion::Logging::SEVERITIES.each_with_index do |sev, i|
      s = rand(10_000_000).to_s
      Adhearsion::Logging::log! s, i + 1, sev
    end
  end
  
  test "should support setting the severity to a symbol or an number" do
    Adhearsion::Logging.severity = 4
    Adhearsion::Logging.severity.should.eql(:fatal)
    
    Adhearsion::Logging.severity = :error
    Adhearsion::Logging.severity.should.eql(:error)
  end
  
  test "should include the Adhearsion::Logging::LoggingMethods module into the main namespace"
  test "should log properly to a separate IO object for errors if necessary"
  test "should not log priorities lower than the current severity"
  test "should log properly to many IO objects"
  test "should log times when desired"
  
  test "should remove all loggers properly" do
    Adhearsion::Logging.register_logger mock_logger
    assert(Adhearsion::Logging.registered_loggers.size >= 1)
    Adhearsion::Logging.remove_logger :all
    assert(Adhearsion::Logging.registered_loggers.empty?)
  end
  
  test "should have the most severe priorities with the highest numbers"
  
  test "should properly remove an arbitrary logger" do
    imposter = mock_logger
    before = Adhearsion::Logging.registered_loggers.size
    Adhearsion::Logging.register_logger imposter
    Adhearsion::Logging.remove_logger imposter
    assert_equal before, Adhearsion::Logging.registered_loggers.size
  end
  
  test "should close any registered loggers when shutting down" do
    one_io, two_io = StringIO.new, StringIO.new
    one = Adhearsion::Logging::StandardLogger.new one_io
    two = Adhearsion::Logging::StandardLogger.new two_io
    flexmock(one).should_receive :close
    flexmock(two).should_receive :close
    Adhearsion::Logging.register_logger one
    Adhearsion::Logging.register_logger two
    Adhearsion::Hooks::TearDown.trigger_hooks
  end
end

describe "Adhearsion::Logging::StandardLogger" do
  include LoggingSpecHelper
  include StandardLoggerBehavior
  
  before:all do
    @logger = Adhearsion::Logging::StandardLogger.new capturer
  end
end

##################################################################
# Older code:
# test "should not log anything when silenced" do
#   Adhearsion::Logging.silence!
#   Adhearsion::Logging.should be_silenced
#   # also call silenced?
# end
# test "should log something when silenced and unsilenced" do
# end