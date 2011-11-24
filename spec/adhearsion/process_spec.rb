require 'spec_helper'

describe Adhearsion::Process do
  before :each do
    Adhearsion::Process.reset
  end

  it 'should trigger :stop_requested events on shutdown' do
    flexmock(Adhearsion::Events).should_receive(:trigger_immediately).once.with(:stop_requested)
    Adhearsion::Process.booted
    Adhearsion::Process.shutdown
  end

  it 'should trigger :shutdown events on force_stop' do
    pending 'How to test after_transition events?'
    flexmock(Adhearsion::Events).should_receive(:trigger_immediately).once.with(:shutdown)
    Adhearsion::Process.force_stop
  end

  it 'should send a hangup to all active calls on force_stop' do
    pending
  end
end
