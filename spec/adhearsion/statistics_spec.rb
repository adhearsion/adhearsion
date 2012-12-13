# encoding: utf-8

require 'spec_helper'

describe Adhearsion::Statistics do
  before { flexmock(Adhearsion.active_calls).should_receive(:count).and_return 0 }

  describe "#dump" do
    it "should report 0 calls offered, routed, rejected, active & completed" do
      subject.dump.call_counts.should == {dialed: 0, offered: 0, routed: 0, rejected: 0, active: 0}
    end
  end

  it "should allow incrementing the dialed call count" do
    subject.register_call_dialed
    subject.dump.call_counts.should == {dialed: 1, offered: 0, routed: 0, rejected: 0, active: 0}
  end

  it "should allow incrementing the offered call count" do
    subject.register_call_offered
    subject.dump.call_counts.should == {dialed: 0, offered: 1, routed: 0, rejected: 0, active: 0}
  end

  it "should allow incrementing the routed call count" do
    subject.register_call_routed
    subject.dump.call_counts.should == {dialed: 0, offered: 0, routed: 1, rejected: 0, active: 0}
  end

  it "should allow incrementing the rejected call count" do
    subject.register_call_rejected
    subject.dump.call_counts.should == {dialed: 0, offered: 0, routed: 0, rejected: 1, active: 0}
  end
end
