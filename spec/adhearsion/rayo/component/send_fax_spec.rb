# encoding: utf-8

require 'spec_helper'

describe Adhearsion::Rayo::Component::SendFax do
  it 'registers itself' do
    expect(Adhearsion::Rayo::RayoNode.class_from_registration(:sendfax, 'urn:xmpp:rayo:fax:1')).to eq(described_class)
  end

  subject do
    described_class.new render_documents: [Adhearsion::Rayo::Component::SendFax::FaxDocument.new(url: 'http://example.com/faxes/document.tiff', pages: [1..4,5,7..9])]
  end

  describe '#render_documents' do
    subject { super().render_documents }
    it { is_expected.to eq([Adhearsion::Rayo::Component::SendFax::FaxDocument.new(url: 'http://example.com/faxes/document.tiff', pages: [1..4,5,7..9])]) }
  end

  describe "exporting to Rayo" do
    it "should export to XML that can be understood by its parser" do
      new_instance = Adhearsion::Rayo::RayoNode.from_xml Nokogiri::XML(subject.to_rayo.to_xml, nil, nil, Nokogiri::XML::ParseOptions::NOBLANKS).root
      expect(new_instance.render_documents).to eq([Adhearsion::Rayo::Component::SendFax::FaxDocument.new(url: 'http://example.com/faxes/document.tiff', pages: [1..4,5,7..9])])
    end
  end

  context "without optional attributes" do
    subject do
      described_class.new render_documents: [Adhearsion::Rayo::Component::SendFax::FaxDocument.new(url: 'http://example.com/faxes/document.tiff')]
    end

    describe "exporting to Rayo" do
      it "should export to XML that can be understood by its parser" do
        new_instance = Adhearsion::Rayo::RayoNode.from_xml Nokogiri::XML(subject.to_rayo.to_xml, nil, nil, Nokogiri::XML::ParseOptions::NOBLANKS).root
        expect(new_instance.render_documents).to eq([Adhearsion::Rayo::Component::SendFax::FaxDocument.new(url: 'http://example.com/faxes/document.tiff')])
      end
    end
  end

  context "from a rayo stanza" do
    subject { Adhearsion::Rayo::RayoNode.from_xml parse_stanza(stanza).root, '9f00061', '1' }

    let :stanza do
        <<-MESSAGE
<sendfax xmlns='urn:xmpp:rayo:fax:1'>
  <document xmlns='urn:xmpp:rayo:fax:1' url='http://shakespere.lit/my_fax.tiff' identity='+14045555555' header='Hello world' pages='1-4,5,7-9'/>
</sendfax>
        MESSAGE
    end

    describe '#render_documents' do
      subject { super().render_documents }
      it { is_expected.to eq([Adhearsion::Rayo::Component::SendFax::FaxDocument.new(url: 'http://shakespere.lit/my_fax.tiff', identity: '+14045555555', header: 'Hello world', pages: [1..4,5,7..9])]) }
    end

    context "without optional attributes" do
      let :stanza do
          <<-MESSAGE
<sendfax xmlns='urn:xmpp:rayo:fax:1'>
  <document xmlns='urn:xmpp:rayo:fax:1' url='http://shakespere.lit/my_fax.tiff'/>
</sendfax>
          MESSAGE
      end

      describe '#render_documents' do
        subject { super().render_documents }
        it { is_expected.to eq([Adhearsion::Rayo::Component::SendFax::FaxDocument.new(url: 'http://shakespere.lit/my_fax.tiff')]) }
      end
    end
  end
end

describe Adhearsion::Rayo::Component::SendFax::FaxDocument do
  it "registers itself" do
    expect(Adhearsion::Rayo::RayoNode.class_from_registration(:document, 'urn:xmpp:rayo:fax:1')).to eq(described_class)
  end

  subject { described_class.new(url: 'http://shakespere.lit/my_fax.tiff', identity: '+14045555555', header: 'Hello world', pages: [1..4,5,7..9]) }

  describe '#url' do
    subject { super().url }
    it { is_expected.to eq('http://shakespere.lit/my_fax.tiff') }
  end

  describe '#identity' do
    subject { super().identity }
    it { is_expected.to eq('+14045555555') }
  end

  describe '#header' do
    subject { super().header }
    it { is_expected.to eq('Hello world') }
  end

  describe '#pages' do
    subject { super().pages }
    it { is_expected.to eq([1..4,5,7..9]) }
  end

  context "without optional attributes" do
    subject { described_class.new(url: 'http://shakespere.lit/my_fax.tiff') }

    describe '#url' do
      subject { super().url }
      it { is_expected.to eq('http://shakespere.lit/my_fax.tiff') }
    end

    describe '#identity' do
      subject { super().identity }
      it { is_expected.to be_nil }
    end

    describe '#header' do
      subject { super().header }
      it { is_expected.to be_nil }
    end

    describe '#pages' do
      subject { super().pages }
      it { is_expected.to be_nil }
    end
  end

  describe "comparison" do
    it "should be the same with the same attributes" do
      is_expected.to eq(described_class.new(url: 'http://shakespere.lit/my_fax.tiff', identity: '+14045555555', header: 'Hello world', pages: [1..4,5,7..9]))
    end

    it "should be different with a different url" do
      is_expected.not_to eq(described_class.new(url: 'http://shakespere.lit/my_other_fax.tiff', identity: '+14045555555', header: 'Hello world', pages: [1..4,5,7..9]))
    end

    it "should be different with a different identity" do
      is_expected.not_to eq(described_class.new(url: 'http://shakespere.lit/my_fax.tiff', identity: '+14045555556', header: 'Hello world', pages: [1..4,5,7..9]))
    end

    it "should be different with a different header" do
      is_expected.not_to eq(described_class.new(url: 'http://shakespere.lit/my_fax.tiff', identity: '+14045555555', header: 'Hello Paul', pages: [1..4,5,7..9]))
    end

    it "should be different with a different pages" do
      is_expected.not_to eq(described_class.new(url: 'http://shakespere.lit/my_fax.tiff', identity: '+14045555555', header: 'Hello world', pages: [1..4,5,6..9]))
    end
  end
end
