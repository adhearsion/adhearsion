require File.dirname(__FILE__) + "/../../test_helper"

describe "The Agent class" do
  test "should allow the agent to be unobtrusively logged out with logout()"
  test "should allow a forced logout!()"
  
  %w(name logged_in? wrapup_time agent_id status).each do |property|
    test "should expose a #{property}() property"
  end
  %(channel current_caller).each do |property|
    test "should return a Channel object for #{property}() if logged_in? is true"    
  end
  %w(channel current_caller).each do |property|
    test "should return nil for #{property}() when logged_in? is false"
  end
  
  test "should update the PBX when a new Agent is instantiated"
end
