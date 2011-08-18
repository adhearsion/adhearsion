require 'spec_helper'

module Adhearsion
  describe Dispatcher do
    def stub_before_call_hooks!
      flexstub(Events).should_receive(:trigger).with([:before_call], Proc).and_return
    end

    def stub_confirmation_manager!
      flexstub(DialPlan::ConfirmationManager).should_receive(:confirmation_call?).and_return false
    end

    before do
      pending
      Adhearsion::Events.reinitialize_theatre!
    end

    it 'should hand the call off to a new Manager if the request is agi://IP_ADDRESS_HERE' do
      stub_before_call_hooks!
      call_mock = flexmock 'A new mock call that will be passed to the manager', :variables => {}, :unique_identifier => "X"

      flexmock(Adhearsion).should_receive(:receive_call_from).once.and_return call_mock
      manager_mock = flexmock 'a mock dialplan manager'
      manager_mock.should_receive(:handle).once.with(call_mock)
      flexmock(Adhearsion::DialPlan::Manager).should_receive(:new).once.and_return manager_mock
      server.serve(nil)
    end

    it 'should hand off a call to a ConfirmationManager if the request begins with confirm!' do
      confirm_options = Adhearsion::DialPlan::ConfirmationManager.encode_hash_for_dial_macro_argument :timeout => 20, :key => "#"
      call_mock = flexmock "a call that has network_script as a variable", :variables => {:network_script => "confirm!#{confirm_options[/^M\(\^?(.+)\)$/,1]}"}, :unique_identifier => "X"
      manager_mock = flexmock 'a mock ConfirmationManager'

      the_following_code {
        flexstub(Adhearsion).should_receive(:receive_call_from).once.and_return(call_mock)
        flexmock(Adhearsion::DialPlan::ConfirmationManager).should_receive(:confirmation_call?).once.with(call_mock).and_return true
        flexmock(Adhearsion::DialPlan::ConfirmationManager).should_receive(:handle).once.with(call_mock).and_throw :handled_call!
        server.serve(nil)
      }.should throw_symbol :handled_call!
    end

    it 'calling the serve() method invokes the before_call event' do
      mock_io   = flexmock "mock IO object given to AGIServer#serve"
      mock_call = flexmock "mock Call"
      flexmock(Adhearsion).should_receive(:receive_call_from).once.with(mock_io).and_return mock_call

      flexmock(Adhearsion::Events).should_receive(:trigger_immediately).once.with([:asterisk, :before_call], mock_call).
          and_throw :triggered

      the_following_code {
        server.serve mock_io
      }.should throw_symbol :triggered
    end

    it 'should execute the hungup_call event when a HungupExtensionCallException is raised' do
      call_mock = flexmock 'a bogus call', :hungup_call? => true, :variables => {:extension => "h"}, :unique_identifier => "X"
      mock_env  = flexmock "A mock execution environment which gets passed along in the HungupExtensionCallException"

      stub_confirmation_manager!
      flexstub(Adhearsion).should_receive(:receive_call_from).once.and_return(call_mock)
      flexmock(Adhearsion::DialPlan::Manager).should_receive(:handle).once.and_raise Adhearsion::HungupExtensionCallException.new(mock_env)
      flexmock(Adhearsion::Events).should_receive(:trigger).once.with([:asterisk, :hungup_call], mock_env).and_throw :hungup_call

      the_following_code { server.serve nil }.should throw_symbol :hungup_call
    end

    it 'should execute the OnFailedCall hooks when a FailedExtensionCallException is raised' do
      call_mock = flexmock 'a bogus call', :failed_call? => true, :variables => {:extension => "failed"}, :unique_identifier => "X"
      mock_env  = flexmock "A mock execution environment which gets passed along in the HungupExtensionCallException", :failed_reason => "does not matter"

      server = Adhearsion::Asterisk::AGI::Server::RubyServer.new :port, :host

      flexmock(Adhearsion).should_receive(:receive_call_from).once.and_return(call_mock)
      flexmock(Adhearsion::DialPlan::Manager).should_receive(:handle).once.and_raise Adhearsion::FailedExtensionCallException.new(mock_env)
      flexmock(Adhearsion::Events).should_receive(:trigger).once.with([:asterisk, :failed_call], mock_env).and_throw :failed_call
      the_following_code { server.serve nil }.should throw_symbol :failed_call
    end

  end
end
