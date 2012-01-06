require 'spec_helper'

module Adhearsion
  module MenuDSL

    describe MenuBuilder do
      subject{ MenuDSL::MenuBuilder.new } 

      describe "#build" do
        it "sets the context and instance_eval's the block" do
          flexmock(subject).should_receive(:foo).with(:bar)
          subject.build do
            foo :bar
          end
        end
      end#build

      describe "#match" do
        let(:match_block) { Proc.new() {} }
        it "raises an exception if called with one argument and no block" do
          expect { subject.match 1 }.to raise_error(ArgumentError)
        end

        it "raises an exception if given both a payload and a block" do
          expect { subject.match(1, Object) {} }.to raise_error(ArgumentError) 
        end

        it "raises an exception if given no patterns" do
          expect { subject.match([]) {} }.to raise_error(ArgumentError, "You cannot call this method without patterns.")
        end

        it "creates a pattern based on a payload" do
          flexmock(MenuDSL::MatchCalculator).should_receive(:build_with_pattern).with("1", Object)
          subject.match "1", Object
        end

        it "creates a pattern based on a block" do
          flexmock(MenuDSL::MatchCalculator).should_receive(:build_with_pattern).with("1", nil, match_block)
          subject.match("1", &match_block)
        end
      end#match

      describe "#weighted_match_calculators" do
        let(:expected_pattern) { MenuDSL::MatchCalculator.build_with_pattern("1", Object) }
        
        it "returns the generated patterns" do
          flexmock(MenuDSL::MatchCalculator).should_receive(:build_with_pattern).with("1", Object).and_return(expected_pattern)
          subject.match("1", Object)
          subject.weighted_match_calculators.should == [expected_pattern]
        end
      end#weighted_match_calculators

      describe "#invalid" do
        let(:callback) { Proc.new() {} }

        it "raises an error if not passed a block" do
          expect { subject.invalid }.to raise_error(LocalJumpError) 
        end

        it "sets the invalid callback" do
          subject.invalid(&callback)
          subject.menu_callbacks[:invalid].should == callback
        end
      end#invalid

      describe "#timeout" do
        let(:callback) { Proc.new() {} }

        it "raises an error if not passed a block" do
          expect { subject.timeout }.to raise_error(LocalJumpError) 
        end

        it "sets the timeout callback" do
          subject.timeout(&callback)
          subject.menu_callbacks[:timeout].should == callback
        end
      end#timeout

      describe "#failure" do
        let(:callback) { Proc.new() {} }

        it "raises an error if not passed a block" do
          expect { subject.failure }.to raise_error(LocalJumpError) 
        end

        it "sets the failure callback" do
          subject.failure(&callback)
          subject.menu_callbacks[:failure].should == callback
        end
      end#failure

      describe "#execute_hook_for" do
        it "executes the correct hook" do
          bar = nil
          subject.invalid do |baz|
            bar = baz
          end
          subject.execute_hook_for(:invalid, "1")
          bar.should == "1"
        end
      end#execute_hook_for

      describe "#calculate_matches_for" do
        it "returns a calculated match collection" do
          subject.match("1", Object)
          subject.calculate_matches_for("1").should be_a CalculatedMatchCollection
        end
      end

    end# describe MenuBuilder

  end# module MenuDSL
end
