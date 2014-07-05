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
    expect(Foo).to respond_to(:logger)
  end

  it 'should be added to any Object instance' do
    expect(Foo.new).to respond_to :logger
  end

  it 'should create the predefined set of log levels' do
    expect(::Logging::LEVELS.keys).to eq(Adhearsion::Logging::LOG_LEVELS.map(&:downcase))
  end

  it "should log to the Object logger when given arguments" do
    message = "o hai. ur home erly."
    foo = Foo.new
    expect(::Logging.logger[Foo]).to receive(:info).once.with(message)
    foo.logger.info message
  end

  it "should log to the Object logger when given arguments (II)" do
    message = "o hai. ur home erly."
    bar = Foo::Bar.new
    expect(::Logging.logger[Foo::Bar]).to receive(:info).once.with(message)
    bar.logger.info message
  end

  it 'should create a new logger when given method_missing' do
    FooBar = Class.new Foo
    expect(::Logging::Repository.instance[FooBar]).to be_nil
    FooBar.logger.info "o hai. ur home erly."
    expect(::Logging::Repository.instance[FooBar]).not_to be_nil
  end

    it "initializes properly a Logging object" do
    expect(::Logging.logger.root.appenders.length).to eql(1)
    expect(::Logging.logger.root.appenders.select{|a| a.is_a?(::Logging::Appenders::Stdout)}.length).to eql(1)
  end

  it "initializes properly a Logging object with appenders as parameter" do
    Adhearsion::Logging.start([::Logging.appenders.stdout, ::Logging.appenders.file('example.log')])
    expect(::Logging.logger.root.appenders.length).to eql(2)
    expect(::Logging.logger.root.appenders.select{|a| a.is_a?(::Logging::Appenders::Stdout)}.length).to eql(1)
    expect(::Logging.logger.root.appenders.select{|a| a.is_a?(::Logging::Appenders::File)}.length).to eql(1)
  end

  it "initializes properly a Logging object with appenders and log level as parameter" do
    Adhearsion::Logging.start([::Logging.appenders.stdout, ::Logging.appenders.file('example.log')], :debug)
    expect(::Logging.logger.root.appenders.length).to eql(2)
    expect(::Logging.logger.root.appenders.select{|a| a.is_a?(::Logging::Appenders::Stdout)}.length).to eql(1)
    expect(::Logging.logger.root.appenders.select{|a| a.is_a?(::Logging::Appenders::File)}.length).to eql(1)
    expect(::Logging.logger.root.level).to eql(::Logging::LEVELS["debug"])
  end

  it "should create only a Logging object per Class (reuse per all the instances)" do
    _logger = Foo.new.logger
    10.times do
      expect(Foo.new.logger.object_id).to eql(_logger.object_id)
    end
  end

  it "should reuse a Logging instance in all Class instances but not with child instances" do
    _foo_logger = Foo.new.logger
    _bar_logger = Foo::Bar.new.logger
    expect(_foo_logger.object_id).not_to eql(_bar_logger)
  end

  it 'should reopen logfiles' do
    expect(::Logging).to receive(:reopen).once
    Adhearsion::Logging.reopen_logs
  end

  it 'should toggle between :trace and the configured log level' do
    orig_level = Adhearsion.config.platform.logging['level']
    Adhearsion.config.platform.logging['level'] = :warn
    Adhearsion::Logging.level = :warn
    Adhearsion::Logging.toggle_trace!
    expect(Adhearsion::Logging.level).to eq(0)
    Adhearsion::Logging.toggle_trace!
    expect(Adhearsion::Logging.level).to eq(3)
    Adhearsion.config.platform.logging['level'] = orig_level
  end

  describe 'level changing' do

    before  { Adhearsion::Logging.unsilence! }
    after   { Adhearsion::Logging.unsilence! }

    it 'changing the logging level should affect all loggers' do
      loggers = [::Foo.logger, ::Foo::Bar.logger]
      expect(loggers.map(&:level)).not_to eq([Adhearsion::Logging::DEBUG] * 2)
      expect(loggers.map(&:level)).to eq([Adhearsion::Logging::INFO] * 2)
      Adhearsion::Logging.logging_level = :warn
      expect(loggers.map(&:level)).to eq([Adhearsion::Logging::WARN] * 2)
    end

    it 'changing the logging level, using level=, should affect all loggers' do
      loggers = [Foo.logger, ::Foo::Bar.logger]
      expect(loggers.map(&:level)).not_to eq([::Logging::LEVELS["debug"]] * 2)
      expect(loggers.map(&:level)).to eq([::Logging::LEVELS["info"]] * 2)
      Adhearsion::Logging.level = :warn
      expect(loggers.map(&:level)).to eq([::Logging::LEVELS["warn"]] * 2)
    end

    it 'should change all the Logger instance level' do
      expect(Foo.logger.level).to be Adhearsion::Logging::INFO
      Adhearsion::Logging.logging_level = :fatal
      expect(Foo.logger.level).to be Adhearsion::Logging::FATAL
    end

    it 'a new logger should have the :root logging level' do
      expect(Foo.logger.level).to be Adhearsion::Logging::INFO
      Adhearsion::Logging.logging_level = :fatal
      expect(Foo::Bar.logger.level).to be Adhearsion::Logging::FATAL
    end

    it '#silence! should change the level to be FATAL' do
      Adhearsion::Logging.silence!
      expect(Adhearsion::Logging.logging_level).to be(Adhearsion::Logging::FATAL)
    end

    it '#unsilence! should change the level to be INFO' do
      Adhearsion::Logging.unsilence!
      expect(Adhearsion::Logging.logging_level).to be(Adhearsion::Logging::INFO)
    end

  end
end
