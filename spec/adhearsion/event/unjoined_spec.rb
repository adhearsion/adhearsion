# encoding: utf-8

require 'spec_helper'

describe Adhearsion::Event::Unjoined do
  it 'registers itself' do
    expect(Adhearsion::Rayo::RayoNode.class_from_registration(:unjoined, 'urn:xmpp:rayo:1')).to eq(described_class)
  end

  describe "from a stanza" do
    let(:stanza) { '<unjoined xmlns="urn:xmpp:rayo:1" call-uri="b" mixer-name="m" />' }

    subject { Adhearsion::Rayo::RayoNode.from_xml parse_stanza(stanza).root, '9f00061', '1' }

    it { is_expected.to be_instance_of described_class }

    it_should_behave_like 'event'

    describe '#call_uri' do
      subject { super().call_uri }
      it { is_expected.to eq('b') }
    end

    describe '#call_id' do
      subject { super().call_id }
      it { is_expected.to eq('b') }
    end

    describe '#mixer_name' do
      subject { super().mixer_name }
      it { is_expected.to eq('m') }
    end
  end

  describe "when setting options in initializer" do
    subject { described_class.new :call_uri => 'abc123', :mixer_name => 'blah' }

    describe '#call_id' do
      subject { super().call_id }
      it { is_expected.to eq('abc123') }
    end

    describe '#mixer_name' do
      subject { super().mixer_name }
      it { is_expected.to eq('blah') }
    end
  end
end
