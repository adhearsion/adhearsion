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
      expect(Events).to receive(:trigger_immediately).once.with(:stop_requested).ordered
      expect(Events).to receive(:trigger_immediately).once.with(:shutdown).ordered
      Adhearsion::Process.booted
      Adhearsion::Process.shutdown
      sleep 0.2
    end

    it '#stop_when_zero_calls should wait until the list of active calls reaches 0' do
      skip
      calls = ThreadSafeArray.new
      3.times do
        fake_call = Object.new
        expect(fake_call).to receive(:hangup).once
        calls << fake_call
      end
      expect(Adhearsion).to receive(:active_calls).and_return calls
      expect(Adhearsion::Process.instance).to receive(:final_shutdown).once
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
      expect(::Process).to receive(:exit).with(1).once.and_return true
      Adhearsion::Process.force_stop
    end

    describe "#final_shutdown" do
      it "should hang up active calls" do
        3.times do
          fake_call = Call.new
          allow(fake_call).to receive_messages :id => random_call_id
          expect(fake_call).to receive(:hangup).once
          Adhearsion.active_calls << fake_call
        end

        Adhearsion::Process.final_shutdown

        Adhearsion.active_calls.clear
      end

      it "should trigger shutdown handlers synchronously" do
        foo = lambda { |b| b }

        expect(foo).to receive(:[]).once.with(:a).ordered
        expect(foo).to receive(:[]).once.with(:b).ordered
        expect(foo).to receive(:[]).once.with(:c).ordered

        Events.shutdown { sleep 2; foo[:a] }
        Events.shutdown { sleep 1; foo[:b] }
        Events.shutdown { foo[:c] }

        Adhearsion::Process.final_shutdown
      end

      it "should stop the console" do
        expect(Console).to receive(:stop).once
        Adhearsion::Process.final_shutdown
      end
    end

    it 'should handle subsequent :shutdown events in the correct order' do
      Adhearsion::Process.booted
      expect(Adhearsion::Process.state_name).to be :running
      Adhearsion::Process.shutdown
      expect(Adhearsion::Process.state_name).to be :stopping
      Adhearsion::Process.shutdown
      expect(Adhearsion::Process.state_name).to be :rejecting
      Adhearsion::Process.shutdown
      expect(Adhearsion::Process.state_name).to be :stopped
      expect(Adhearsion::Process.instance).to receive(:die_now!).once
      Adhearsion::Process.shutdown
      sleep 0.2
    end

    it 'should forcibly kill the Adhearsion process on :force_stop' do
      expect(::Process).to receive(:exit).once.with(1)
      Adhearsion::Process.force_stop
    end

    describe "#fqdn" do
      it "should be a string" do
        expect(Adhearsion::Process.fqdn).to be_a String
      end

      context "when networking issues crop up" do
        before { allow(Socket).to receive(:gethostbyname).and_raise(SocketError) }

        it "should raise SocketError" do
          expect { Adhearsion::Process.fqdn }.to raise_error(SocketError)
        end
      end
    end
  end
end
