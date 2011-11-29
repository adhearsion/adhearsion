require 'spec_helper'

module Adhearsion
  class DialPlan
    describe Manager do

      include DialplanTestingHelper

      let(:context_name)  { :adhearsion }
      let(:mock_context)  { flexmock('a context') }
      let(:call)          { new_call_for_context context_name }

      describe "basic operation" do
        before :each do
          mock_dial_plan_lookup_for_context_name

          flexmock(Loader).should_receive(:load_dialplans).and_return {
            flexmock("loaded contexts", :contexts => nil)
          }

          call.context.should be context_name # Sanity check context name being set
        end

        it 'invokes the before_call event' do
          flexmock(Events).should_receive(:trigger_immediately).once.with(:before_call, call).and_throw :triggered

          the_following_code {
            subject.handle call
          }.should throw_symbol :triggered
        end

        it "Given a Call, the manager finds the call's desired entry point based on the originating context" do
          subject.entry_point_for(call).should be mock_context
        end

        describe "handles a call" do
          it "by executing the proper context" do
            flexmock(ExecutionEnvironment).new_instances.should_receive(:run).once
            subject.handle call
          end

          it "and catches standard errors, raising an exception event" do
            flexmock(ExecutionEnvironment).new_instances.should_receive(:run).once.and_raise(StandardError)
            flexmock(Events).should_receive(:trigger).once.with(:exception, StandardError)
            subject.handle call
          end

          it "catches Hangup exceptions and fires the after_call event immediately" do
            flexmock(Events).should_receive(:trigger_immediately).once.with(:before_call, call)
            flexmock(ExecutionEnvironment).new_instances.should_receive(:run).once.and_raise(Hangup)
            flexmock(Events).should_receive(:trigger_immediately).once.with(:after_call, call)
            subject.handle call
          end

          it "hangs up the call" do
            flexmock(ExecutionEnvironment).new_instances.should_receive(:run).once.ordered.and_raise(StandardError)
            flexmock(call).should_receive(:hangup!).once.ordered
            subject.handle call
          end
        end

        it "should raise a NoContextError exception if the targeted context is not found" do
          the_following_code {
            flexmock(subject).should_receive(:entry_point_for).and_return nil
            subject.handle call
          }.should raise_error(Manager::NoContextError)
        end

        it 'should send :accept to the execution environment if Adhearsion.config.automatically_accept_incoming_calls is set' do
          flexmock(ExecutionEnvironment).new_instances.should_receive(:accept).once.and_throw :accepted_call!
          Adhearsion.config.platform do |config|
            config.automatically_accept_incoming_calls = true
          end
          the_following_code {
            subject.handle call
          }.should throw_symbol :accepted_call!
        end

        it 'should NOT send :accept to the execution environment if Adhearsion.config.automatically_accept_incoming_calls is NOT set' do
          Adhearsion.config.platform do |config|
            config.automatically_accept_incoming_calls = false
          end

          entry_point = DialplanContextProc.new(:does_not_matter) { "Do nothing" }
          flexmock(subject).should_receive(:entry_point_for).once.with(call).and_return(entry_point)

          execution_env = ExecutionEnvironment.create(call, nil)
          flexmock(execution_env).should_receive(:entry_point).and_return entry_point
          flexmock(execution_env).should_receive(:accept).never

          flexmock(ExecutionEnvironment).should_receive(:new).once.and_return execution_env

          subject.handle call
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

        flexmock(call).should_receive :write_and_await_response

        manager = Adhearsion::DialPlan::Manager.new
        manager.dial_plan.entry_points.empty?.should_not be true

        flexmock(call).should_receive(:hangup!).once

        manager.handle call

        %w(these_context_names_do_not_really_matter icanhascheezburger? am_not_for_kokoa!).each do |context_name|
          manager.context.respond_to?(context_name).should be true
        end
      end

      it "with_next_message should execute its block with the message from the inbox" do
        pending
        [:one, :two, :three].each { |message| call.inbox << message }

        dialplan = %{ adhearsion {  with_next_message { |message| throw message } } }
        executing_dialplan(:entrance => dialplan, :call => call).should throw_symbol :one
      end

      describe "#messages_waiting?" do
        let(:dialplan) { %{ adhearsion { throw messages_waiting? ? :yes : :no } } }

        it "should return false if the inbox is empty" do
          pending
          executing_dialplan(:entrance => dialplan, :call => call).should throw_symbol :no
        end

        it "should return false if the inbox is not empty" do
          pending
          call.inbox << Object.new
          executing_dialplan(:entrance => dialplan, :call => call).should throw_symbol :yes
        end
      end

      describe "control statements" do

        it "should catch ControlPassingExceptions" do
          Adhearsion.config.platform.automatically_accept_incoming_calls = false
          dialplan = %{
            foo { raise Adhearsion::DSL::Dialplan::ControlPassingException.new(bar) }
            bar {}
          }
          executing_dialplan(:foo => dialplan).should_not raise_error
        end

        it "All dialplan contexts should be available at context execution time" do
          dialplan = %{
            context_defined_first {
              throw :i_see_it if context_defined_second
            }
            context_defined_second {}
          }
          executing_dialplan(:context_defined_first => dialplan).should throw_symbol :i_see_it
        end

        test_dialplan_inclusions = true
        if Object.const_defined?("JRUBY_VERSION")
          require 'adhearsion/version'
          curver = Adhearsion::PkgVersion.new(JRUBY_VERSION)
          minver = Adhearsion::PkgVersion.new("1.6.0")
          if curver < minver
            # JRuby contains a bug that breaks some of the menu functionality
            # See: https://adhearsion.lighthouseapp.com/projects/5871/tickets/92-menu-method-under-jruby-does-not-appear-to-work
            test_dialplan_inclusions = false
          end
        end

        if test_dialplan_inclusions
          it "Proc#+@ should execute the other context" do
            dialplan = %{
              eins {
                +zwei
                throw :eins
              }
              zwei {
                throw :zwei
              }
            }
            executing_dialplan(:eins => dialplan).should throw_symbol :zwei
          end

          it "Proc#+@ should not return to its originating context" do
            dialplan = %{
              andere {}
              zuerst {
                +andere
                throw :after_control_statement
              }
            }
            executing_dialplan(:zuerst => dialplan).should_not raise_error
          end
        end

        it "new constants should still be accessible within the dialplan" do
          Adhearsion.config.platform.automatically_accept_incoming_calls = false
          ::Jicksta = :Jicksta
          dialplan = %{
            constant_test {
              Jicksta.should == :Jicksta
            }
          }
          executing_dialplan(:constant_test => dialplan).should_not raise_error
        end
      end
    end
  end
end
