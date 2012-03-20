# encoding: utf-8

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

        it "raises an exception if called without a CallController and no block" do
          expect { subject.match 1 }.to raise_error(ArgumentError)
        end

        it "raises an exception if given both a payload and a block" do
          expect { subject.match(1, Object) {} }.to raise_error(ArgumentError)
        end

        it "raises an exception if given no patterns" do
          expect { subject.match() {} }.to raise_error(ArgumentError, "You cannot call this method without patterns.")
        end

        it "creates a pattern based on a payload" do
          flexmock(MenuDSL::MatchCalculator).should_receive(:build_with_pattern).with("1", Object)
          subject.match "1", Object
        end

        it "creates a pattern based on a block" do
          flexmock(MenuDSL::MatchCalculator).should_receive(:build_with_pattern).with("1", nil, match_block)
          subject.match("1", &match_block)
        end

        it "creates multiple patterns if multiple arguments are passed in" do
          flexmock(MenuDSL::MatchCalculator).should_receive(:build_with_pattern).with(1, Object)
          flexmock(MenuDSL::MatchCalculator).should_receive(:build_with_pattern).with(2, Object)
          subject.match(1, 2, Object)
        end
      end#match

      describe "#has_matchers?" do
        context "with no matchers specified" do
          its(:has_matchers?) { should be false }
        end

        context "with at least one matcher specified" do
          before do
            subject.match(1) {}
          end

          its(:has_matchers?) { should be true }
        end
      end

      describe "#weighted_match_calculators" do
        let(:expected_pattern) { MenuDSL::MatchCalculator.build_with_pattern("1", Object) }

        it "returns the generated patterns" do
          flexmock(MenuDSL::MatchCalculator).should_receive(:build_with_pattern).with("1", Object).and_return(expected_pattern)
          subject.match("1", Object)
          subject.weighted_match_calculators.should be == [expected_pattern]
        end
      end#weighted_match_calculators

      describe "#invalid" do
        let(:callback) { Proc.new() {} }

        it "raises an error if not passed a block" do
          expect { subject.invalid }.to raise_error(LocalJumpError)
        end

        it "sets the invalid callback" do
          subject.invalid(&callback)
          subject.menu_callbacks[:invalid].should be == callback
        end
      end#invalid

      describe "#timeout" do
        let(:callback) { Proc.new() {} }

        it "raises an error if not passed a block" do
          expect { subject.timeout }.to raise_error(LocalJumpError)
        end

        it "sets the timeout callback" do
          subject.timeout(&callback)
          subject.menu_callbacks[:timeout].should be == callback
        end
      end#timeout

      describe "#failure" do
        let(:callback) { Proc.new() {} }

        it "raises an error if not passed a block" do
          expect { subject.failure }.to raise_error(LocalJumpError)
        end

        it "sets the failure callback" do
          subject.failure(&callback)
          subject.menu_callbacks[:failure].should be == callback
        end
      end#failure

      describe "#validator" do
        let(:callback) { Proc.new() {} }

        it "raises an error if not passed a block" do
          expect { subject.validator }.to raise_error(LocalJumpError)
        end

        it "sets the invalid callback" do
          subject.validator(&callback)
          subject.menu_callbacks[:validator].should be == callback
        end
      end#invalid

      describe "#execute_hook_for" do
        it "executes the correct hook" do
          bar = nil
          subject.invalid do |baz|
            bar = baz
          end
          subject.execute_hook_for(:invalid, "1")
          bar.should be == "1"
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
