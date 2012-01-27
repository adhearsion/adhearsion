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
  end
end