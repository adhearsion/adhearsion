require 'spec_helper'

describe Adhearsion do
  subject {Adhearsion}

  describe "while accessing the config method" do
    it "should return a Configuration instance" do
      subject.config.should be_instance_of Adhearsion::Configuration
    end

    it "should execute a block" do
      foo = Object.new
      flexmock(foo).should_receive(:bar).once
      Adhearsion.config do |config|
        foo.bar
      end
    end
  end

  describe "while accessing the ahn_root= method" do
    it "should update properly the config root variable" do
      Adhearsion.ahn_root = "./"
      Adhearsion.config[:platform].root.should == Dir.getwd
    end

    it "should update properly the config root variable when path is nil" do
      Adhearsion.ahn_root = nil
      Adhearsion.config[:platform].root.should be_nil
    end
  end
end
