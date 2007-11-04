require File.dirname(__FILE__) + "/../test_helper"
require 'adhearsion/helper_support/helper_loader'

include Adhearsion::HelperSupport
describe" HelperLoader" do
  test "should execute the before- and after-helpers-load hooks"
  test "should load other HelperLoader modules in Adhearsion::HelperSupport::HelperLoader"
end

describe "HelperLoader::RubyHelperLoader" do
  test "should report a helper's exception as from the helper's filename"
  test "should evaluate the helper inside Adhearsion::Helpers" do
    file = "kewlz0rz.rb"
    flexmock(HelperLoader::RubyHelperLoader).should_receive(:my_helpers).once.
      and_return([file])
    flexmock(File).should_receive(:read).once.and_return <<-HELPER
      def kewlz0rz_method
        puts "What hath God wrought?!"
      end
    HELPER
    HelperLoader::RubyHelperLoader.load!
    
    dummy = Object.new.extend Adhearsion::Helpers
    dummy.instance_eval { should.respond_to(:kewlz0rz_method) }
    self.should.not.respond_to(:kewlz0rz_method)
  end
  
end

