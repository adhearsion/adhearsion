# encoding: utf-8

require 'spec_helper'

describe Adhearsion::Rayo::Command::Join do
  it 'registers itself' do
    expect(Adhearsion::Rayo::RayoNode.class_from_registration(:join, 'urn:xmpp:rayo:1')).to eq(described_class)
  end

  describe "when setting options in initializer" do
    subject { described_class.new :call_uri => 'abc123', :mixer_name => 'blah', :direction => :duplex, :media => :bridge }

    describe '#call_uri' do
      subject { super().call_uri }
      it { is_expected.to eq('abc123') }
    end

    describe '#mixer_name' do
      subject { super().mixer_name }
      it { is_expected.to eq('blah') }
    end

    describe '#direction' do
      subject { super().direction }
      it { is_expected.to eq(:duplex) }
    end

    describe '#media' do
      subject { super().media }
      it { is_expected.to eq(:bridge) }
    end

    context "with old call_id attribute" do
      subject { described_class.new call_id: 'abc123' }

      describe '#call_uri' do
        subject { super().call_uri }
        it { is_expected.to eq('abc123') }
      end
    end

    describe "exporting to Rayo" do
      it "should export to XML that can be understood by its parser" do
        new_instance = Adhearsion::Rayo::RayoNode.from_xml subject.to_rayo
        expect(new_instance).to be_instance_of described_class
        expect(new_instance.call_uri).to eq('abc123')
        expect(new_instance.mixer_name).to eq('blah')
        expect(new_instance.direction).to eq(:duplex)
        expect(new_instance.media).to eq(:bridge)
      end

      it "should render to a parent node if supplied" do
        doc = Nokogiri::XML::Document.new
        parent = Nokogiri::XML::Node.new 'foo', doc
        doc.root = parent
        rayo_doc = subject.to_rayo(parent)
        expect(rayo_doc).to eq(parent)
      end

      context "when attributes are not set" do
        subject { described_class.new call_uri: 'abc123' }

        it "should not include them in the XML representation" do
          expect(subject.to_rayo['call-uri']).to eq('abc123')
          expect(subject.to_rayo['mixer-name']).to be_nil
        end
      end
    end
  end

  describe "from a stanza" do
    let :stanza do
      <<-MESSAGE
<join xmlns="urn:xmpp:rayo:1"
      call-uri="abc123"
      mixer-name="blah"
      direction="duplex"
      media="bridge" />
      MESSAGE
    end

    subject { Adhearsion::Rayo::RayoNode.from_xml parse_stanza(stanza).root, '9f00061', '1' }

    it { is_expected.to be_instance_of described_class }

    describe '#call_uri' do
      subject { super().call_uri }
      it { is_expected.to eq('abc123') }
    end

    describe '#mixer_name' do
      subject { super().mixer_name }
      it { is_expected.to eq('blah') }
    end

    describe '#direction' do
      subject { super().direction }
      it { is_expected.to eq(:duplex) }
    end

    describe '#media' do
      subject { super().media }
      it { is_expected.to eq(:bridge) }
    end

    context "when no attributes are set" do
      let(:stanza) { '<join xmlns="urn:xmpp:rayo:1" />' }

      describe '#call_uri' do
        subject { super().call_uri }
        it { is_expected.to be_nil }
      end

      describe '#mixer_name' do
        subject { super().mixer_name }
        it { is_expected.to be_nil }
      end

      describe '#direction' do
        subject { super().direction }
        it { is_expected.to be_nil }
      end

      describe '#media' do
        subject { super().media }
        it { is_expected.to be_nil }
      end
    end
  end

  describe "with a direction" do
    [nil, :duplex, :send, :recv].each do |direction|
      describe direction.to_s do
        subject { described_class.new :direction => direction }

        describe '#direction' do
          subject { super().direction }
          it { is_expected.to eq(direction) }
        end
      end
    end

    describe "no direction" do
      subject { described_class.new }

      describe '#direction' do
        subject { super().direction }
        it { is_expected.to be_nil }
      end
    end

    describe "blahblahblah" do
      it "should raise an error" do
        expect { described_class.new(:direction => :blahblahblah) }.to raise_error ArgumentError
      end
    end
  end
end
