# encoding: utf-8

require 'spec_helper'

describe Adhearsion::Rayo::Component::Asterisk::AMI::Action do
  it 'registers itself' do
    expect(Adhearsion::Rayo::RayoNode.class_from_registration(:action, 'urn:xmpp:rayo:asterisk:ami:1')).to eq(described_class)
  end

  describe "from a stanza" do
    let :stanza do
      <<-MESSAGE
<action xmlns="urn:xmpp:rayo:asterisk:ami:1" name="Originate">
  <param name="Channel" value="SIP/101test"/>
  <param name="Context" value="default"/>
  <param name="Exten" value="8135551212"/>
  <param name="Priority" value="1"/>
  <param name="Callerid" value="3125551212"/>
  <param name="Timeout" value="30000"/>
  <param name="Variable" value="var1=23|var2=24|var3=25"/>
  <param name="Async" value="1"/>
</action>
      MESSAGE
    end

    subject { Adhearsion::Rayo::RayoNode.from_xml parse_stanza(stanza).root, '9f00061', '1' }

    it { is_expected.to be_instance_of described_class }

    it_should_behave_like 'event'

    describe '#name' do
      subject { super().name }
      it { is_expected.to eq('Originate') }
    end

    describe '#params' do
      subject { super().params }
      it { is_expected.to eq({ 'Channel'   => 'SIP/101test',
                                   'Context'   => 'default',
                                   'Exten'     => '8135551212',
                                   'Priority'  => '1',
                                   'Callerid'  => '3125551212',
                                   'Timeout'   => '30000',
                                   'Variable'  => 'var1=23|var2=24|var3=25',
                                   'Async'     => '1'}) }
    end
  end

  describe "testing equality" do
    context "with the same name and params" do
      it "should be equal" do
        expect(described_class.new(:name => 'Originate', :params => { :channel => 'SIP/101test' })).to eq(described_class.new(:name => 'Originate', :params => { :channel => 'SIP/101test' }))
      end
    end

    context "with the same name and different params" do
      it "should be equal" do
        expect(described_class.new(:name => 'Originate', :params => { :channel => 'SIP/101' })).not_to eq(described_class.new(:name => 'Originate', :params => { :channel => 'SIP/101test' }))
      end
    end

    context "with a different name and the same params" do
      it "should be equal" do
        expect(described_class.new(:name => 'Hangup', :params => { :channel => 'SIP/101test' })).not_to eq(described_class.new(:name => 'Originate', :params => { :channel => 'SIP/101test' }))
      end
    end
  end

  describe "when setting options in initializer" do
    subject do
      described_class.new :name => 'Originate',
                          :params => { 'Channel' => 'SIP/101test' }
    end

    describe '#name' do
      subject { super().name }
      it { is_expected.to eq('Originate') }
    end

    describe '#params' do
      subject { super().params }
      it { is_expected.to eq({ 'Channel' => 'SIP/101test' }) }
    end

    describe "exporting to Rayo" do
      it "should export to XML that can be understood by its parser" do
        new_instance = Adhearsion::Rayo::RayoNode.from_xml subject.to_rayo
        expect(new_instance).to be_instance_of described_class
        expect(new_instance.name).to eq('Originate')
        expect(new_instance.params).to eq({ 'Channel' => 'SIP/101test' })
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

  describe described_class::Complete::Success do
    let :stanza do
      <<-MESSAGE
<complete xmlns="urn:xmpp:rayo:ext:1">
  <success xmlns="urn:xmpp:rayo:asterisk:ami:complete:1">
    <message>Originate successfully queued</message>
    <text-body>Some thing happened</text-body>
    <attribute name="Channel" value="SIP/101-3f3f"/>
    <attribute name="State" value="Ring"/>
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

    describe '#message' do
      subject { super().message }
      it { is_expected.to eq("Originate successfully queued") }
    end

    describe '#text_body' do
      subject { super().text_body }
      it { is_expected.to eq('Some thing happened') }
    end

    describe '#headers' do
      subject { super().headers }
      it { is_expected.to eq({'Channel' => 'SIP/101-3f3f', 'State' => 'Ring'}) }
    end

    describe '#attributes' do
      subject { super().attributes }
      it { is_expected.to eq({'Channel' => 'SIP/101-3f3f', 'State' => 'Ring'}) }
    end # For BC

    describe "when setting options in initializer" do
      subject do
        described_class.new message: 'Originate successfully queued', text_body: 'Some thing happened', headers: {'Channel' => 'SIP/101-3f3f', 'State' => 'Ring'}
      end

      describe '#message' do
        subject { super().message }
        it { is_expected.to eq('Originate successfully queued') }
      end

      describe '#text_body' do
        subject { super().text_body }
        it { is_expected.to eq('Some thing happened') }
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
  end
end
