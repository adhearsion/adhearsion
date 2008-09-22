require File.dirname(__FILE__) + "/../test_helper"

context "Files from config" do
  
  test "the old way of doing paths should not still be around" do
    should.not.respond_to(:all_helpers)
    should.not.respond_to(:helper_path)
  end
  
  test "should work when only one filename is present" do
    mock_ahnrc_with "paths:\n    helpers: foobar.rb"
    AHN_CONFIG.files_from_setting("paths", "init").should eql(%w[foobar.rb])
  end
  
  test "should work when an Array of filenames is present" do
    fail
  end
  
  test "should work when one glob filename is present" do
    fail
  end
  
  test "should work when an Array of filenames are present" do
    fail
  end
  
end

BEGIN {
  module PathsTestHelper
    def mock_ahnrc_with(raw_yaml)
      raise NotImplementedError
    end
  end
}