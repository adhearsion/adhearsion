require File.join(File.dirname(__FILE__), "ami_helper")
Dir[File.join(File.dirname(__FILE__), "test_*")].each do |file|
  require file
end