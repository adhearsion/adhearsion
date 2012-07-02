# encoding: utf-8

require 'spec_helper'

module Adhearsion
  describe Adhearsion::Process do
    before :all do
      Adhearsion.active_calls.clear
    end

    before :each do
      Adhearsion::Process.reset
    end

    it 'should trigger :stop_requested events on #shutdown' do
      flexmock(Events).should_receive(:trigger_immediately).once.with(:stop_requested).ordered
      flexmock(Events).should_receive(:trigger_immediately).once.with(:shutdown).ordered
      Adhearsion::Process.booted
      Adhearsion::Process.shutdown
      sleep 0.2
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
      3.times do
        calls << Thread.new do
          sleep 1
          calls.pop
        end
      end
      Adhearsion::Process.stop_when_zero_calls
      calls.each { |thread| thread.join }
    end

    it 'should terminate the process immediately on #force_stop' do
      flexmock(::Process).should_receive(:exit).with(1).once.and_return true
      Adhearsion::Process.force_stop
    end

    describe "#final_shutdown" do
      it "should hang up active calls" do
        3.times do
          fake_call = flexmock Call.new, :id => random_call_id
          flexmock(fake_call).should_receive(:hangup!).once
          Adhearsion.active_calls << fake_call
        end

        Adhearsion::Process.final_shutdown

        Adhearsion.active_calls.clear
      end

      it "should trigger shutdown handlers synchronously" do
        foo = lambda { |b| b }

        flexmock(foo).should_receive(:[]).once.with(:a).ordered
        flexmock(foo).should_receive(:[]).once.with(:b).ordered
        flexmock(foo).should_receive(:[]).once.with(:c).ordered

        Events.shutdown { sleep 2; foo[:a] }
        Events.shutdown { sleep 1; foo[:b] }
        Events.shutdown { foo[:c] }

        Adhearsion::Process.final_shutdown
      end

      it "should stop the console" do
        flexmock(Console).should_receive(:stop).once
        Adhearsion::Process.final_shutdown
      end
    end

    it 'should handle subsequent :shutdown events in the correct order' do
      Adhearsion::Process.booted
      Adhearsion::Process.state_name.should be :running
      Adhearsion::Process.shutdown
      Adhearsion::Process.state_name.should be :stopping
      Adhearsion::Process.shutdown
      Adhearsion::Process.state_name.should be :rejecting
      Adhearsion::Process.shutdown
      Adhearsion::Process.state_name.should be :stopped
      flexmock(Adhearsion::Process.instance).should_receive(:die_now!).once
      Adhearsion::Process.shutdown
      sleep 0.2
    end

    it 'should forcibly kill the Adhearsion process on :force_stop' do
      flexmock(::Process).should_receive(:exit).once.with(1)
      Adhearsion::Process.force_stop
    end
  end
end
