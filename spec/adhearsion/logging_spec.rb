# encoding: utf-8

require 'spec_helper'

describe Adhearsion::Logging do

  before :all do
    ::Logging.shutdown
    ::Logging.reset
    Adhearsion::Logging.init
  end

  before do
    Adhearsion::Logging.start
    Adhearsion::Logging.silence!
  end

  after :all do
    Adhearsion::Logging.silence!
  end

  it 'should be added to any Object' do
    Foo.should respond_to(:logger)
  end

  it 'should be added to any Object instance' do
    Foo.new.should respond_to :logger
  end

  it 'should create the predefined set of log levels' do
    ::Logging::LEVELS.keys.should be == Adhearsion::Logging::LOG_LEVELS.map(&:downcase)
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

    it "initializes properly a Logging object" do
    ::Logging.logger.root.appenders.length.should eql(1)
    ::Logging.logger.root.appenders.select{|a| a.is_a?(::Logging::Appenders::Stdout)}.length.should eql(1)
  end

  it "initializes properly a Logging object with appenders as parameter" do
    Adhearsion::Logging.start([::Logging.appenders.stdout, ::Logging.appenders.file('example.log')])
    ::Logging.logger.root.appenders.length.should eql(2)
    ::Logging.logger.root.appenders.select{|a| a.is_a?(::Logging::Appenders::Stdout)}.length.should eql(1)
    ::Logging.logger.root.appenders.select{|a| a.is_a?(::Logging::Appenders::File)}.length.should eql(1)
  end

  it "initializes properly a Logging object with appenders and log level as parameter" do
    Adhearsion::Logging.start([::Logging.appenders.stdout, ::Logging.appenders.file('example.log')], :debug)
    ::Logging.logger.root.appenders.length.should eql(2)
    ::Logging.logger.root.appenders.select{|a| a.is_a?(::Logging::Appenders::Stdout)}.length.should eql(1)
    ::Logging.logger.root.appenders.select{|a| a.is_a?(::Logging::Appenders::File)}.length.should eql(1)
    ::Logging.logger.root.level.should eql(::Logging::LEVELS["debug"])
  end

  it "should create only a Logging object per Class (reuse per all the instances)" do
    _logger = Foo.new.logger
    10.times do
      Foo.new.logger.object_id.should eql(_logger.object_id)
    end
  end

  it "should reuse a Logging instance in all Class instances but not with child instances" do
    _foo_logger = Foo.new.logger
    _bar_logger = Foo::Bar.new.logger
    _foo_logger.object_id.should_not eql(_bar_logger)
  end

  it 'should reopen logfiles' do
    flexmock(::Logging).should_receive(:reopen).once
    Adhearsion::Logging.reopen_logs
  end

  it 'should toggle between :trace and the configured log level' do
    orig_level = Adhearsion.config.platform.logging['level']
    Adhearsion.config.platform.logging['level'] = :warn
    Adhearsion::Logging.level = :warn
    Adhearsion::Logging.toggle_trace!
    Adhearsion::Logging.level.should be == 0
    Adhearsion::Logging.toggle_trace!
    Adhearsion::Logging.level.should be == 3
    Adhearsion.config.platform.logging['level'] = orig_level
  end

  describe 'level changing' do

    before  { Adhearsion::Logging.unsilence! }
    after   { Adhearsion::Logging.unsilence! }

    it 'changing the logging level should affect all loggers' do
      loggers = [::Foo.logger, ::Foo::Bar.logger]
      loggers.map(&:level).should_not be == [Adhearsion::Logging::DEBUG] * 2
      loggers.map(&:level).should be == [Adhearsion::Logging::INFO] * 2
      Adhearsion::Logging.logging_level = :warn
      loggers.map(&:level).should be == [Adhearsion::Logging::WARN] * 2
    end

    it 'changing the logging level, using level=, should affect all loggers' do
      loggers = [Foo.logger, ::Foo::Bar.logger]
      loggers.map(&:level).should_not be == [::Logging::LEVELS["debug"]] * 2
      loggers.map(&:level).should be == [::Logging::LEVELS["info"]] * 2
      Adhearsion::Logging.level = :warn
      loggers.map(&:level).should be == [::Logging::LEVELS["warn"]] * 2
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

    it '#silence! should change the level to be FATAL' do
      Adhearsion::Logging.silence!
      Adhearsion::Logging.logging_level.should be(Adhearsion::Logging::FATAL)
    end

    it '#unsilence! should change the level to be INFO' do
      Adhearsion::Logging.unsilence!
      Adhearsion::Logging.logging_level.should be(Adhearsion::Logging::INFO)
    end

  end
end
