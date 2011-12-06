require 'spec_helper'

FooBarController = Class.new

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

      describe "defining routes in the block" do
        let(:router) do
          Router.new do
            route 'calls from fred', FooBarController, :from => 'fred'
            route 'calls from paul', :from => 'paul' do
              :bar
            end
            route 'catchall' do
              :foo
            end
          end
        end

        subject { router.routes }

        it { should have(3).elements }

        it "should contain Routes" do
          subject.each do |route|
            route.should be_a Router::Route
          end
        end

        it "should build up the routes with the correct data" do
          subject[0].name.should == 'calls from fred'
          subject[0].guards.should == {:from => 'fred'}
          subject[0].target.should == FooBarController

          subject[1].name.should == 'calls from paul'
          subject[1].guards.should == {:from => 'paul'}
          subject[1].target.should be_a Proc

          subject[2].name.should == 'catchall'
          subject[2].guards.should == nil
          subject[2].target.should be_a Proc
        end
      end
    end
  end
end
