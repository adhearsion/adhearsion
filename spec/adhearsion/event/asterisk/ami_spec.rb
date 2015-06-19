# encoding: utf-8

require 'spec_helper'

describe Adhearsion::Event::Asterisk::AMI do
  it 'registers itself' do
    expect(Adhearsion::Rayo::RayoNode.class_from_registration(:event, 'urn:xmpp:rayo:asterisk:ami:1')).to eq(described_class)
  end

  describe "from a stanza" do
    let :stanza do
      <<-MESSAGE
<event xmlns="urn:xmpp:rayo:asterisk:ami:1" name="Newchannel">
  <attribute name="Channel" value="SIP/101-3f3f"/>
  <attribute name="State" value="Ring"/>
</event>
      MESSAGE
    end

    subject { Adhearsion::Rayo::RayoNode.from_xml parse_stanza(stanza).root, '9f00061', '1' }

    it { is_expected.to be_instance_of described_class }

    it_should_behave_like 'event'

    describe '#name' do
      subject { super().name }
      it { is_expected.to eq('Newchannel') }
    end

    describe '#headers' do
      subject { super().headers }
      it { is_expected.to eq({'Channel' => 'SIP/101-3f3f', 'State' => 'Ring'}) }
    end

    describe '#attributes' do
      subject { super().attributes }
      it { is_expected.to eq({'Channel' => 'SIP/101-3f3f', 'State' => 'Ring'}) }
    end # For BC
  end

  describe "when setting options in initializer" do
    subject do
      described_class.new name: 'Newchannel',
                          headers: {'Channel' => 'SIP/101-3f3f', 'State' => 'Ring'}
    end

    describe '#name' do
      subject { super().name }
      it { is_expected.to eq('Newchannel') }
    end

    describe '#headers' do
      subject { super().headers }
      it { is_expected.to eq({'Channel' => 'SIP/101-3f3f', 'State' => 'Ring'}) }
    end

    describe '#attributes' do
      subject { super().attributes }
      it { is_expected.to eq({'Channel' => 'SIP/101-3f3f', 'State' => 'Ring'}) }
    end # For BC

    describe "exporting to Rayo" do
      it "should export to XML that can be understood by its parser" do
        new_instance = Adhearsion::Rayo::RayoNode.from_xml subject.to_rayo
        expect(new_instance).to be_instance_of described_class
        expect(new_instance.name).to eq('Newchannel')
        expect(new_instance.headers).to eq({'Channel' => 'SIP/101-3f3f', 'State' => 'Ring'})
        expect(new_instance.attributes).to eq({'Channel' => 'SIP/101-3f3f', 'State' => 'Ring'}) # For BC
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
