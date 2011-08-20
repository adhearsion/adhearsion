require 'spec_helper'

module Adhearsion
  class DialPlan
    describe ExecutionEnvironment do

      let(:variables)   { { :context => "zomgzlols", :caller_id => "Ponce de Leon" } }
      let(:call)        { Adhearsion::Call.new mock_offer }
      let(:entry_point) { lambda {} }

      subject { ExecutionEnvironment.create call, entry_point }

      include DialplanTestingHelper

      it "should extend itself with behavior specific to the voip platform which originated the call" do
        ExecutionEnvironment.included_modules.should_not include(Adhearsion::Rayo::Commands)
        subject.metaclass.included_modules.should include(Adhearsion::Rayo::Commands)
      end

      describe "an executed context" do
        it "should raise a NameError error when a missing constant is referenced" do
          the_following_code {
            flexmock(Adhearsion::AHN_CONFIG).should_receive(:automatically_accept_incoming_calls).and_return false
            context = :context_with_missing_constant
            call = new_call_for_context context
            mock_dialplan_with "#{context} { ThisConstantDoesntExist }"
            Manager.new.handle call
          }.should raise_error NameError
        end
      end

      it "should define variables accessors within itself" do
        pending
        call.variables.empty?.should be false
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

        manager.handle call

        %w(these_context_names_do_not_really_matter icanhascheezburger? am_not_for_kokoa!).each do |context_name|
          manager.context.respond_to?(context_name).should be true
        end
      end

    end
  end
end
