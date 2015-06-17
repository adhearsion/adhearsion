# encoding: utf-8

require 'spec_helper'

describe Adhearsion::Rayo::Command::Redirect do
  it 'registers itself' do
    expect(Adhearsion::Rayo::RayoNode.class_from_registration(:redirect, 'urn:xmpp:rayo:1')).to eq(described_class)
  end

  describe "when setting options in initializer" do
    subject { described_class.new to: 'tel:+14045551234', headers: { 'X-skill' => 'agent', 'X-customer-id' => '8877' } }

    describe '#to' do
      subject { super().to }
      it { is_expected.to eq('tel:+14045551234') }
    end

    describe '#headers' do
      subject { super().headers }
      it { is_expected.to eq({ 'X-skill' => 'agent', 'X-customer-id' => '8877' }) }
    end

    describe "exporting to Rayo" do
      it "should export to XML that can be understood by its parser" do
        new_instance = Adhearsion::Rayo::RayoNode.from_xml subject.to_rayo
        expect(new_instance).to be_instance_of described_class
        expect(new_instance.to).to eq('tel:+14045551234')
        expect(new_instance.headers).to eq({ 'X-skill' => 'agent', 'X-customer-id' => '8877' })
      end

      it "should render to a parent node if supplied" do
        doc = Nokogiri::XML::Document.new
        parent = Nokogiri::XML::Node.new 'foo', doc
        doc.root = parent
        rayo_doc = subject.to_rayo(parent)
        expect(rayo_doc).to eq(parent)
      end

      context "when attributes are not set" do
        subject { described_class.new }

        it "should not include them in the XML representation" do
          expect(subject.to_rayo['to']).to be_nil
        end
      end
    end
  end

  describe "from a stanza" do
    let :stanza do
      <<-MESSAGE
<redirect xmlns='urn:xmpp:rayo:1'
    to='tel:+14045551234'>
  <!-- Signaling (e.g. SIP) Headers -->
  <header name="X-skill" value="agent" />
  <header name="X-customer-id" value="8877" />
</redirect>
      MESSAGE
    end

    subject { Adhearsion::Rayo::RayoNode.from_xml parse_stanza(stanza).root, '9f00061', '1' }

    it { is_expected.to be_instance_of described_class }

    describe '#to' do
      subject { super().to }
      it { is_expected.to eq('tel:+14045551234') }
    end

    describe '#headers' do
      subject { super().headers }
      it { is_expected.to eq({ 'X-skill' => 'agent', 'X-customer-id' => '8877' }) }
    end

    context "with no headers or to provided" do
      let(:stanza) { '<redirect xmlns="urn:xmpp:rayo:1"/>' }

      describe '#to' do
        subject { super().to }
        it { is_expected.to be_nil }
      end

      describe '#headers' do
        subject { super().headers }
        it { is_expected.to eq({}) }
      end
    end
  end
end
