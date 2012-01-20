require 'spec_helper'

describe SynchronizedHash do
  describe "comparison with a Hash" do
    let(:hash) { {:foo => 'bar'} }

    context "with the same contents" do
      before do
        subject[:foo] = 'bar'
      end

      it { should == hash }
    end

    context "with different contents" do
      before do
        subject[:foo] = 'baz'
      end

      it { should_not == hash }
    end
  end

  describe "comparison with another SynchronizedHash" do
    let(:other) { SynchronizedHash.new }

    before do
      other[:foo] = 'bar'
    end

    context "with the same contents" do
      before do
        subject[:foo] = 'bar'
      end

      it { should == other }
    end

    context "with different contents" do
      before do
        subject[:foo] = 'baz'
      end

      it { should_not == other }
    end
  end
end
