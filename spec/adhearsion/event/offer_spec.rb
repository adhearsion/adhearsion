# encoding: utf-8

require 'spec_helper'

describe Adhearsion::Event::Offer do
  it 'registers itself' do
    expect(Adhearsion::Rayo::RayoNode.class_from_registration(:offer, 'urn:xmpp:rayo:1')).to eq(described_class)
  end

  describe "from a stanza" do
    let :stanza do
      <<-MESSAGE
<offer xmlns='urn:xmpp:rayo:1'
    to='tel:+18003211212'
    from='tel:+13058881212'>
  <!-- Signaling (e.g. SIP) Headers -->
  <header name="X-skill" value="agent" />
  <header name="X-customer-id" value="8877" />
</offer>
      MESSAGE
    end

    subject { Adhearsion::Rayo::RayoNode.from_xml parse_stanza(stanza).root, '9f00061', '1' }

    it { is_expected.to be_instance_of described_class }

    it_should_behave_like 'event'

    describe '#to' do
      subject { super().to }
      it { is_expected.to eq('tel:+18003211212') }
    end

    describe '#from' do
      subject { super().from }
      it { is_expected.to eq('tel:+13058881212') }
    end

    describe '#headers' do
      subject { super().headers }
      it { is_expected.to eq({ 'X-skill' => 'agent', 'X-customer-id' => '8877' }) }
    end

    context "with no headers provided" do
      let(:stanza) { '<offer xmlns="urn:xmpp:rayo:1"/>' }

      describe '#headers' do
        subject { super().headers }
        it { is_expected.to eq({}) }
      end
    end

    context "with multiple headers of the same name" do
      let :stanza do
        <<-MESSAGE
<offer xmlns='urn:xmpp:rayo:1'
    to='tel:+18003211212'
    from='tel:+13058881212'>
  <!-- Signaling (e.g. SIP) Headers -->
  <header name="X-skill" value="sales" />
  <header name="X-skill" value="complaints" />
</offer>
        MESSAGE
      end

      describe '#headers' do
        subject { super().headers }
        it { is_expected.to eq({'X-skill' => ['sales', 'complaints']}) }
      end
    end
  end

  describe "when setting options in initializer" do
    subject do
      described_class.new to:      'tel:+18003211212',
                          from:    'tel:+13058881212',
                          headers: { 'X-skill' => 'agent', 'X-customer-id' => '8877' }
    end

    describe '#to' do
      subject { super().to }
      it { is_expected.to eq('tel:+18003211212') }
    end

    describe '#from' do
      subject { super().from }
      it { is_expected.to eq('tel:+13058881212') }
    end

    describe '#headers' do
      subject { super().headers }
      it { is_expected.to eq({ 'X-skill' => 'agent', 'X-customer-id' => '8877' }) }
    end

    context "with headers set to nil" do
      subject do
        described_class.new headers: nil
      end

      describe '#headers' do
        subject { super().headers }
        it { is_expected.to eq({}) }
      end
    end
  end
end
