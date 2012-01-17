require 'spec_helper'

describe Adhearsion::Process do
  before :each do
    Adhearsion::Process.reset
  end

  it 'should trigger :stop_requested events on #shutdown' do
    flexmock(Adhearsion::Events).should_receive(:trigger_immediately).once.with(:stop_requested)
    Adhearsion::Process.booted
    Adhearsion::Process.shutdown
  end

  it '#stop_when_zero_calls should wait until the list of active calls reaches 0' do
    pending
    calls = ThreadSafeArray.new
    3.times do
      fake_call = Object.new
      flexmock(fake_call).should_receive(:hangup).once
      calls << fake_call
    end
    flexmock(Adhearsion).should_receive(:active_calls).and_return calls
    flexmock(Adhearsion::Process.instance).should_receive(:final_shutdown).once
    calls = []
    3.times { calls << Thread.new { sleep 1; calls.pop } }
    Adhearsion::Process.stop_when_zero_calls
    calls.each { |thread| thread.join }
  end

  it 'should terminate the process immediately on #force_stop' do
    flexmock(::Process).should_receive(:exit).with(1).once.and_return true
    Adhearsion::Process.force_stop
  end
end
