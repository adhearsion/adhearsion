# encoding: utf-8

require 'spec_helper'

describe Adhearsion do
  describe "#root=" do
    it "should update properly the config root variable" do
      Adhearsion.root = "./"
      Adhearsion.config[:platform].root.should be == Dir.getwd
    end

    it "should update properly the config root variable when path is nil" do
      Adhearsion.root = nil
      Adhearsion.config[:platform].root.should be_nil
    end
  end

  describe "#root" do
    it "should return the set root" do
      Adhearsion.root = "./"
      Adhearsion.root.should be == Dir.getwd
    end
  end

  describe "#ahn_root=" do
    it "should update properly the config root variable" do
      Adhearsion.ahn_root = "./"
      Adhearsion.config[:platform].root.should be == Dir.getwd
    end

    it "should update properly the config root variable when path is nil" do
      Adhearsion.ahn_root = nil
      Adhearsion.config[:platform].root.should be_nil
    end
  end

  describe "#config" do
    it "should return a Configuration instance" do
      subject.config.should be_instance_of Adhearsion::Configuration
    end

    it "should execute a block" do
      foo = Object.new
      foo.should_receive(:bar).once
      Adhearsion.config do |config|
        foo.bar
      end
    end
  end

  describe "#router" do
    its(:router) { should be_a Adhearsion::Router }

    it "should always use the same router" do
      Adhearsion.router.should be Adhearsion.router
    end

    it "should pass a block along to the router" do
      foo = nil
      Adhearsion.router do
        foo = self
      end

      foo.should be Adhearsion.router
    end
  end

  describe "#active_calls" do
    it "should be a calls collection" do
      Adhearsion.active_calls.should be_a Adhearsion::Calls
    end

    it "should return the same instance each time" do
      Adhearsion.active_calls.should be Adhearsion.active_calls
    end
  end

  describe "#statistics" do
    it "should be a statistics aggregator" do
      Adhearsion.statistics.should be_a Adhearsion::Statistics
    end

    it "should return the same instance each time" do
      Adhearsion.statistics.should be Adhearsion.statistics
    end

    it "should create a new aggregator if the existing one dies" do
      original = Adhearsion.statistics
      original.terminate
      original.should_not be_alive

      sleep 0.25

      current = Adhearsion.statistics
      current.should be_alive
      current.should_not be original
    end
  end

  describe "#status" do
    it "should be the process status name" do
      Adhearsion.status.should be == :booting
    end
  end

  it "should have an encoding on all files" do
    Dir['{bin,features,lib,spec}/**/*.rb'].each do |filename|
      File.open filename do |file|
        first_line = file.first
        first_line.should == "# encoding: utf-8\n"
      end
    end
  end
end
