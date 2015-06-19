# encoding: utf-8

require 'spec_helper'

describe Adhearsion::Event::End do
  it 'registers itself' do
    expect(Adhearsion::Rayo::RayoNode.class_from_registration(:end, 'urn:xmpp:rayo:1')).to eq(described_class)
  end

  describe "from a stanza" do
    let :stanza do
      <<-MESSAGE
<end xmlns="urn:xmpp:rayo:1">
  <timeout platform-code="18" />
  <!-- Signaling (e.g. SIP) Headers -->
  <header name="X-skill" value="agent" />
  <header name="X-customer-id" value="8877" />
</end>
      MESSAGE
    end

    subject { Adhearsion::Rayo::RayoNode.from_xml parse_stanza(stanza).root, '9f00061', '1' }

    it { is_expected.to be_instance_of described_class }

    it_should_behave_like 'event'

    describe '#reason' do
      subject { super().reason }
      it { is_expected.to eq(:timeout) }
    end

    describe '#platform_code' do
      subject { super().platform_code }
      it { is_expected.to eq('18') }
    end

    describe '#headers' do
      subject { super().headers }
      it { is_expected.to eq({ 'X-skill' => 'agent', 'X-customer-id' => '8877' }) }
    end

    context "with no headers or reason provided" do
      let(:stanza) { '<end xmlns="urn:xmpp:rayo:1"/>' }

      describe '#reason' do
        subject { super().reason }
        it { is_expected.to be_nil}
      end

      describe '#platform_code' do
        subject { super().platform_code }
        it { is_expected.to be_nil }
      end

      describe '#headers' do
        subject { super().headers }
        it { is_expected.to eq({}) }
      end
    end
  end

  describe "when setting options in initializer" do
    subject do
      described_class.new reason: :hangup,
                          platform_code: 18,
                          headers: { 'X-skill' => 'agent', 'X-customer-id' => '8877' }
    end

    describe '#reason' do
      subject { super().reason }
      it { is_expected.to eq(:hangup) }
    end

    describe '#platform_code' do
      subject { super().platform_code }
      it { is_expected.to eq('18') }
    end

    describe '#headers' do
      subject { super().headers }
      it { is_expected.to eq({ 'X-skill' => 'agent', 'X-customer-id' => '8877' }) }
    end
  end
end
