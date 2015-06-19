# encoding: utf-8

require 'spec_helper'

describe Adhearsion::Rayo::Command::Reject do
  it 'registers itself' do
    expect(Adhearsion::Rayo::RayoNode.class_from_registration(:reject, 'urn:xmpp:rayo:1')).to eq(described_class)
  end

  describe "when setting options in initializer" do
    subject { described_class.new reason: :busy, headers: { 'X-skill' => 'agent', 'X-customer-id' => '8877' } }

    describe '#reason' do
      subject { super().reason }
      it { is_expected.to eq(:busy) }
    end

    describe '#headers' do
      subject { super().headers }
      it { is_expected.to eq({ 'X-skill' => 'agent', 'X-customer-id' => '8877' }) }
    end

    describe "exporting to Rayo" do
      it "should export to XML that can be understood by its parser" do
        new_instance = Adhearsion::Rayo::RayoNode.from_xml subject.to_rayo
        expect(new_instance).to be_instance_of described_class
        expect(new_instance.reason).to eq(:busy)
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
          expect(subject.to_rayo.children.count).to eq(0)
        end
      end
    end
  end

  describe "from a stanza" do
    let :stanza do
      <<-MESSAGE
<reject xmlns='urn:xmpp:rayo:1'>
<busy />
<!-- Sample Headers (optional) -->
<header name="X-skill" value="agent" />
<header name="X-customer-id" value="8877" />
</reject>
      MESSAGE
    end

    subject { Adhearsion::Rayo::RayoNode.from_xml parse_stanza(stanza).root, '9f00061', '1' }

    it { is_expected.to be_instance_of described_class }

    describe '#reason' do
      subject { super().reason }
      it { is_expected.to eq(:busy) }
    end

    describe '#headers' do
      subject { super().headers }
      it { is_expected.to eq({ 'X-skill' => 'agent', 'X-customer-id' => '8877' }) }
    end

    context "with no headers or reason provided" do
      let(:stanza) { '<reject xmlns="urn:xmpp:rayo:1"/>' }

      describe '#reason' do
        subject { super().reason }
        it { is_expected.to be_nil }
      end

      describe '#headers' do
        subject { super().headers }
        it { is_expected.to eq({}) }
      end
    end
  end

  describe "with the reason" do
    [nil, :decline, :busy, :error].each do |reason|
      describe reason.to_s do
        subject { described_class.new :reason => reason }

        describe '#reason' do
          subject { super().reason }
          it { is_expected.to eq(reason) }
        end
      end
    end

    describe "no reason" do
      subject { described_class.new }

      describe '#reason' do
        subject { super().reason }
        it { is_expected.to be_nil }
      end
    end

    describe "blahblahblah" do
      it "should raise an error" do
        expect { described_class.new(:reason => :blahblahblah) }.to raise_error ArgumentError
      end
    end
  end
end
