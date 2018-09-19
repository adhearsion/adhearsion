# encoding: utf-8

require 'spec_helper'

describe Adhearsion::Rayo::Command::Exec do
  it 'registers itself' do
    expect(Adhearsion::Rayo::RayoNode.class_from_registration(:exec, 'urn:xmpp:rayo:1')).to eq(described_class)
  end

  describe "when setting options in initializer" do
    subject { described_class.new api: 'sofia', args: 'status' }

    describe '#api' do
      subject { super().api }
      it { is_expected.to eq('sofia') }
    end

    describe '#args' do
      subject { super().args }
      it { is_expected.to eq('status') }
    end

    describe "exporting to Rayo" do
      it "should export to XML that can be understood by its parser" do
        puts subject.to_rayo
        new_instance = Adhearsion::Rayo::RayoNode.from_xml subject.to_rayo
        expect(new_instance).to be_instance_of described_class
        expect(new_instance.api).to eq('sofia')
        expect(new_instance.args).to eq('status')
      end

      it "should render to a parent node if supplied" do
        doc = Nokogiri::XML::Document.new
        parent = Nokogiri::XML::Node.new 'foo', doc
        doc.root = parent
        rayo_doc = subject.to_rayo(parent)
        expect(rayo_doc).to eq(parent)
      end

      context "when attributes are not set" do
        subject { described_class.new api: 'sofia' }

        it "should not include them in the XML representation" do
          expect(subject.to_rayo['api']).to eq('sofia')
          expect(subject.to_rayo['args']).to be_nil
        end
      end
    end
  end

  describe "#response=" do
    subject { described_class.new app: 'send_dtmf', args: '1' }

    it 'sets the response' do
      subject.request!
      subject.response = 'ok'
      expect(subject.response).to eq 'ok'
    end

  end
end


