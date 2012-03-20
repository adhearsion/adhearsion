# encoding: utf-8

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
          subject[0].name.should be == 'calls from fred'
          subject[0].guards.should be == [{:from => 'fred'}]
          subject[0].target.should be == FooBarController

          subject[1].name.should be == 'calls from paul'
          subject[1].guards.should be == [{:from => 'paul'}]
          subject[1].target.should be_a Proc

          subject[2].name.should be == 'catchall'
          subject[2].guards.should be == []
          subject[2].target.should be_a Proc
        end
      end

      describe "matching a call" do
        let(:router) do
          Router.new do
            route 'calls from fred', FooBarController, :from => 'fred'
            route 'calls from fred2', :from => 'fred' do
              :car
            end
            route 'calls from paul', :from => 'paul' do
              :bar
            end
            route 'catchall' do
              :foo
            end
          end
        end

        subject { router.match call }

        context 'with a call from fred' do
          let(:call) { flexmock 'Adhearsion::Call', :from => 'fred' }
          its(:name) { should be == 'calls from fred' }
        end

        context 'with a call from paul' do
          let(:call) { flexmock 'Adhearsion::Call', :from => 'paul' }
          its(:name) { should be == 'calls from paul' }
        end

        context 'with a call from frank' do
          let(:call) { flexmock 'Adhearsion::Call', :from => 'frank' }
          its(:name) { should be == 'catchall' }
        end
      end

      describe "handling a call" do
        subject do
          Router.new do
            route 'catchall', FooBarController
          end
        end

        let(:call) { flexmock 'Adhearsion::Call', :id => 'abc123' }
        let(:route) { subject.routes.first }

        it "should return the route's dispatcher" do
          subject.handle(call).should be route.dispatcher
        end
      end
    end
  end
end
