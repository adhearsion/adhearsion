def ami(m, &block) context("AMI", "##{m}", &block) end

ami:ping do
  test "should return the number of seconds before a response if reachable"
  test "should raise a PingError if unreachable"
end

ami:agents do
  test "should return an Array of Agent objects"
  test "should convert the logged-in time to a Ruby DateTime"
  test "should convert the logged-in status to a Symbol"
  test "should work with known logged-in statuses"
  test "should convert unrecognized logged-in statuses to :unknown"
end

ami:queues do
  
end

ami:state_of_extension do
  test "should take one argument"
  test "should "
end