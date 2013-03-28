# encoding: utf-8

require 'spec_helper'

FooBarController = Class.new

module Adhearsion
  describe Router do
    describe 'a new router' do
      subject { Router.new {} }

      let(:call) { mock 'Adhearsion::Call' }
      before { call.stub id: 'abc123' }

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

        context "as evented" do
          let(:router) do
            Router.new do
              route 'calls from fred', FooBarController, :from => 'fred'
              evented do
                route 'catchall' do |call|
                  :foo
                end
              end
            end
          end

          it "should create a route which is evented" do
            subject[0].should_not be_evented
            subject[1].should be_evented
          end
        end

        context "as unaccepting" do
          let(:router) do
            Router.new do
              route 'calls from fred', FooBarController, :from => 'fred'
              unaccepting do
                route 'catchall' do |call|
                  :foo
                end
              end
            end
          end

          it "should create a route with is unaccepting" do
            subject[0].should be_accepting
            subject[1].should_not be_accepting
          end
        end

        context "as openended" do
          let(:router) do
            Router.new do
              route 'calls from fred', FooBarController, :from => 'fred'
              openended do
                route 'catchall' do |call|
                  :foo
                end
              end
            end
          end

          it "should create a route which is openended" do
            subject[0].should_not be_openended
            subject[1].should be_openended
          end
        end

        context "as combined evented/unaccepting" do
          let(:router) do
            Router.new do
              route 'calls from fred', FooBarController, :from => 'fred'
              unaccepting do
                evented do
                  route 'catchall' do |call|
                    :foo
                  end
                end
              end
            end
          end

          it "should create a route which is evented and unaccepting" do
            subject[0].should be_accepting
            subject[0].should_not be_evented
            subject[1].should be_evented
            subject[1].should_not be_accepting
          end
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
          before { call.stub :from => 'fred' }
          its(:name) { should be == 'calls from fred' }
        end

        context 'with a call from paul' do
          before { call.stub :from => 'paul' }
          its(:name) { should be == 'calls from paul' }
        end

        context 'with a call from frank' do
          before { call.stub :from => 'frank' }
          its(:name) { should be == 'catchall' }
        end
      end

      describe "handling a call" do
        subject do
          Router.new do
            route 'catchall', FooBarController
          end
        end

        let(:route) { subject.routes.first }

        it "should dispatch via the route" do
          route.should_receive(:dispatch).once.with call
          subject.handle call
        end

        context "when there are no routes" do
          subject do
            Router.new {}
          end

          it "should return a dispatcher which rejects the call as an error" do
            call.should_receive(:reject).once.with(:error)
            subject.handle call
          end
        end

        context "when no routes match" do
          subject do
            Router.new do
              route 'too-specific', FooBarController, :to => 'foo'
            end
          end

          before { call.stub to: 'bar' }

          it "should return a dispatcher which rejects the call as an error" do
            call.should_receive(:reject).once.with(:error)
            subject.handle call
          end
        end
      end
    end
  end
end
