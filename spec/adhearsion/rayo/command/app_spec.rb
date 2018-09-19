# encoding: utf-8

require 'spec_helper'

describe Adhearsion::Rayo::Command::App do
  it 'registers itself' do
    expect(Adhearsion::Rayo::RayoNode.class_from_registration(:app, 'urn:xmpp:rayo:1')).to eq(described_class)
  end

  describe "when setting options in initializer" do
    subject { described_class.new app: 'playback', args: 'hello' }

    describe '#app' do
      subject { super().app }
      it { is_expected.to eq('playback') }
    end

    describe '#args' do
      subject { super().args }
      it { is_expected.to eq('hello') }
    end

    describe "exporting to Rayo" do
      it "should export to XML that can be understood by its parser" do
        puts subject.to_rayo
        new_instance = Adhearsion::Rayo::RayoNode.from_xml subject.to_rayo
        expect(new_instance).to be_instance_of described_class
        expect(new_instance.app).to eq('hello')
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
        subject { described_class.new app: 'hangup' }

        it "should not include them in the XML representation" do
          expect(subject.to_rayo['app']).to eq('hangup')
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



