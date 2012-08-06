# encoding: utf-8

require 'spec_helper'

module Adhearsion
  class Router
    describe EventedRoute do
      let(:name) { 'catchall' }

      subject { Route.new name }

      before { subject.extend described_class }

      it { should be_evented }

      describe "dispatching a call" do
        let(:call) { Call.new }

        context "via a block" do
          subject :route do
            Route.new 'foobar' do |c|
              c.foo
            end
          end

          it "should yield the call to the block" do
            flexmock(call).should_receive(:foo).once
            route.dispatch call
          end
        end
      end
    end
  end
end
