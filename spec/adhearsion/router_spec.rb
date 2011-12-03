require 'spec_helper'

module Adhearsion
  describe Router do
    describe 'a new router' do
      subject { Router.new {} }

      it "should make the router available to the block" do
        foo = nil
        Router.new do
          foo = self
        end
        foo.should be_a Router
      end

      it "should allow defining routes in the block" do
        router = Router.new do
          route
          route
        end

        router.routes.should have(2).routes
        router.routes.each do |route|
          route.should be_a Router::Route
        end
      end
    end
  end
end
