# encoding: utf-8

require 'spec_helper'

describe Adhearsion::Event::StoppedSpeaking do
  it 'registers itself' do
    expect(Adhearsion::Rayo::RayoNode.class_from_registration(:'stopped-speaking', 'urn:xmpp:rayo:1')).to eq(described_class)
  end

  describe "from a stanza" do
    let :stanza do
      '<stopped-speaking xmlns="urn:xmpp:rayo:1" call-id="x0yz4ye-lx7-6ai9njwvw8nsb"/>'
    end

    subject { Adhearsion::Rayo::RayoNode.from_xml parse_stanza(stanza).root, '9f00061', '1' }

    it { is_expected.to be_instance_of described_class }

    it_should_behave_like 'event'

    describe '#call_id' do
      subject { super().call_id }
      it { is_expected.to eq("x0yz4ye-lx7-6ai9njwvw8nsb") }
    end
  end

  describe "when setting options in initializer" do
    subject do
      described_class.new :call_id => 'abc123'
    end

    describe '#call_id' do
      subject { super().call_id }
      it { is_expected.to eq('abc123') }
    end
  end
end
