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

  it '#stop_when_zero_calls should wait until the list of active calls reaches 0' do
    calls = ThreadSafeArray.new
    3.times { calls << Object.new }
    flexmock(Adhearsion).should_receive(:active_calls).and_return calls
    flexmock(Adhearsion::Process.instance).should_receive(:force_stop).once
    Thread.new { sleep 1; calls.pop }
    Adhearsion::Process.stop_when_zero_calls
  end

  it 'should trigger :shutdown events on force_stop' do
    flexmock(Adhearsion::Events).should_receive(:trigger_immediately).once.with(:shutdown)
    Adhearsion::Process.force_stop
  end

  it 'should send a hangup to all active calls on force_stop' do
    calls = []
    3.times do
      fake_call = Object.new
      flexmock(fake_call).should_receive(:hangup).once
      calls << fake_call
    end
    flexmock(Adhearsion).should_receive(:active_calls).and_return calls
    Adhearsion::Process.force_stop
  end
end