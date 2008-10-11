require File.join(File.dirname(__FILE__), "spec_helper")
Dir[File.join(File.dirname(__FILE__), "test_*")].each do |file|
  require file
end