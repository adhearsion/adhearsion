require 'spec_helper'

module Adhearsion
  class DialPlan
    describe ExecutionEnvironment do

      let(:headers)     { {:x_foo => 'bar'} }
      let(:call)        { Adhearsion::Call.new mock_offer(nil, headers) }
      let(:entry_point) { lambda {} }

      subject { ExecutionEnvironment.create call, entry_point }

      include DialplanTestingHelper

      it "should extend itself with behavior specific to the voip platform which originated the call" do
        ExecutionEnvironment.included_modules.should_not include(Adhearsion::Punchblock::Commands)
        subject.metaclass.included_modules.should include(Adhearsion::Punchblock::Commands)
      end

      it "should add plugin dialplan methods" do
        flexmock(Adhearsion::Plugin).should_receive(:methods_scope).once.and_return({:dialplan => Module.new { def foo; end}})
        e = ExecutionEnvironment.create call, entry_point
        e.should respond_to(:foo)
      end

      before { flexmock(Adhearsion.config).should_receive(:automatically_accept_incoming_calls).and_return false }

      it "should define variables accessor methods" do
        call.variables.empty?.should be false
        call.variables.should
        call.variables.each do |key, value|
          subject.send(key).should be value
        end
      end
    end
  end
end
