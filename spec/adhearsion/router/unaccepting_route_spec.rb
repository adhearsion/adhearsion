# encoding: utf-8

require 'spec_helper'

module Adhearsion
  class Router
    describe UnacceptingRoute do
      let(:name) { 'catchall' }

      subject { Route.new name }

      before { subject.extend described_class }

      it { should_not be_accepting }

      describe "dispatching a call" do
        let(:call) { Call.new }

        let(:latch) { CountDownLatch.new 1 }

        before { call.wrapped_object.stub :write_and_await_response }

        context "via a call controller" do
          let(:controller)  { CallController }
          subject(:route)   { Route.new 'foobar', controller }

          it "should not accept the call" do
            call.should_receive(:accept).never
            route.dispatch call, lambda { latch.countdown! }
            latch.wait(LATCH_TIMEOUT).should be true
          end

          it "should instruct the call to use an instance of the controller" do
            call.should_receive(:execute_controller).once.with kind_of(controller), kind_of(Proc)
            route.dispatch call
          end

          it "should hangup the call after all controllers have executed" do
            call.should_receive(:hangup).once
            route.dispatch call, lambda { latch.countdown! }
            latch.wait(LATCH_TIMEOUT).should be true
          end

          context "if hangup raises a Call::Hangup" do
            before { call.should_receive(:hangup).once.and_raise Call::Hangup }

            it "should not raise an exception" do
              lambda do
                route.dispatch call, lambda { latch.countdown! }
                latch.wait(LATCH_TIMEOUT).should be true
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
