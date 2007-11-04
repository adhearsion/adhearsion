require File.dirname(__FILE__) + "/../../test_helper"
describe "The Channel class" do
  # HANGUP
  test "should allow forced hangups with hangup!()"
  test "should have a hangup_after() method which takes an amount of time in seconds"
  
  # See the   AMI function
  test "should allow setting the absolute_timeout() in seconds"
  test "should disable the absolute_timeout() when the method receives false"
  test "should allow setting the digit_timeout() in seconds"
  test "should disable the digit_timeout() when the method receives false"
  
  test "should make available a hangup_after() method"
  test "should make available an 'endpoint' and 'uniqueness' property"
  test "should override to_s() to return the String with which it was invoked"
  
  test "should support playing DTMF tones on the channel"
  test "should support breaking up the String it receives into individual DTMF play operations"
end