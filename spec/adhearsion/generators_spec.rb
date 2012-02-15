require 'spec_helper'
require 'adhearsion/generators'

module Adhearsion
  describe Generators do
    describe "storing generator mappings" do
      let(:generator_key) { "example_gen" }

      it "adds a generator to the mappings and returns it" do
        DummyGenerator = Class.new

        Generators.add_generator generator_key, DummyGenerator
        Generators.mappings[generator_key].should == DummyGenerator
      end
    end
  end
end
