# encoding: utf-8

require 'spec_helper'

describe Adhearsion::Event::DTMF do
  it 'registers itself' do
    expect(Adhearsion::Rayo::RayoNode.class_from_registration(:dtmf, 'urn:xmpp:rayo:1')).to eq(described_class)
  end

  describe "from a stanza" do
    let(:stanza) { "<dtmf xmlns='urn:xmpp:rayo:1' signal='#' />" }

    subject { Adhearsion::Rayo::RayoNode.from_xml parse_stanza(stanza).root, '9f00061', '1' }

    it { is_expected.to be_instance_of described_class }

    it_should_behave_like 'event'

    describe '#signal' do
      subject { super().signal }
      it { is_expected.to eq('#') }
    end
  end

  describe "when setting options in initializer" do
    subject do
      described_class.new :signal => '#'
    end

    describe '#signal' do
      subject { super().signal }
      it { is_expected.to eq('#') }
    end
  end
end
