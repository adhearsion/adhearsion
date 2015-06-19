# encoding: utf-8

require 'spec_helper'

describe Adhearsion::URIList do
  describe '#size' do
    subject { super().size }
    it { is_expected.to eq(0) }
  end

  context "created with a set of entries" do
    subject { described_class.new 'http://example.com/hello.mp3', 'http://example.com/goodbye.mp3' }

    describe '#size' do
      subject { super().size }
      it { is_expected.to eq(2) }
    end

    describe '#to_ary' do
      subject { super().to_ary }
      it { is_expected.to eq(['http://example.com/hello.mp3', 'http://example.com/goodbye.mp3']) }
    end

    describe '#to_s' do
      subject { super().to_s }
      it { is_expected.to eq("http://example.com/hello.mp3\nhttp://example.com/goodbye.mp3") }
    end
  end

  context "created with an array of entries" do
    subject { described_class.new ['http://example.com/hello.mp3', 'http://example.com/goodbye.mp3'] }

    describe '#size' do
      subject { super().size }
      it { is_expected.to eq(2) }
    end

    describe '#to_ary' do
      subject { super().to_ary }
      it { is_expected.to eq(['http://example.com/hello.mp3', 'http://example.com/goodbye.mp3']) }
    end

    describe '#to_s' do
      subject { super().to_s }
      it { is_expected.to eq("http://example.com/hello.mp3\nhttp://example.com/goodbye.mp3") }
    end
  end

  context "imported from a string" do
    let(:string) do
      <<-STRING
      http://example.com/hello.mp3
      http://example.com/goodbye.mp3
      STRING
    end

    subject { described_class.import string }

    describe '#size' do
      subject { super().size }
      it { is_expected.to eq(2) }
    end

    describe '#to_ary' do
      subject { super().to_ary }
      it { is_expected.to eq(['http://example.com/hello.mp3', 'http://example.com/goodbye.mp3']) }
    end

    describe '#to_s' do
      subject { super().to_s }
      it { is_expected.to eq("http://example.com/hello.mp3\nhttp://example.com/goodbye.mp3") }
    end
  end

  describe "comparisons" do
    context "when the elements are the same" do
      it "resolves equal" do
        expect(described_class.new('foo', 'bar')).to eq(described_class.new('foo', 'bar'))
      end
    end

    context "when the elements are different" do
      it "does not resolve equal" do
        expect(described_class.new('foo', 'baz')).not_to eq(described_class.new('bar', 'baz'))
      end
    end
  end
end
