# encoding: utf-8

require 'spec_helper'

describe Adhearsion::Rayo::Command::Unmute do
  it 'registers itself' do
    expect(Adhearsion::Rayo::RayoNode.class_from_registration(:unmute, 'urn:xmpp:rayo:1')).to eq(described_class)
  end

  describe "from a stanza" do
    let(:stanza) { '<unmute xmlns="urn:xmpp:rayo:1"/>' }

    subject { Adhearsion::Rayo::RayoNode.from_xml parse_stanza(stanza).root, '9f00061', '1' }

    it { is_expected.to be_instance_of described_class }
  end

  describe "exporting to Rayo" do
    it "should export to XML that can be understood by its parser" do
      new_instance = Adhearsion::Rayo::RayoNode.from_xml subject.to_rayo
      expect(new_instance).to be_instance_of described_class
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
