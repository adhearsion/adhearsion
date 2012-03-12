# encoding: utf-8

require 'spec_helper'

module Adhearsion
  module MenuDSL
    describe MatchCalculator do
      describe ".build_with_pattern" do
        it "should return an appropriate subclass instance based on the pattern's class" do
          MatchCalculator.build_with_pattern(1..2, :main).should be_an_instance_of RangeMatchCalculator
        end
      end
    end
  end
end
