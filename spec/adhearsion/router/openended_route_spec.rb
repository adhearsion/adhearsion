# encoding: utf-8

require 'spec_helper'

module Adhearsion
  class Router
    describe OpenendedRoute do
      let(:name) { 'catchall' }

      subject { Route.new name }

      before { subject.extend described_class }

      it { should be_openended }

      describe "dispatching a call" do
        let(:call) { Call.new }

        let(:latch) { CountDownLatch.new 1 }

        before { flexmock(call.wrapped_object).should_receive :write_and_await_response }

        context "via a call controller" do
          let(:controller)  { CallController }
          subject(:route)   { Route.new 'foobar', controller }

          it "should accept the call" do
            flexmock(call).should_receive(:accept).once
            route.dispatch call
          end

          it "should instruct the call to use an instance of the controller" do
            flexmock(call).should_receive(:execute_controller).once.with controller, Proc
            route.dispatch call
          end

          it "should not hangup the call after all controllers have executed" do
            flexmock(call).should_receive(:hangup).never
            route.dispatch call, lambda { latch.countdown! }
            latch.wait(2).should be true
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
            route.dispatch call
          end
        end
      end
    end
  end
end
