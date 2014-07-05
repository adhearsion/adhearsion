# encoding: utf-8

require 'spec_helper'

module Adhearsion
  describe Console do
    before do
      Console.instance.stub :pry => nil
    end

    describe "providing hooks to include console functionality" do
      it "should allow mixing in a module globally on all CallController classes" do
        Console.mixin TestBiscuit
        expect(Console.throwadogabone).to be true
      end
    end

    unless defined? JRUBY_VERSION # These tests are not valid on JRuby
      describe 'testing for readline' do
        it 'should return false when detecting readline' do
          expect(Readline).to receive(:emacs_editing_mode).once.and_return true
          expect(Console.cruby_with_readline?).to be true
        end

        it 'should return true when detecting libedit' do
          expect(Readline).to receive(:emacs_editing_mode).once.and_raise NotImplementedError
          expect(Console.cruby_with_readline?).to be false
        end
      end
    end

    describe "#log_level" do
      context "with a value" do
        it "should set the log level via Adhearsion::Logging" do
          expect(Adhearsion::Logging).to receive(:level=).once.with(:foo)
          Console.log_level :foo
        end
      end

      context "without a value" do
        it "should return the current level as a symbol" do
          Adhearsion::Logging.level = :fatal
          expect(Console.log_level).to eq(:fatal)
        end
      end
    end

    describe "#silence!" do
      it "should delegate to Adhearsion::Logging" do
        expect(Adhearsion::Logging).to receive(:silence!).once
        Console.silence!
      end
    end

    describe "#unsilence!" do
      it "should delegate to Adhearsion::Logging" do
        expect(Adhearsion::Logging).to receive(:unsilence!).once
        Console.unsilence!
      end
    end

    describe "#shutdown!" do
      it "should tell the process to shutdown" do
        expect(Adhearsion::Process).to receive(:shutdown!).once
        Console.shutdown!
      end
    end

    describe "#originate" do
      it "should be an alias for Adhearsion::OutboundCall.originate" do
        foo = nil
        expect(Adhearsion::OutboundCall).to receive(:originate).once.with(:foo, :bar).and_yield
        Console.originate(:foo, :bar) { foo = :bar}
        expect(foo).to eq(:bar)
      end
    end

    describe "#take" do
      let(:call)    { Call.new }
      let(:call_id) { rand.to_s }

      before do
        Adhearsion.active_calls.clear
        call.stub(:id => call_id)
      end

      context "with a call" do
        it "should interact with the call" do
          expect(Console.instance).to receive(:interact_with_call).once.with call
          Console.take call
        end
      end

      context "with no argument" do
        context "with one currently active call" do
          before do
            Adhearsion.active_calls << call
          end

          it "should interact with the current call" do
            expect(Console.instance).to receive(:interact_with_call).once.with call
            Console.take
          end
        end

        context "with multiple current calls" do
          let(:call2) { Call.new }

          before do
            call2.stub :id => rand.to_s
            Adhearsion.active_calls << call << call2
          end

          it "should allow selection of the call to use" do
            mock_io = StringIO.new
            Console.input = mock_io
            expect(mock_io).to receive(:gets).once.and_return "1\n"
            expect(Console.instance).to receive(:interact_with_call).once.with call2
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
            expect(Console.instance).to receive(:interact_with_call).once.with call
            Console.take call_id
          end
        end

        context "if an active call with that ID does not exist" do
          it "should log an error explaining that the call does not exist" do
            expect(Console.logger).to receive(:error).once.with(/does not exist/)
            expect(Console.instance).to receive(:interact_with_call).never
            Console.take call_id
          end
        end
      end
    end

    describe "#interact_with_call" do
      let(:call) { Call.new }

      it "should pause the call's controllers, and unpause even if the interactive controller raises" do
        expect(call).to receive(:pause_controllers).once.ordered
        expect(CallController).to receive(:exec).once.ordered.and_raise StandardError
        expect(call).to receive(:resume_controllers).once.ordered
        expect { Console.interact_with_call call }.to raise_error StandardError
      end

      it "should execute an interactive call controller on the call" do
        expect(CallController).to receive(:exec).once do |c|
          expect(c).to be_a Console::InteractiveController
          expect(c.call).to be call
        end
        Console.interact_with_call call
      end
    end
  end
end
