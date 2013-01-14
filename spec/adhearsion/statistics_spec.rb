# encoding: utf-8

require 'spec_helper'

describe Adhearsion::Statistics do
  before(:all) do
    Adhearsion::Statistics.setup_event_handlers
  end

  subject { Celluloid::Actor[:statistics] }

  before do
    Celluloid::Actor[:statistics] = described_class.new
    flexmock(Adhearsion.active_calls).should_receive(:count).and_return 0
  end

  after do
    Celluloid::Actor.clear_registry
    Adhearsion.router = nil
  end

  describe "#dump" do
    it "should report 0 calls offered, routed, rejected, active & completed" do
      subject.dump.call_counts.should == {dialed: 0, offered: 0, routed: 0, rejected: 0, active: 0}
    end

    it "should report 0 calls for each route in the router" do
      subject.dump.calls_by_route.should == {}
      Adhearsion.router.route 'your route', Adhearsion::CallController
      Adhearsion.router.route 'my route', Adhearsion::CallController
      subject.dump.calls_by_route.should == {'your route' => 0, 'my route' => 0}
    end
  end

  it "should listen for dialed call events and increment the dialed call count" do
    Adhearsion::Events.trigger_immediately :call_dialed, :foo_call
    subject.dump.call_counts.should == {dialed: 1, offered: 0, routed: 0, rejected: 0, active: 0}
  end

  it "should listen for call offer events and increment the offered call count" do
    Adhearsion::Events.trigger_immediately :punchblock, Punchblock::Event::Offer.new
    subject.dump.call_counts.should == {dialed: 0, offered: 1, routed: 0, rejected: 0, active: 0}
  end

  context "when call_routed events are triggered" do
    let(:route) { Adhearsion::Router::Route.new('my route') }

    before do
      Adhearsion.router.route 'your route', Adhearsion::CallController
      Adhearsion.router.route 'my route', Adhearsion::CallController

      Adhearsion::Events.trigger_immediately :call_routed, call: :foo, route: route
    end

    it "should increment the routed call count" do
      subject.dump.call_counts.should == {dialed: 0, offered: 0, routed: 1, rejected: 0, active: 0}
    end

    it "should increment the calls_by_route counter for the route matched" do
      subject.dump.calls_by_route.should == {'your route' => 0, 'my route' => 1}
    end
  end

  it "should listen for rejected call events and increment the rejected call count" do
    Adhearsion::Events.trigger_immediately :call_rejected, call: :foo, reason: :bar
    subject.dump.call_counts.should == {dialed: 0, offered: 0, routed: 0, rejected: 1, active: 0}
  end
end
