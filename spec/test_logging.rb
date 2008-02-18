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
  
  test 'new loggers created by method_missing() should be instances of AdhearsionLogger' do
    ahn_log.qwerty.should.be.kind_of Adhearsion::Logging::AdhearsionLogger
  end
  
end

# Essential for running the tests
context 'Logger silencing' do
  
  test '#silence!() should change the level to be FATAL' do
    flexmock(Adhearsion::Logging::DefaultAdhearsionLogger).should_receive(:level=).once.with(Log4r::FATAL)
    Adhearsion::Logging.silence!
  end
  
  test '#unsilence!() should change the level to be INFO' do
    flexmock(Adhearsion::Logging::DefaultAdhearsionLogger).should_receive(:level=).once.with(Log4r::INFO)
    Adhearsion::Logging.unsilence!
  end
  
end