# encoding: utf-8

require 'spec_helper'

describe Adhearsion::Rayo::Component::Asterisk::AGI::Command do
  it 'registers itself' do
    expect(Adhearsion::Rayo::RayoNode.class_from_registration(:command, 'urn:xmpp:rayo:asterisk:agi:1')).to eq(described_class)
  end

  describe "from a stanza" do
    let :stanza do
      <<-MESSAGE
<command xmlns="urn:xmpp:rayo:asterisk:agi:1" name="GET VARIABLE">
  <param value="UNIQUEID"/>
</command>
      MESSAGE
    end

    subject { Adhearsion::Rayo::RayoNode.from_xml parse_stanza(stanza).root, '9f00061', '1' }

    it { is_expected.to be_instance_of described_class }

    it_should_behave_like 'event'

    describe '#name' do
      subject { super().name }
      it { is_expected.to eq('GET VARIABLE') }
    end

    describe '#params' do
      subject { super().params }
      it { is_expected.to eq(['UNIQUEID']) }
    end
  end

  describe "when setting options in initializer" do
    subject do
      described_class.new name: 'GET VARIABLE',
                          params: ['UNIQUEID']
    end

    describe '#name' do
      subject { super().name }
      it { is_expected.to eq('GET VARIABLE') }
    end

    describe '#params' do
      subject { super().params }
      it { is_expected.to eq(['UNIQUEID']) }
    end
  end

  describe described_class::Complete::Success do
    let :stanza do
      <<-MESSAGE
<complete xmlns="urn:xmpp:rayo:ext:1">
  <success xmlns="urn:xmpp:rayo:asterisk:agi:complete:1">
    <code>200</code>
    <result>0</result>
    <data>1187188485.0</data>
  </success>
</complete>
      MESSAGE
    end

    subject { Adhearsion::Rayo::RayoNode.from_xml(parse_stanza(stanza).root).reason }

    it { is_expected.to be_instance_of described_class }

    describe '#name' do
      subject { super().name }
      it { is_expected.to eq(:success) }
    end

    describe '#code' do
      subject { super().code }
      it { is_expected.to eq(200) }
    end

    describe '#result' do
      subject { super().result }
      it { is_expected.to eq(0) }
    end

    describe '#data' do
      subject { super().data }
      it { is_expected.to eq('1187188485.0') }
    end

    describe "when setting options in initializer" do
      subject do
        described_class.new code: 200, result: 0, data: '1187188485.0'
      end

      describe '#code' do
        subject { super().code }
        it { is_expected.to eq(200) }
      end

      describe '#result' do
        subject { super().result }
        it { is_expected.to eq(0) }
      end

      describe '#data' do
        subject { super().data }
        it { is_expected.to eq('1187188485.0') }
      end
    end
  end
end
