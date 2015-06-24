# encoding: utf-8

require 'spec_helper'

describe Adhearsion::Rayo::Component::ReceiveFax do
  it 'registers itself' do
    expect(Adhearsion::Rayo::RayoNode.class_from_registration(:receivefax, 'urn:xmpp:rayo:fax:1')).to eq(described_class)
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

  describe "from a stanza" do
    let :stanza do
      <<-MESSAGE
<receivefax xmlns="urn:xmpp:rayo:fax:1"/>
      MESSAGE
    end

    subject { Adhearsion::Rayo::RayoNode.from_xml parse_stanza(stanza).root, '9f00061', '1' }

    it { is_expected.to be_instance_of described_class }
  end

  describe "actions" do
    let(:mock_client) { double 'Client' }
    let(:command) { described_class.new }

    before do
      command.component_id = 'abc123'
      command.target_call_id = '123abc'
      command.client = mock_client
    end

    describe '#stop_action' do
      subject { command.stop_action }

      describe '#to_xml' do
        subject { super().to_xml }
        it { is_expected.to eq('<stop xmlns="urn:xmpp:rayo:ext:1"/>') }
      end

      describe '#component_id' do
        subject { super().component_id }
        it { is_expected.to eq('abc123') }
      end

      describe '#target_call_id' do
        subject { super().target_call_id }
        it { is_expected.to eq('123abc') }
      end
    end

    describe '#stop!' do
      describe "when the command is executing" do
        before do
          command.request!
          command.execute!
        end

        it "should send its command properly" do
          expect(mock_client).to receive(:execute_command).with(command.stop_action, :target_call_id => '123abc', :component_id => 'abc123')
          command.stop!
        end
      end

      describe "when the command is not executing" do
        it "should raise an error" do
          expect { command.stop! }.to raise_error(Adhearsion::Rayo::Component::InvalidActionError, "Cannot stop a ReceiveFax that is new")
        end
      end
    end
  end

  describe Adhearsion::Rayo::Component::ReceiveFax::Complete::Finish do
    let :stanza do
      <<-MESSAGE
<complete xmlns='urn:xmpp:rayo:ext:1'>
  <finish xmlns='urn:xmpp:rayo:fax:complete:1'/>
  <fax xmlns='urn:xmpp:rayo:fax:complete:1' url='http://shakespere.lit/faxes/fax1.tiff' resolution='595x841' size='12287492817' pages='3'/>
  <metadata xmlns='urn:xmpp:rayo:fax:complete:1' name="fax-transfer-rate" value="10000" />
  <metadata xmlns='urn:xmpp:rayo:fax:complete:1' name="foo" value="true" />
</complete>
      MESSAGE
    end

    subject(:complete_node) { Adhearsion::Rayo::RayoNode.from_xml(parse_stanza(stanza).root) }

    it "should understand a finish reason" do
      expect(subject.reason).to be_instance_of described_class
    end

    describe "should make the fax data available" do
      subject { complete_node.fax }

      it { is_expected.to be_instance_of Adhearsion::Rayo::Component::ReceiveFax::Fax }

      describe '#url' do
        subject { super().url }
        it { is_expected.to eq('http://shakespere.lit/faxes/fax1.tiff') }
      end

      describe '#resolution' do
        subject { super().resolution }
        it { is_expected.to eq('595x841') }
      end

      describe '#pages' do
        subject { super().pages }
        it { is_expected.to eq(3) }
      end

      describe '#size' do
        subject { super().size }
        it { is_expected.to eq(12287492817) }
      end
    end

    describe '#fax_metadata' do
      subject { super().fax_metadata }
      it { is_expected.to eq({'fax-transfer-rate' => '10000', 'foo' => 'true'}) }
    end
  end
end
