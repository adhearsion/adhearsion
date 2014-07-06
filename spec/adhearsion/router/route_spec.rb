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

        it { is_expected.not_to be_evented }
        it { is_expected.to be_accepting }

        describe "with a class target and guards" do
          let(:target) { CallController }

          subject { Route.new name, target, *guards }

          describe '#name' do
            subject { super().name }
            it { is_expected.to eq(name) }
          end

          describe '#target' do
            subject { super().target }
            it { is_expected.to eq(target) }
          end

          describe '#guards' do
            subject { super().guards }
            it { is_expected.to eq(guards) }
          end
        end

        describe "with a block target and guards" do
          subject { Route.new(name, *guards) { :foo } }

          describe '#name' do
            subject { super().name }
            it { is_expected.to eq(name) }
          end

          describe '#target' do
            subject { super().target }
            it { is_expected.to be_a Proc }
          end

          describe '#guards' do
            subject { super().guards }
            it { is_expected.to eq(guards) }
          end
        end
      end

      describe "a guarded route" do
        subject { Route.new 'foobar', CallController, *guards }

        def should_match_the_call
          expect(subject.match?(call)).to be true
        end

        def should_not_match_the_call
          expect(subject.match?(call)).to be false
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

        before { allow(call.wrapped_object).to receive :write_and_await_response }

        context "via a call controller" do
          let(:controller)  { CallController }
          let(:route)       { Route.new 'foobar', controller }

          it "should immediately fire the :call_routed event giving the call and route" do
            expect(Adhearsion::Events).to receive(:trigger_immediately).once.with(:call_routed, call: call, route: route)
            expect(call).to receive(:hangup).once
            route.dispatch call, lambda { latch.countdown! }
            expect(latch.wait(2)).to be true
          end

          it "should accept the call" do
            expect(call).to receive(:accept).once
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

          context "when the call has already ended before routing can begin" do
            before { Celluloid::Actor.kill call }

            it "should fall through cleanly" do
              expect { route.dispatch call }.not_to raise_error
            end
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
              expect(call).to receive(:execute_controller).once.with expected_controller, kind_of(Proc)
              route.dispatch call
            end
          end

          context 'with the Call#auto_hangup set to false' do
            before { call.auto_hangup = false }

            it "should not hangup the call after controller execution" do
              expect(call).to receive(:hangup).never
              route.dispatch call, lambda { latch.countdown! }
              expect(latch.wait(2)).to be true
            end
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

          context "if the call is dead when trying to clear it up" do
            let :controller do
              Class.new CallController do
                def run
                  call.terminate
                end
              end
            end

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
