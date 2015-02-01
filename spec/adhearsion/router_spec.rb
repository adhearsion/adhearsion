# encoding: utf-8

require 'spec_helper'

FooBarController = Class.new

module Adhearsion
  describe Router do
    describe 'a new router' do
      subject { Router.new {} }

      let(:call) { double 'Adhearsion::Call' }
      before { allow(call).to receive_messages id: 'abc123' }

      it "should make the router available to the block" do
        foo = nil
        Router.new do
          foo = self
        end
        expect(foo).to be_a Router
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

        it 'has 3 elements' do
          expect(subject.size).to eq(3)
        end

        it "should contain Routes" do
          subject.each do |route|
            expect(route).to be_a Router::Route
          end
        end

        it "should build up the routes with the correct data" do
          expect(subject[0].name).to eq('calls from fred')
          expect(subject[0].guards).to eq([{:from => 'fred'}])
          expect(subject[0].target).to eq(FooBarController)

          expect(subject[1].name).to eq('calls from paul')
          expect(subject[1].guards).to eq([{:from => 'paul'}])
          expect(subject[1].target).to be_a Proc

          expect(subject[2].name).to eq('catchall')
          expect(subject[2].guards).to eq([])
          expect(subject[2].target).to be_a Proc
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
            expect(subject[0]).not_to be_evented
            expect(subject[1]).to be_evented
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
            expect(subject[0]).to be_accepting
            expect(subject[1]).not_to be_accepting
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
            expect(subject[0]).not_to be_openended
            expect(subject[1]).to be_openended
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
            expect(subject[0]).to be_accepting
            expect(subject[0]).not_to be_evented
            expect(subject[1]).to be_evented
            expect(subject[1]).not_to be_accepting
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
          before { allow(call).to receive_messages :from => 'fred' }

          describe '#name' do
            subject { super().name }
            it { is_expected.to eq('calls from fred') }
          end
        end

        context 'with a call from paul' do
          before { allow(call).to receive_messages :from => 'paul' }

          describe '#name' do
            subject { super().name }
            it { is_expected.to eq('calls from paul') }
          end
        end

        context 'with a call from frank' do
          before { allow(call).to receive_messages :from => 'frank' }

          describe '#name' do
            subject { super().name }
            it { is_expected.to eq('catchall') }
          end
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
          expect(route).to receive(:dispatch).once.with call
          subject.handle call
        end

        context "when there are no routes" do
          subject do
            Router.new {}
          end

          it "should return a dispatcher which rejects the call as an error" do
            expect(call).to receive(:reject).once.with(:error)
            subject.handle call
          end
        end

        context "when no routes match" do
          subject do
            Router.new do
              route 'too-specific', FooBarController, :to => 'foo'
            end
          end

          before { allow(call).to receive_messages to: 'bar' }

          it "should return a dispatcher which rejects the call as an error" do
            expect(call).to receive(:reject).once.with(:error)
            subject.handle call
          end
        end
      end
    end
  end
end
