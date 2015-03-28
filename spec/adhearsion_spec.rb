# encoding: utf-8

require 'spec_helper'

describe Adhearsion do
  describe "#root=" do
    it "should update properly the config root variable" do
      Adhearsion.root = "./"
      expect(Adhearsion.config[:platform].root).to eq(Dir.getwd)
    end

    it "should update properly the config root variable when path is nil" do
      Adhearsion.root = nil
      expect(Adhearsion.config[:platform].root).to be_nil
    end
  end

  describe "#root" do
    it "should return the set root" do
      Adhearsion.root = "./"
      expect(Adhearsion.root).to eq(Dir.getwd)
    end
  end

  describe "#ahn_root=" do
    it "should update properly the config root variable" do
      Adhearsion.ahn_root = "./"
      expect(Adhearsion.config[:platform].root).to eq(Dir.getwd)
    end

    it "should update properly the config root variable when path is nil" do
      Adhearsion.ahn_root = nil
      expect(Adhearsion.config[:platform].root).to be_nil
    end
  end

  describe "#config" do
    it "should return a Configuration instance" do
      expect(subject.config).to be_instance_of Adhearsion::Configuration
    end

    it "should execute a block" do
      foo = Object.new
      expect(foo).to receive(:bar).once
      Adhearsion.config do |config|
        foo.bar
      end
    end
  end

  describe "#environments" do
    it "should be the collection of valid environments" do
      Adhearsion.config.valid_environments << :foo
      expect(Adhearsion.environments).to include :foo
    end
  end

  describe "#environment" do
    let(:env) { "foo" }

    before do
      Adhearsion.config{ |conf| conf.platform.environment = nil}
      ENV['AHN_PLATFORM_ENVIRONMENT'] = env
    end

    it "should be the collection of valid environments" do
      Adhearsion.config.platform.environment.should eq env.to_sym
    end
  end

  describe "#router" do
    describe '#router' do
      subject { super().router }
      it { is_expected.to be_a Adhearsion::Router }
    end

    it "should always use the same router" do
      expect(Adhearsion.router).to be Adhearsion.router
    end

    it "should pass a block along to the router" do
      foo = nil
      Adhearsion.router do
        foo = self
      end

      expect(foo).to be Adhearsion.router
    end
  end

  describe "#active_calls" do
    it "should be a calls collection" do
      expect(Adhearsion.active_calls).to be_a Adhearsion::Calls
    end

    it "should return the same instance each time" do
      expect(Adhearsion.active_calls).to be Adhearsion.active_calls
    end
  end

  describe "#statistics" do
    it "should be a statistics aggregator" do
      expect(Adhearsion.statistics).to be_a Adhearsion::Statistics
    end

    it "should return the same instance each time" do
      expect(Adhearsion.statistics).to be Adhearsion.statistics
    end

    it "should create a new aggregator if the existing one dies" do
      original = Adhearsion.statistics
      original.terminate
      expect(original.alive?).to be false

      sleep 0.25

      current = Adhearsion.statistics
      expect(current).to be_alive
      expect(current).not_to be original
    end
  end

  describe "#status" do
    it "should be the process status name" do
      expect(Adhearsion.status).to eq(:booting)
    end
  end

  it "should have an encoding on all files" do
    Dir['{bin,features,lib,spec}/**/*.rb'].each do |filename|
      File.open filename do |file|
        first_line = file.first
        expect(first_line).to eq("# encoding: utf-8\n")
      end
    end
  end
end
