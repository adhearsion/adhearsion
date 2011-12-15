require 'spec_helper'

module Adhearsion
  describe DialplanController do
    include CallControllerTestHelpers

    it { should be_a DialplanController }
    it { should be_a CallController }

    let :dialplan do
      Proc.new { foo value }
    end

    before { subject.dialplan = dialplan }

    its(:dialplan) { should be dialplan }

    describe "running" do
      it "should execute the dialplan in the context of the controller" do
        flexmock subject, :value => :bar
        subject.should_receive(:foo).once.with(:bar)
        subject.run
      end
    end
  end
end
