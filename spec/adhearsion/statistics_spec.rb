# encoding: utf-8

require 'spec_helper'

describe Adhearsion::Statistics do
  subject { Celluloid::Actor[:statistics] }

  before do
    Celluloid::Actor[:statistics] = described_class.new
    Adhearsion::Statistics.setup_event_handlers
    allow(Adhearsion.active_calls).to receive_messages count: 0
  end

  after do
    Celluloid::Actor.clear_registry
    Adhearsion.router = nil
  end

  describe "#dump" do
    it "should report 0 calls offered, routed, rejected, active & completed" do
      expect(subject.dump.call_counts).to eq({dialed: 0, offered: 0, routed: 0, rejected: 0, active: 0})
    end

    it "should report 0 calls for each route in the router" do
      expect(subject.dump.calls_by_route).to eq({})
      Adhearsion.router.route 'your route', Adhearsion::CallController
      Adhearsion.router.route 'my route', Adhearsion::CallController
      expect(subject.dump.calls_by_route).to eq({'your route' => 0, 'my route' => 0})
    end
  end

  it "should listen for dialed call events and increment the dialed call count" do
    Adhearsion::Events.trigger_immediately :call_dialed, :foo_call
    expect(subject.dump.call_counts).to eq({dialed: 1, offered: 0, routed: 0, rejected: 0, active: 0})
  end

  it "should listen for call offer events and increment the offered call count" do
    Adhearsion::Events.trigger_immediately :rayo, Adhearsion::Event::Offer.new
    expect(subject.dump.call_counts).to eq({dialed: 0, offered: 1, routed: 0, rejected: 0, active: 0})
  end

  context "when call_routed events are triggered" do
    let(:route) { Adhearsion::Router::Route.new('my route') }

    before do
      Adhearsion.router.route 'your route', Adhearsion::CallController
      Adhearsion.router.route 'my route', Adhearsion::CallController

      Adhearsion::Events.trigger_immediately :call_routed, call: :foo, route: route
    end

    it "should increment the routed call count" do
      expect(subject.dump.call_counts).to eq({dialed: 0, offered: 0, routed: 1, rejected: 0, active: 0})
    end

    it "should increment the calls_by_route counter for the route matched" do
      expect(subject.dump.calls_by_route).to eq({'your route' => 0, 'my route' => 1})
    end
  end

  it "should listen for rejected call events and increment the rejected call count" do
    Adhearsion::Events.trigger_immediately :call_rejected, call: :foo, reason: :bar
    expect(subject.dump.call_counts).to eq({dialed: 0, offered: 0, routed: 0, rejected: 1, active: 0})
  end
end
