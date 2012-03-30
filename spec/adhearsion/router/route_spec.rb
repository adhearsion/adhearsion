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

        context "via a call controller" do
          let(:controller)  { CallController }
          let(:route)       { Route.new 'foobar', controller }

          it "should instruct the call to use an instance of the controller" do
            flexmock(call).should_receive(:execute_controller).once.with controller, Proc
            route.dispatcher.call call
          end

          it "should hangup the call after all controllers have executed" do
            flexmock(call).should_receive(:hangup).once
            route.dispatcher.call call, lambda { latch.countdown! }
            latch.wait(2).should be true
          end

          context "if hangup raises a Call::Hangup" do
            before { flexmock(call).should_receive(:hangup).once.and_raise Call::Hangup }

            it "should not raise an exception" do
              lambda do
                route.dispatcher.call call, lambda { latch.countdown! }
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
            flexmock(call).should_receive(:execute_controller).once.with(CallController, Proc).and_return do |controller|
              controller.block.call.should be == :foobar
            end
            route.dispatcher.call call
          end
        end
      end
    end
  end
end
