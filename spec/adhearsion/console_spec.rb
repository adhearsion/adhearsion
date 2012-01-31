require 'spec_helper'

module Adhearsion
  describe Console do
    describe "providing hooks to include console functionality" do
      it "should allow mixing in a module globally on all CallController classes" do
        Adhearsion::Console.mixin TestBiscuit
        Adhearsion::Console.throwadogabone.should be true
      end
    end

    describe 'testing for libedit vs. readline' do
      it 'should return true when detecting readline' do
        flexmock(Readline).should_receive(:emacs_editing_mode).once.and_return true
        Adhearsion::Console.libedit?.should be false
      end

      it 'should return false when detecting libedit' do
        flexmock(Readline).should_receive(:emacs_editing_mode).once.and_raise NotImplementedError
        Adhearsion::Console.libedit?.should be true
      end
    end

    describe "#log_level" do
      context "with a value" do
        it "should set the log level via Adhearsion::Logging" do
          flexmock(Adhearsion::Logging).should_receive(:level=).once.with(:foo)
          Console.log_level :foo
        end
      end

      context "without a value" do
        it "should return the current level as a symbol" do
          Adhearsion::Logging.level = :fatal
          Console.log_level.should == :fatal
        end
      end
    end

    describe "#silence!" do
      it "should delegate to Adhearsion::Logging" do
        flexmock(Adhearsion::Logging).should_receive(:silence!).once
        Console.silence!
      end
    end

    describe "#unsilence!" do
      it "should delegate to Adhearsion::Logging" do
        flexmock(Adhearsion::Logging).should_receive(:unsilence!).once
        Console.unsilence!
      end
    end

    describe "#shutdown" do
      it "should tell the process to shutdown" do
        flexmock(Adhearsion::Process).should_receive(:shutdown!).once
        Console.shutdown
      end
    end
  end
end