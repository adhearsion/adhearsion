# encoding: utf-8

require 'spec_helper'

describe Adhearsion::Rayo::Command::Accept do
  it 'registers itself' do
    expect(Adhearsion::Rayo::RayoNode.class_from_registration(:accept, 'urn:xmpp:rayo:1')).to eq(described_class)
  end

  describe "from a stanza" do
    let(:stanza) do
      <<-STANZA
        <accept xmlns="urn:xmpp:rayo:1">
          <header name="X-skill" value="agent" />
          <header name="X-customer-id" value="8877" />
        </accept>
      STANZA
    end

    subject { Adhearsion::Rayo::RayoNode.from_xml parse_stanza(stanza).root, '9f00061', '1' }

    it { is_expected.to be_instance_of described_class }

    describe '#headers' do
      subject { super().headers }
      it { is_expected.to eq({ 'X-skill' => 'agent', 'X-customer-id' => '8877' }) }
    end

    context "with no headers provided" do
      let(:stanza) { '<accept xmlns="urn:xmpp:rayo:1"/>' }

      describe '#headers' do
        subject { super().headers }
        it { is_expected.to eq({}) }
      end
    end
  end

  describe "when setting options in initializer" do
    subject { described_class.new headers: { 'X-skill' => 'agent', 'X-customer-id' => '8877' } }

    describe '#headers' do
      subject { super().headers }
      it { is_expected.to eq({ 'X-skill' => 'agent', 'X-customer-id' => '8877' }) }
    end

    describe "exporting to Rayo" do
      it "should export to XML that can be understood by its parser" do
        new_instance = Adhearsion::Rayo::RayoNode.from_xml subject.to_rayo
        expect(new_instance).to be_instance_of described_class
        expect(new_instance.headers).to eq({ 'X-skill' => 'agent', 'X-customer-id' => '8877' })
      end

      it "should render to a parent node if supplied" do
        doc = Nokogiri::XML::Document.new
        parent = Nokogiri::XML::Node.new 'foo', doc
        doc.root = parent
        rayo_doc = subject.to_rayo(parent)
        expect(rayo_doc).to eq(parent)
      end
    end
  end
end
