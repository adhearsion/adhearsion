# encoding: utf-8

require 'spec_helper'

module Adhearsion
  class Router
    describe UnacceptingRoute do
      let(:name) { 'catchall' }

      subject { Route.new name }

      before { subject.extend described_class }

      it { is_expected.not_to be_accepting }

      describe "dispatching a call" do
        let(:call) { Call.new }

        let(:latch) { CountDownLatch.new 1 }

        before { allow(call.wrapped_object).to receive :write_and_await_response }

        context "via a call controller" do
          let(:controller)  { CallController }
          subject(:route)   { Route.new 'foobar', controller }

          it "should not accept the call" do
            expect(call).to receive(:accept).never
            route.dispatch call, lambda { latch.countdown! }
            expect(latch.wait(2)).to be true
          end

          it "should instruct the call to use an instance of the controller" do
            expect(call).to receive(:execute_controller).once.with kind_of(controller), kind_of(Proc)
            route.dispatch call
          end

          it "should hangup the call after all controllers have executed" do
            expect(call).to receive(:hangup).once
            route.dispatch call, lambda { latch.countdown! }
            expect(latch.wait(2)).to be true
          end

          context "if hangup raises a Call::Hangup" do
            before { expect(call).to receive(:hangup).once.and_raise Call::Hangup }

            it "should not raise an exception" do
              expect do
                route.dispatch call, lambda { latch.countdown! }
                expect(latch.wait(2)).to be true
              end.not_to raise_error
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
            expect(call).to receive(:execute_controller).once.with(kind_of(CallController), kind_of(Proc)) do |controller|
              expect(controller.block.call).to eq(:foobar)
            end
            route.dispatch call
          end
        end
      end
    end
  end
end
