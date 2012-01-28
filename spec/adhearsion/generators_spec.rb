require 'spec_helper'
require 'adhearsion/generators'

describe Adhearsion::Generators do

  describe "#mappings" do
    it "returns an empty OrderedHash if there are no mappings" do
      mappings = Adhearsion::Generators.mappings
      mappings.should be_a ActiveSupport::OrderedHash
      mappings.empty?.should == true
    end
  end

  describe "#add_generator" do
    let(:generator_key) { "example_gen" }
    
    it "adds a generator to the mappings and returns it" do
      class DummyGenerator; end

      Adhearsion::Generators.add_generator(generator_key, DummyGenerator)
      Adhearsion::Generators.mappings[generator_key].should == DummyGenerator
    end
  end
end
