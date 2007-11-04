require File.dirname(__FILE__) + '/../../test_helper'

describe 'PBX' do
  %w"iax_peers sip_peers".each do |property|
    test "should expose a #{property}() property"
  end
  test "should return an Array of Peer objects"
end
