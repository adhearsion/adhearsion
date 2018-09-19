# encoding: utf-8

require 'spec_helper'

describe Adhearsion::Rayo::Response do
  it 'registers itself' do
    expect(Adhearsion::Rayo::RayoNode.class_from_registration(:response, 'urn:xmpp:rayo:1')).to eq(described_class)
  end

  describe "from a stanza" do
    let(:response)     { 'some_string' }
    let(:stanza)  { "<response response='#{response}' xmlns='urn:xmpp:rayo:1' />" }

    subject { Adhearsion::Rayo::RayoNode.from_xml parse_stanza(stanza).root, '9f00061', '1' }

    it { is_expected.to be_instance_of described_class }
  end

  describe "when setting options in initializer" do
    subject { described_class.new response: response }
    let(:response) { 'xmpp:fgh4590@.net/abc123' }

    describe '#response' do
      subject { super().response }
      it { is_expected.to eq(response) }
    end

    describe "exporting to Rayo" do
      context "when attributes are set" do
        let(:response) { 'fgh4590' }

        it "should export to XML that can be understood by its parser" do
          new_instance = Adhearsion::Rayo::RayoNode.from_xml subject.to_rayo
          expect(new_instance).to be_instance_of described_class
          expect(new_instance.response).to eq(response)
        end
      end

      context "when attributes are not set" do
        subject { described_class.new }

        it "should not include them in the XML representation" do
          expect(subject.to_rayo['response']).to be_nil
        end
      end
    end
  end
end


