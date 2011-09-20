require 'spec_helper'

module Adhearsion
  module Punchblock
    module Menu

      describe CalculatedMatchCollection do
        include PunchblockCommandTestHelpers

        attr_reader :collection
        before(:each) do
          @collection = Adhearsion::Punchblock::Menu::CalculatedMatchCollection.new
        end

        it "the <<() method should collect the potential matches into the actual_potential_matches Array" do
          mock_matches_array_1 = [:foo, :bar, :qaz],
          mock_matches_array_2 = [10, 20, 30]
          mock_matches_1 = mock_with_potential_matches mock_matches_array_1
          mock_matches_2 = mock_with_potential_matches mock_matches_array_2

          collection << mock_matches_1
          collection.actual_potential_matches.should == mock_matches_array_1

          collection << mock_matches_2
          collection.actual_potential_matches.should == mock_matches_array_1 + mock_matches_array_2
        end

        it "the <<() method should collect the exact matches into the actual_exact_matches Array" do
          mock_matches_array_1 = [:blam, :blargh],
          mock_matches_array_2 = [5,4,3,2,1]
          mock_matches_1 = mock_with_exact_matches mock_matches_array_1
          mock_matches_2 = mock_with_exact_matches mock_matches_array_2

          collection << mock_matches_1
          collection.actual_exact_matches.should == mock_matches_array_1

          collection << mock_matches_2
          collection.actual_exact_matches.should == mock_matches_array_1 + mock_matches_array_2
        end

        it "if any exact matches exist, the exact_match?() method should return true" do
          collection << mock_with_exact_matches([1,2,3])
          collection.exact_match?.should be true
        end

        it "if any potential matches exist, the potential_match?() method should return true" do
          collection << mock_with_potential_matches([1,2,3])
          collection.potential_match?.should be true
        end

      end
    end
  end
end
