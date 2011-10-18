require 'spec_helper'

describe Adhearsion::Logging do

  before(:each) do
    Adhearsion::Initializer::Logging.start
    Adhearsion::Logging.silence!
  end

  it 'should be added to any Object' do
    Foo.should respond_to(:logger)
  end

  it 'should be added to any Object instance' do
    Foo.new.should respond_to(:logger)
  end

  it "should log to the Object logger when given arguments" do
    message = "o hai. ur home erly."
    foo = Foo.new
    flexmock(::Logging.logger[Foo]).should_receive(:info).once.with(message)
    foo.logger.info message
  end

  it "should log to the Object logger when given arguments (II)" do
    message = "o hai. ur home erly."
    bar = Foo::Bar.new
    flexmock(::Logging.logger[Foo::Bar]).should_receive(:info).once.with(message)
    bar.logger.info message
  end

  it 'should create a new logger when given method_missing' do
    FooBar = Class.new Foo
    ::Logging::Repository.instance[FooBar].should be_nil
    FooBar.logger.info "o hai. ur home erly."
    ::Logging::Repository.instance[FooBar].should_not be_nil
  end

end

# Essential for running the tests
describe 'Logger level changing' do

  before(:each) do
    Adhearsion::Initializer::Logging.start
  end

  after :each do
    Adhearsion::Logging.logging_level = :info
  end

  after :all do
    Adhearsion::Logging.logging_level = :fatal # Silence them again
  end

  it 'changing the logging level should affect all loggers' do
    loggers = [Foo.logger, Foo::Bar.logger]
    loggers.map(&:level).should_not == [::Logging::LEVELS["debug"]] * 2
    loggers.map(&:level).should == [::Logging::LEVELS["info"]] * 2
    Adhearsion::Logging.logging_level = :warn
    loggers.map(&:level).should == [::Logging::LEVELS["warn"]] * 2
  end

  it 'changing the logging level, using level=, should affect all loggers' do
    loggers = [Foo.logger, Foo::Bar.logger]
    loggers.map(&:level).should_not == [::Logging::LEVELS["debug"]] * 2
    loggers.map(&:level).should == [::Logging::LEVELS["info"]] * 2
    Adhearsion::Logging.level = :warn
    loggers.map(&:level).should == [::Logging::LEVELS["warn"]] * 2
  end

  it 'should change all the Logger instance level' do
    Foo.logger.level.should be Adhearsion::Logging::INFO
    Adhearsion::Logging.logging_level = :fatal
    Foo.logger.level.should be Adhearsion::Logging::FATAL
  end

  it 'a new logger should have the :root logging level' do
    Foo.logger.level.should be Adhearsion::Logging::INFO
    Adhearsion::Logging.logging_level = :fatal
    Foo::Bar.logger.level.should be Adhearsion::Logging::FATAL
  end

  it '#silence!() should change the level to be FATAL' do
    Adhearsion::Logging.silence!
    Adhearsion::Logging.logging_level.should be(Adhearsion::Logging::FATAL)
  end

  it '#unsilence!() should change the level to be INFO' do
    Adhearsion::Logging.unsilence!
    Adhearsion::Logging.logging_level.should be(Adhearsion::Logging::INFO)
  end

end
