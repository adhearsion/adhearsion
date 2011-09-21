require 'spec_helper'

module Adhearsion
  module Punchblock
    module Menu

      describe "MatchCalculator" do
        include PunchblockCommandTestHelpers

        it "the build_with_pattern() method should return an appropriate subclass instance based on the pattern's class" do
          MatchCalculator.build_with_pattern(1..2, :main).should be_an_instance_of RangeMatchCalculator
        end

      end

    end
  end
end
