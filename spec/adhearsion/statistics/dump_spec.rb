# encoding: utf-8

require 'spec_helper'

describe Adhearsion::Statistics::Dump do
  it "should have a timestamp" do
    origin_time = Time.now
    dump = Adhearsion::Statistics::Dump.new timestamp: origin_time
    dump.timestamp.should == origin_time
  end

  it "should have a hash of call counts" do
    counts = {dialed: 0, offered: 0, routed: 0, rejected: 0, active: 0}
    dump = Adhearsion::Statistics::Dump.new call_counts: counts
    dump.call_counts.should == counts
  end

  it "should have a hash of call counts by route" do
    counts = {"my route" => 1, "your route" => 10}
    dump = Adhearsion::Statistics::Dump.new calls_by_route: counts
    dump.calls_by_route.should == counts
  end

  it "should be equal to another dump if they share the same timestamp" do
    origin_time = Time.now
    dump1 = Adhearsion::Statistics::Dump.new timestamp: origin_time
    dump2 = Adhearsion::Statistics::Dump.new timestamp: origin_time
    dump1.should be == dump2
  end

  it "should compare based on the timestamp" do
    origin_time = Time.now
    dump1 = Adhearsion::Statistics::Dump.new timestamp: origin_time
    dump2 = Adhearsion::Statistics::Dump.new timestamp: (origin_time + 1)
    dump1.should be < dump2
    dump2.should be > dump1
  end
end
