# encoding: utf-8

require 'spec_helper'

describe Adhearsion::Rayo::Ref do
  it 'registers itself' do
    expect(Adhearsion::Rayo::RayoNode.class_from_registration(:ref, 'urn:xmpp:rayo:1')).to eq(described_class)
  end

  describe "from a stanza" do
    let(:uri)     { 'some_uri' }
    let(:stanza)  { "<ref uri='#{uri}' xmlns='urn:xmpp:rayo:1' />" }

    subject { Adhearsion::Rayo::RayoNode.from_xml parse_stanza(stanza).root, '9f00061', '1' }

    it { is_expected.to be_instance_of described_class }

    describe '#target_call_id' do
      subject { super().target_call_id }
      it { is_expected.to eq('9f00061') }
    end

    context "when the URI isn't actually a URI" do
      let(:uri) { 'fgh4590' }

      describe '#uri' do
        subject { super().uri }
        it { is_expected.to eq(URI('fgh4590')) }
      end

      describe '#scheme' do
        subject { super().scheme }
        it { is_expected.to eq(nil) }
      end

      describe '#call_id' do
        subject { super().call_id }
        it { is_expected.to eq('fgh4590') }
      end

      describe '#domain' do
        subject { super().domain }
        it { is_expected.to eq(nil) }
      end

      describe '#component_id' do
        subject { super().component_id }
        it { is_expected.to eq('fgh4590') }
      end
    end

    context "when the URI is an XMPP JID" do
      let(:uri) { 'xmpp:fgh4590@rayo.net/abc123' }

      describe '#uri' do
        subject { super().uri }
        it { is_expected.to eq(URI('xmpp:fgh4590@rayo.net/abc123')) }
      end

      describe '#scheme' do
        subject { super().scheme }
        it { is_expected.to eq('xmpp') }
      end

      describe '#call_id' do
        subject { super().call_id }
        it { is_expected.to eq('fgh4590') }
      end

      describe '#domain' do
        subject { super().domain }
        it { is_expected.to eq('rayo.net') }
      end

      describe '#component_id' do
        subject { super().component_id }
        it { is_expected.to eq('abc123') }
      end
    end

    context "when the URI is an asterisk UUID" do
      let(:uri) { 'asterisk:fgh4590' }

      describe '#uri' do
        subject { super().uri }
        it { is_expected.to eq(URI('asterisk:fgh4590')) }
      end

      describe '#scheme' do
        subject { super().scheme }
        it { is_expected.to eq('asterisk') }
      end

      describe '#call_id' do
        subject { super().call_id }
        it { is_expected.to eq('fgh4590') }
      end

      describe '#domain' do
        subject { super().domain }
        it { is_expected.to eq(nil) }
      end

      describe '#component_id' do
        subject { super().component_id }
        it { is_expected.to eq('fgh4590') }
      end
    end
  end

  describe "when setting options in initializer" do
    subject { described_class.new uri: uri }
    let(:uri) { 'xmpp:fgh4590@rayo.net/abc123' }

    describe '#uri' do
      subject { super().uri }
      it { is_expected.to eq(URI('xmpp:fgh4590@rayo.net/abc123')) }
    end

    describe "exporting to Rayo" do
      context "when the URI isn't actually a URI" do
        let(:uri) { 'fgh4590' }

        it "should export to XML that can be understood by its parser" do
          new_instance = Adhearsion::Rayo::RayoNode.from_xml subject.to_rayo
          expect(new_instance).to be_instance_of described_class
          expect(new_instance.uri).to eq(URI('fgh4590'))
        end
      end

      context "when the URI is an XMPP JID" do
        let(:uri) { 'xmpp:fgh4590@rayo.net' }

        it "should export to XML that can be understood by its parser" do
          new_instance = Adhearsion::Rayo::RayoNode.from_xml subject.to_rayo
          expect(new_instance).to be_instance_of described_class
          expect(new_instance.uri).to eq(URI('xmpp:fgh4590@rayo.net'))
        end
      end

      context "when the URI is an asterisk UUID" do
        let(:uri) { 'asterisk:fgh4590' }

        it "should export to XML that can be understood by its parser" do
          new_instance = Adhearsion::Rayo::RayoNode.from_xml subject.to_rayo
          expect(new_instance).to be_instance_of described_class
          expect(new_instance.uri).to eq(URI('asterisk:fgh4590'))
        end
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
          expect(subject.to_rayo['uri']).to be_nil
        end
      end
    end
  end
end
