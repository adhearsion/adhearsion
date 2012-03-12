# encoding: utf-8

require 'spec_helper'

module Adhearsion
  describe Console do
    before do
      flexmock Console.instance, :pry => nil
    end

    include FlexMock::ArgumentTypes
    describe "providing hooks to include console functionality" do
      it "should allow mixing in a module globally on all CallController classes" do
        Console.mixin TestBiscuit
        Console.throwadogabone.should be true
      end
    end

    describe 'testing for libedit vs. readline' do
      it 'should return true when detecting readline' do
        flexmock(Readline).should_receive(:emacs_editing_mode).once.and_return true
        Console.libedit?.should be false
      end

      it 'should return false when detecting libedit' do
        flexmock(Readline).should_receive(:emacs_editing_mode).once.and_raise NotImplementedError
        Console.libedit?.should be true
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
          Console.log_level.should be == :fatal
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

    describe "#shutdown!" do
      it "should tell the process to shutdown" do
        flexmock(Adhearsion::Process).should_receive(:shutdown!).once
        Console.shutdown!
      end
    end

    describe "#take" do
      let(:call)    { Call.new }
      let(:call_id) { rand.to_s }

      before do
        Adhearsion.active_calls.clear!
        flexmock(call).should_receive(:id => call_id)
      end

      context "with a call" do
        it "should interact with the call" do
          flexmock(Console.instance).should_receive(:interact_with_call).once.with call
          Console.take call
        end
      end

      context "with no argument" do
        context "with one currently active call" do
          before do
            Adhearsion.active_calls << call
          end

          it "should interact with the current call" do
            flexmock(Console.instance).should_receive(:interact_with_call).once.with call
            Console.take
          end
        end

        context "with multiple current calls" do
          let(:call2) { Call.new }

          before do
            flexmock(call2).should_receive :id => rand.to_s
            Adhearsion.active_calls << call << call2
          end

          it "should allow selection of the call to use" do
            mock_io = StringIO.new
            Console.input = mock_io
            flexmock(mock_io).should_receive(:gets).once.and_return "1\n"
            flexmock(Console.instance).should_receive(:interact_with_call).once.with call2
            Console.take
          end
        end
      end

      context "with a call ID" do
        context "if an active call with that ID exists" do
          before do
            Adhearsion.active_calls << call
          end

          it "should interact with that call" do
            flexmock(Console.instance).should_receive(:interact_with_call).once.with call
            Console.take call_id
          end
        end

        context "if an active call with that ID does not exist" do
          it "should log an error explaining that the call does not exist" do
            flexmock(Console.logger).should_receive(:error).once.with(/does not exist/)
            flexmock(Console.instance).should_receive(:interact_with_call).never
            Console.take call_id
          end
        end
      end
    end

    describe "#interact_with_call" do
      let(:call) { Call.new }

      it "should pause the call's controllers, and unpause even if the interactive controller raises" do
        flexmock(call).should_receive(:pause_controllers).once.ordered
        flexmock(CallController).should_receive(:exec).once.ordered.and_raise StandardError
        flexmock(call).should_receive(:resume_controllers).once.ordered
        lambda { Console.interact_with_call call }.should raise_error StandardError
      end

      it "should execute an interactive call controller on the call" do
        flexmock(CallController).should_receive(:exec).once.with(on do |c|
          c.should be_a Console::InteractiveController
          c.call.should be call
        end)
        Console.interact_with_call call
      end
    end
  end
end