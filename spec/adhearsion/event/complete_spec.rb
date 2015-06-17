# encoding: utf-8

require 'spec_helper'

describe Adhearsion::Event::Complete do
  it 'registers itself' do
    expect(Adhearsion::Rayo::RayoNode.class_from_registration(:complete, 'urn:xmpp:rayo:ext:1')).to eq(described_class)
  end

  describe "setting a reason" do
    let(:reason) { Adhearsion::Event::Complete::Stop.new }

    describe '#reason' do
      it "should set the reason" do
        subject.reason = reason
        expect(subject.reason).to eq(reason)
      end
    end
  end

  describe "comparing for equality" do
    subject do
      described_class.new reason: Adhearsion::Event::Complete::Stop.new,
        target_call_id: '1234',
        component_id: 'abcd'
    end

    let :other_complete do
      described_class.new reason: reason,
        target_call_id: call_id,
        component_id: component_id
    end

    context 'with reason, call id and component id the same' do
      let(:reason)        { Adhearsion::Event::Complete::Stop.new }
      let(:call_id)       { '1234' }
      let(:component_id)  { 'abcd' }

      it "should be equal" do
        expect(subject).to eq(other_complete)
      end
    end

    context 'with a different reason' do
      let(:reason)        { Adhearsion::Event::Complete::Hangup.new }
      let(:call_id)       { '1234' }
      let(:component_id)  { 'abcd' }

      it "should not be equal" do
        expect(subject).not_to eq(other_complete)
      end
    end

    context 'with a different call id' do
      let(:reason)        { Adhearsion::Event::Complete::Stop.new }
      let(:call_id)       { '5678' }
      let(:component_id)  { 'abcd' }

      it "should not be equal" do
        expect(subject).not_to eq(other_complete)
      end
    end

    context 'with a different component id' do
      let(:reason)        { Adhearsion::Event::Complete::Stop.new }
      let(:call_id)       { '1234' }
      let(:component_id)  { 'efgh' }

      it "should not be equal" do
        expect(subject).not_to eq(other_complete)
      end
    end
  end

  describe "from a stanza" do
    let :stanza do
      <<-MESSAGE
<complete xmlns='urn:xmpp:rayo:ext:1'>
  <stop xmlns='urn:xmpp:rayo:ext:complete:1' />
</complete>
      MESSAGE
    end

    subject { Adhearsion::Rayo::RayoNode.from_xml parse_stanza(stanza).root, '9f00061', '1' }

    it { is_expected.to be_instance_of described_class }

    it_should_behave_like 'event'

    describe '#reason' do
      subject { super().reason }
      it { is_expected.to be_instance_of Adhearsion::Event::Complete::Stop }
    end
  end
end

describe Adhearsion::Event::Complete::Stop do
  let :stanza do
    <<-MESSAGE
<complete xmlns='urn:xmpp:rayo:ext:1'>
  <stop xmlns='urn:xmpp:rayo:ext:complete:1' />
</complete>
    MESSAGE
  end

  subject { Adhearsion::Rayo::RayoNode.from_xml(parse_stanza(stanza).root).reason }

  it { is_expected.to be_instance_of described_class }

  describe '#name' do
    subject { super().name }
    it { is_expected.to eq(:stop) }
  end
end

describe Adhearsion::Event::Complete::Hangup do
  let :stanza do
    <<-MESSAGE
<complete xmlns='urn:xmpp:rayo:ext:1'>
  <hangup xmlns='urn:xmpp:rayo:ext:complete:1' />
</complete>
    MESSAGE
  end

  subject { Adhearsion::Rayo::RayoNode.from_xml(parse_stanza(stanza).root).reason }

  it { is_expected.to be_instance_of described_class }

  describe '#name' do
    subject { super().name }
    it { is_expected.to eq(:hangup) }
  end
end

describe Adhearsion::Event::Complete::Error do
  let :stanza do
    <<-MESSAGE
<complete xmlns='urn:xmpp:rayo:ext:1'>
  <error xmlns='urn:xmpp:rayo:ext:complete:1'>
    Something really bad happened
  </error>
</complete>
    MESSAGE
  end

  subject { Adhearsion::Rayo::RayoNode.from_xml(parse_stanza(stanza).root).reason }

  it { is_expected.to be_instance_of described_class }

  describe '#name' do
    subject { super().name }
    it { is_expected.to eq(:error) }
  end

  describe '#details' do
    subject { super().details }
    it { is_expected.to eq("Something really bad happened") }
  end

  describe "when setting options in initializer" do
    subject do
      described_class.new :details => 'Ooops'
    end

    describe '#details' do
      subject { super().details }
      it { is_expected.to eq('Ooops') }
    end
  end
end

describe Adhearsion::Event::Complete::Reason do
  subject { described_class.new name: "Foo" }

  it { is_expected.to be_a Adhearsion::Event }
end
