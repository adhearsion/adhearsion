# encoding: utf-8

require 'spec_helper'

describe Adhearsion::Statistics do
  before { flexmock(Adhearsion.active_calls).should_receive(:count).and_return 0 }

  describe "#dump" do
    it "should report 0 calls offered, routed, rejected, active & completed" do
      subject.dump.call_counts.should == {dialed: 0, offered: 0, routed: 0, rejected: 0, active: 0}
    end
  end

  it "should listen for dialed call events and increment the dialed call count" do
    subject
    Adhearsion::Events.trigger_immediately :call_dialed, :foo_call
    subject.dump.call_counts.should == {dialed: 1, offered: 0, routed: 0, rejected: 0, active: 0}
  end

  it "should listen for call offer events and increment the offered call count" do
    subject
    Adhearsion::Events.trigger_immediately :punchblock, Punchblock::Event::Offer.new
    subject.dump.call_counts.should == {dialed: 0, offered: 1, routed: 0, rejected: 0, active: 0}
  end

  it "should listen for routed call events and increment the routed call count" do
    subject
    Adhearsion::Events.trigger_immediately :call_routed, call: :foo, route: Adhearsion::Router::Route.new('my_route')
    subject.dump.call_counts.should == {dialed: 0, offered: 0, routed: 1, rejected: 0, active: 0}
  end

  it "should listen for rejected call events and increment the rejected call count" do
    subject
    Adhearsion::Events.trigger_immediately :call_rejected, call: :foo, reason: :bar
    subject.dump.call_counts.should == {dialed: 0, offered: 0, routed: 0, rejected: 1, active: 0}
  end
end
