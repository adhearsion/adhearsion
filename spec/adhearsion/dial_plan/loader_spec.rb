require 'spec_helper'

describe "DialPlan loader" do
  include DialplanTestingHelper

  it '::build should raise a SyntaxError when the dialplan String contains one' do
    the_following_code {
      Adhearsion::DialPlan::Loader.load "foo { ((((( *@!^*@&*^!^@ }"
    }.should raise_error SyntaxError
  end

  it "loading a single context" do
    loader = load(<<-DIAL_PLAN)
      one {
        raise 'this block should not be evaluated'
      }
    DIAL_PLAN

    loader.contexts.keys.size.should be 1
    loader.contexts.keys.first.should be :one
  end

  it "loading multiple contexts loads all contexts" do
    loader = load(<<-DIAL_PLAN)
      one {
        raise 'this block should not be evaluated'
      }

      two {
        raise 'this other block should not be evaluated either'
      }
    DIAL_PLAN

    loader.contexts.keys.size.should be 2
    loader.contexts.keys.map(&:to_s).sort.should == %w(one two)
  end

  it 'loading a dialplan with a syntax error' do
    the_following_code {
      load "foo { &@(*!&(*@*!@^!^%@%^! }"
    }.should raise_error SyntaxError
  end

  it "loading a dial plan from a file" do
    loader = nil
    the_following_code {
      loader = Adhearsion::DialPlan::Loader.load_dialplans
    }.should_not raise_error

    loader.contexts.keys.size.should be 1
    loader.contexts.keys.first.should be :sample_context
  end

end
