require 'spec_helper'

describe Adhearsion::Initializer::Logging do

  before(:each) do
    Adhearsion::Initializer::Logging.start
	end

	after(:each) do
	  Adhearsion::Logging.reset
  end

  after(:all) do
    Adhearsion::Initializer::Logging.start
    Adhearsion::Logging.silence!
  end

  it "initializes properly a Logging object" do
    ::Logging.logger.root.appenders.length.should eql(1)
    ::Logging.logger.root.appenders.select{|a| a.is_a?(::Logging::Appenders::Stdout)}.length.should eql(1)
  end

  it 'should created the predefined set of log levels' do
    ::Logging::LEVELS.length.should eql(Adhearsion::Logging::LOG_LEVELS.length)
  end

  it "initializes properly a Logging object with appenders as parameter" do
    Adhearsion::Initializer::Logging.start([::Logging.appenders.stdout, ::Logging.appenders.file('example.log')])
    ::Logging.logger.root.appenders.length.should eql(2)
    ::Logging.logger.root.appenders.select{|a| a.is_a?(::Logging::Appenders::Stdout)}.length.should eql(1)
    ::Logging.logger.root.appenders.select{|a| a.is_a?(::Logging::Appenders::File)}.length.should eql(1)
  end

  it "initializes properly a Logging object with appenders and log level as parameter" do
    Adhearsion::Initializer::Logging.start([::Logging.appenders.stdout, ::Logging.appenders.file('example.log')], :debug)
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

end
