require File.dirname(__FILE__) + "/test_helper"

context "Invoking an interface method via DRb" do

  include DRbTestHelper

  test "should raise an exception if the method is not found" do
    the_following_code do
      new_drb_rpc_object.this_method_doesnt_exist
    end.should.raise NoMethodError
  end

  before(:all) { require 'drb' }

  before :each do
    @component_manager = Adhearsion::Components::ComponentManager.new("/path/doesnt/matter")
    @door = DRb.start_service "druby://127.0.0.1:9050", new_drb_rpc_object
  end

  after :each do
    DRb.stop_service
  end

  test "should return normal Ruby data structures properly over DRb" do
    add_rpc_methods <<-RUBY
      def bar
        [3,2,1]
      end
    RUBY
    client = DRbObject.new nil, DRb.uri
    client.bar.should.equal [3, 2, 1]
  end

  test "should raise an exception for a non-existent interface" do
    client = DRbObject.new nil, DRb.uri
    the_following_code do
      client.interface.bad_interface.should.equal [3, 2, 1]
    end.should.raise NoMethodError
  end

  test "should raise an exception for a non-existent method" do
    client = DRbObject.new nil, DRb.uri
    the_following_code do
      client.interface.interface.foobar.equal [3, 2, 1]
    end.should.raise NoMethodError
  end

  after do
    DRb.stop_service
  end
end


BEGIN {
  module DRbTestHelper

    def new_drb_rpc_object
      Object.new.tap do |obj|
        @component_manager.extend_object_with(obj, :rpc)
      end
    end

    def add_rpc_methods(code)
      @component_manager.load_code "methods_for(:rpc) do; #{code}; end"
    end

  end
}