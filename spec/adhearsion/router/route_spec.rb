# encoding: utf-8

require 'spec_helper'

module Adhearsion
  class Router
    describe Route do
      describe 'a new route' do
        let(:name) { 'catchall' }
        let(:guards) do
          [
            {:to => /foobar/},
            [{:from => 'fred'}, {:from => 'paul'}]
          ]
        end

        subject { Route.new name }

        it { should_not be_evented }
        it { should be_accepting }

        describe "with a class target and guards" do
          let(:target) { CallController }

          subject { Route.new name, target, *guards }

          its(:name)    { should be == name }
          its(:target)  { should be == target }
          its(:guards)  { should be == guards }
        end

        describe "with a block target and guards" do
          subject { Route.new(name, *guards) { :foo } }

          its(:name)    { should be == name }
          its(:target)  { should be_a Proc }
          its(:guards)  { should be == guards }
        end
      end

      describe "a guarded route" do
        subject { Route.new 'foobar', CallController, *guards }

        def should_match_the_call
          subject.match?(call).should be true
        end

        def should_not_match_the_call
          subject.match?(call).should be false
        end

        describe "matching calls from fred to paul" do
          let :guards do
            [
              {:from => 'fred', :to => 'paul'}
            ]
          end

          let :offer do
            Punchblock::Event::Offer.new :to => to, :from => from
          end

          let(:call) { Adhearsion::Call.new offer }

          context "with a call from fred to paul" do
            let(:from)  { 'fred' }
            let(:to)    { 'paul' }
            it { should_match_the_call }
          end

          context "with a call from fred to frank" do
            let(:from)  { 'fred' }
            let(:to)    { 'frank' }
            it { should_not_match_the_call }
          end

          context "with a call from frank to paul" do
            let(:from)  { 'frank' }
            let(:to)    { 'paul' }
            it { should_not_match_the_call }
          end
        end

        describe "matching calls with the variable :foo=:bar" do
          let :guards do
            [[:[], :foo] => :bar]
          end

          let(:call) { Adhearsion::Call.new }

          context "with :foo=:bar" do
            before { call[:foo] = :bar }
            it { should_match_the_call }
          end

          context "with :foo=:baz" do
            before { call[:foo] = :baz }
            it { should_not_match_the_call }
          end

          context "with :foo unset" do
            it { should_not_match_the_call }
          end
        end
      end

      describe "dispatching a call" do
        let(:call) { Call.new }

        let(:latch) { CountDownLatch.new 1 }

        before { call.wrapped_object.stub :write_and_await_response }

        context "via a call controller" do
          let(:controller)  { CallController }
          let(:route)       { Route.new 'foobar', controller }

          it "should immediately fire the :call_routed event giving the call and route" do
            Adhearsion::Events.should_receive(:trigger_immediately).once.with(:call_routed, call: call, route: route)
            call.should_receive(:hangup).once
            route.dispatch call, lambda { latch.countdown! }
            latch.wait(2).should be true
          end

          it "should accept the call" do
            call.should_receive(:accept).once
            route.dispatch call, lambda { latch.countdown! }
            latch.wait(2).should be true
          end

          it "should instruct the call to use an instance of the controller" do
            call.should_receive(:execute_controller).once.with kind_of(controller), kind_of(Proc)
            route.dispatch call
          end

          it "should hangup the call after all controllers have executed" do
            call.should_receive(:hangup).once
            route.dispatch call, lambda { latch.countdown! }
            latch.wait(2).should be true
          end

          context "when the CallController mutates its metadata" do
            let :controller do
              Class.new CallController do
                def run
                  metadata[:foo] = 'bar'
                end
              end
            end

            before do
              route.dispatch call
            end

            it "gives the next call fresh metadata" do
              expected_controller = controller.new call, nil
              call.should_receive(:execute_controller).once.with expected_controller, kind_of(Proc)
              route.dispatch call
            end
          end

          context 'with the :ahn_prevent_hangup call variable set' do
            before { call[:ahn_prevent_hangup] = true }

            it "should not hangup the call after controller execution" do
              call.should_receive(:hangup).never
              route.dispatch call, lambda { latch.countdown! }
              latch.wait(2).should be true
            end
          end

          context "if hangup raises a Call::Hangup" do
            before { call.should_receive(:hangup).once.and_raise Call::Hangup }

            it "should not raise an exception" do
              lambda do
                route.dispatch call, lambda { latch.countdown! }
                latch.wait(2).should be true
              end.should_not raise_error
            end
          end

          context "if the call is dead when trying to clear it up" do
            let :controller do
              Class.new CallController do
                def run
                  call.terminate
                end
              end
            end

            it "should not raise an exception" do
              lambda do
                route.dispatch call, lambda { latch.countdown! }
                latch.wait(2).should be true
              end.should_not raise_error
            end
          end
        end

        context "via a block" do
          let :route do
            Route.new 'foobar' do
              :foobar
            end
          end

          it "should instruct the call to use a CallController with the correct block" do
            call.should_receive(:execute_controller).once.with(kind_of(CallController), kind_of(Proc)).and_return do |controller|
              controller.block.call.should be == :foobar
            end
            route.dispatch call
          end
        end
      end
    end
  end
end
