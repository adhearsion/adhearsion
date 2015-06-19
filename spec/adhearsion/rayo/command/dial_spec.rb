# encoding: utf-8

require 'spec_helper'

describe Adhearsion::Rayo::Command::Dial do
  it 'registers itself' do
    expect(Adhearsion::Rayo::RayoNode.class_from_registration(:dial, 'urn:xmpp:rayo:1')).to eq(described_class)
  end

  let(:join_params) { {:call_uri => 'abc123'} }

  describe "when setting options in initializer" do
    subject { described_class.new to: 'tel:+14155551212', from: 'tel:+13035551212', uri: 'xmpp:foo@bar.com', timeout: 30000, headers: { 'X-skill' => 'agent', 'X-customer-id' => '8877' }, join: join_params }

    describe '#to' do
      subject { super().to }
      it { is_expected.to eq('tel:+14155551212') }
    end

    describe '#from' do
      subject { super().from }
      it { is_expected.to eq('tel:+13035551212') }
    end

    describe '#uri' do
      subject { super().uri }
      it { is_expected.to eq('xmpp:foo@bar.com') }
    end

    describe '#timeout' do
      subject { super().timeout }
      it { is_expected.to eq(30000) }
    end

    describe '#join' do
      subject { super().join }
      it { is_expected.to eq(Adhearsion::Rayo::Command::Join.new(join_params)) }
    end

    describe '#headers' do
      subject { super().headers }
      it { is_expected.to eq({ 'X-skill' => 'agent', 'X-customer-id' => '8877' }) }
    end

    describe "exporting to Rayo" do
      it "should export to XML that can be understood by its parser" do
        new_instance = Adhearsion::Rayo::RayoNode.from_xml subject.to_rayo
        expect(new_instance).to be_instance_of described_class
        expect(new_instance.to).to eq('tel:+14155551212')
        expect(new_instance.from).to eq('tel:+13035551212')
        expect(new_instance.uri).to eq('xmpp:foo@bar.com')
        expect(new_instance.timeout).to eq(30000)
        expect(new_instance.join).to eq(Adhearsion::Rayo::Command::Join.new(join_params))
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
        subject { described_class.new to: 'abc123' }

        it "should not include them in the XML representation" do
          expect(subject.to_rayo['to']).to eq('abc123')
          expect(subject.to_rayo['from']).to be_nil
        end
      end
    end
  end

  describe "from a stanza" do
    let :stanza do
      <<-MESSAGE
<dial to='tel:+14155551212' from='tel:+13035551212' uri='xmpp:foo@bar.com' timeout='30000' xmlns='urn:xmpp:rayo:1'>
  <join call-uri="abc123" />
  <header name="X-skill" value="agent" />
  <header name="X-customer-id" value="8877" />
</dial>
      MESSAGE
    end

    subject { Adhearsion::Rayo::RayoNode.from_xml parse_stanza(stanza).root, '9f00061', '1' }

    it { is_expected.to be_instance_of described_class }

    describe '#to' do
      subject { super().to }
      it { is_expected.to eq('tel:+14155551212') }
    end

    describe '#from' do
      subject { super().from }
      it { is_expected.to eq('tel:+13035551212') }
    end

    describe '#uri' do
      subject { super().uri }
      it { is_expected.to eq('xmpp:foo@bar.com') }
    end

    describe '#timeout' do
      subject { super().timeout }
      it { is_expected.to eq(30000) }
    end

    describe '#join' do
      subject { super().join }
      it { is_expected.to eq(Adhearsion::Rayo::Command::Join.new(join_params)) }
    end

    describe '#headers' do
      subject { super().headers }
      it { is_expected.to eq({ 'X-skill' => 'agent', 'X-customer-id' => '8877' }) }
    end

    context "with no headers provided" do
      let(:stanza) { '<dial xmlns="urn:xmpp:rayo:1"/>' }

      describe '#headers' do
        subject { super().headers }
        it { is_expected.to eq({}) }
      end
    end
  end

  describe "#response=" do
    before { subject.request! }

    let(:call_id) { 'abc123' }
    let(:domain)  { 'rayo.net' }

    let :ref do
      Adhearsion::Rayo::Ref.new uri: "xmpp:#{call_id}@#{domain}"
    end

    it "should set the transport from the ref" do
      subject.response = ref
      expect(subject.transport).to eq('xmpp')
    end

    it "should set the call ID from the ref" do
      subject.response = ref
      expect(subject.target_call_id).to eq(call_id)
    end

    it "should set the domain from the ref" do
      subject.response = ref
      expect(subject.domain).to eq(domain)
    end
  end
end
