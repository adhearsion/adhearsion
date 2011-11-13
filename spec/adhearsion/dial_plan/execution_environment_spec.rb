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

      it "should define accessors for other contexts in the dialplan" do
        call = new_call_for_context :am_not_for_kokoa!
        bogus_dialplan = <<-DIALPLAN
          am_not_for_kokoa! {}
          icanhascheezburger? {}
          these_context_names_do_not_really_matter {}
        DIALPLAN

        mock_dialplan_with bogus_dialplan

        manager = Adhearsion::DialPlan::Manager.new
        manager.dial_plan.entry_points.empty?.should_not be true

        flexmock(call).should_receive(:hangup!).once

        manager.handle call

        %w(these_context_names_do_not_really_matter icanhascheezburger? am_not_for_kokoa!).each do |context_name|
          manager.context.respond_to?(context_name).should be true
        end
      end

    end
  end
end
