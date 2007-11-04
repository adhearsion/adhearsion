require File.dirname(__FILE__) + '/../../test_helper'

describe "The VoicemailInbox class" do
  %w"mailbox_id context all_voicemails new_voicemails old_voicemails".each do |property|
    test "should expose a #{property}() property"
  end
  test "should make the default context 'default'"
  test "should return an array of Voicemail objects when calling voicemails()"
end

describe "The Voicemail class" do
  test "should have a created_on property which returns a DateTime"
  
end