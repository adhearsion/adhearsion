require File.dirname(__FILE__) + "/test_helper"

context 'The ahn_log command' do
  
  test 'should add the ahn_log method to the global namespace' do
    ahn_log.should.be Adhearsion::Logging::DefaultAdhearsionLogger
  end
  
  test "should log to the standard Adhearsion logger when given arguments" do
    message = "o hai. ur home erly."
    flexmock(Log4r::Logger['ahn']).should_receive(:info).once.with(message)
    ahn_log message
  end
  
  test 'should create a new logger when given method_missing' do
    ahn_log.micromenus 'danger will robinson!'  
    Log4r::Logger['micromenus'].should.not.be nil
  end
  
  test 'should define a singleton method on itself of any name found by method_missing' do
    ahn_log.agi "SOMETHING IMPORTANT HAPPENED"
    Adhearsion::Logging::AdhearsionLogger.instance_methods.should.include 'agi'
  end
  
  test "dynamically generated loggers should support logging with blocks" do
    # I had to comment out this test because Flexmock makes it impossible to#
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
  
  test 'new loggers created by method_missing() should be instances of AdhearsionLogger' do
    ahn_log.qwerty.should.be.kind_of Adhearsion::Logging::AdhearsionLogger
  end
  
end

# Essential for running the tests
context 'Logger level changing' do
  
  after :each do
    Adhearsion::Logging.logging_level = :info
  end
  
  after :all do
    Adhearsion::Logging.logging_level = :fatal # Silence them again
  end
  
  test 'changing the logging level should affect all loggers' do
    loggers = [ahn_log.one, ahn_log.two, ahn_log.three]
    loggers.map(&:level).should.not == [Log4r::WARN] * 3
    Adhearsion::Logging.logging_level = :warn
    loggers.map(&:level).should == [Log4r::WARN] * 3
  end
  
  test 'a new logger should have the global Adhearsion logging level' do
    ahn_log.foo.level.should.equal Log4r::INFO
    Adhearsion::Logging.logging_level = :fatal
    ahn_log.brand_new.level.should.equal Log4r::FATAL
  end
  
  test '#silence!() should change the level to be FATAL' do
    flexmock(Adhearsion::Logging::DefaultAdhearsionLogger).should_receive(:level=).once.with(Log4r::FATAL)
    Adhearsion::Logging.silence!
  end
  
  test '#unsilence!() should change the level to be INFO' do
    flexmock(Adhearsion::Logging::DefaultAdhearsionLogger).should_receive(:level=).once.with(Log4r::INFO)
    Adhearsion::Logging.unsilence!
  end
  
end