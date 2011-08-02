require 'spec_helper'

describe 'The ahn_log command' do

  it 'should add the ahn_log method to the global namespace' do
    ahn_log.should be Adhearsion::Logging::DefaultAdhearsionLogger
  end

  it "should log to the standard Adhearsion logger when given arguments" do
    message = "o hai. ur home erly."
    flexmock(Log4r::Logger['ahn']).should_receive(:info).once.with(message)
    ahn_log message
  end

  it 'should create a new logger when given method_missing' do
    ahn_log.micromenus 'danger will robinson!'
    Log4r::Logger['micromenus'].should_not be nil
  end

  it 'should define a singleton method on itself of any name found by method_missing' do
    ahn_log.agi "SOMETHING IMPORTANT HAPPENED"
    Adhearsion::Logging::AdhearsionLogger.instance_methods.map{|m| m.to_sym}.should include :agi
  end

  it "dynamically generated loggers should support logging with blocks" do
    # I had to comment out this it because Flexmock makes it impossible to#
    # set up an expectation for receiving blocks.

    # proc_to_log = lambda { [1,2,3].reverse.join }
    #
    # info_catcher = flexmock "A logger that responds to info()"
    # info_catcher.should_receive(:info).once.with(&proc_to_log)
    #
    # flexmock(Log4r::Logger).should_receive(:[]).with('log4r')
    # flexmock(Log4r::Logger).should_receive(:[]).once.with('ami').and_return info_catcher
    #
    # ahn_log.ami(&proc_to_log)
  end

  it 'new loggers created by method_missing() should be instances of AdhearsionLogger' do
    ahn_log.qwerty.should be_a_kind_of Adhearsion::Logging::AdhearsionLogger
  end

  it "handles crazy logger names" do
    ahn_log.send :'locals@DEMO_ca.ll&', "hey"
    Log4r::Logger['locals@DEMO_ca.ll&'].should_not be nil
    ahn_log.send(:'localsdemo_call').should == Log4r::Logger['locals@DEMO_ca.ll&']
  end

end

# Essential for running the tests
describe 'Logger level changing' do

  after :each do
    Adhearsion::Logging.logging_level = :info
  end

  after :all do
    Adhearsion::Logging.logging_level = :fatal # Silence them again
  end

  it 'changing the logging level should affect all loggers' do
    loggers = [ahn_log.one, ahn_log.two, ahn_log.three]
    loggers.map(&:level).should_not == [Log4r::WARN] * 3
    Adhearsion::Logging.logging_level = :warn
    loggers.map(&:level).should == [Log4r::WARN] * 3
  end

  it 'a new logger should have the global Adhearsion logging level' do
    ahn_log.foo.level.should be Log4r::INFO
    Adhearsion::Logging.logging_level = :fatal
    ahn_log.brand_new.level.should be Log4r::FATAL
  end

  it '#silence!() should change the level to be FATAL' do
    flexmock(Adhearsion::Logging::DefaultAdhearsionLogger).should_receive(:level=).once.with(Log4r::FATAL)
    Adhearsion::Logging.silence!
    # Verify and close manually here because the after-test hook breaks the expectation
    flexmock_verify
    flexmock_close
  end

  it '#unsilence!() should change the level to be INFO' do
    flexmock(Adhearsion::Logging::DefaultAdhearsionLogger).should_receive(:level=).once.with(Log4r::INFO)
    Adhearsion::Logging.unsilence!
    # Verify and close manually here because the after-test hook breaks the expectation
    flexmock_verify
    flexmock_close
  end

end
