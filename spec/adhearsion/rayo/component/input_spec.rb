# encoding: utf-8

require 'spec_helper'

describe Adhearsion::Rayo::Component::Input do
  it 'registers itself' do
    expect(Adhearsion::Rayo::RayoNode.class_from_registration(:input, 'urn:xmpp:rayo:input:1')).to eq(described_class)
  end

  describe "when setting options in initializer" do
    subject do
      described_class.new grammar: {value: '[5 DIGITS]', content_type: 'application/grammar+custom'},
                :mode                 => :voice,
                :terminator           => '#',
                :max_silence          => 1000,
                :recognizer           => 'default',
                :language             => 'en-US',
                :initial_timeout      => 2000,
                :inter_digit_timeout  => 2000,
                :recognition_timeout  => 0,
                :sensitivity          => 0.5,
                :min_confidence       => 0.5,
                :headers              => { 'Confidence-Threshold' => '0.5', 'Sensitivity-Level' => '0.2' }
    end

    describe '#grammars' do
      subject { super().grammars }
      it { is_expected.to eq([described_class::Grammar.new(:value => '[5 DIGITS]', :content_type => 'application/grammar+custom')]) }
    end

    describe '#mode' do
      subject { super().mode }
      it { is_expected.to eq(:voice) }
    end

    describe '#terminator' do
      subject { super().terminator }
      it { is_expected.to eq('#') }
    end

    describe '#max_silence' do
      subject { super().max_silence }
      it { is_expected.to eq(1000) }
    end

    describe '#recognizer' do
      subject { super().recognizer }
      it { is_expected.to eq('default') }
    end

    describe '#language' do
      subject { super().language }
      it { is_expected.to eq('en-US') }
    end

    describe '#initial_timeout' do
      subject { super().initial_timeout }
      it { is_expected.to eq(2000) }
    end

    describe '#inter_digit_timeout' do
      subject { super().inter_digit_timeout }
      it { is_expected.to eq(2000) }
    end

    describe '#recognition_timeout' do
      subject { super().recognition_timeout }
      it { is_expected.to eq(0) }
    end

    describe '#sensitivity' do
      subject { super().sensitivity }
      it { is_expected.to eq(0.5) }
    end

    describe '#min_confidence' do
      subject { super().min_confidence }
      it { is_expected.to eq(0.5) }
    end

    context "with multiple grammars" do
      subject do
        described_class.new :grammars => [
          {:value => '[5 DIGITS]', :content_type => 'application/grammar+custom'},
          {:value => '[10 DIGITS]', :content_type => 'application/grammar+custom'}
        ]
      end

      describe '#grammars' do
        subject { super().grammars }
        it { is_expected.to eq([
        described_class::Grammar.new(:value => '[5 DIGITS]', :content_type => 'application/grammar+custom'),
        described_class::Grammar.new(:value => '[10 DIGITS]', :content_type => 'application/grammar+custom')
      ])}
      end
    end

    context "with a nil grammar" do
      it "removes all grammars" do
        subject.grammar = nil
        expect(subject.grammars).to eq([])
      end
    end

    context "without any grammars" do
      subject { described_class.new }

      describe '#grammars' do
        subject { super().grammars }
        it { is_expected.to eq([]) }
      end
    end

    describe '#headers' do
      subject { super().headers }
      it { is_expected.to eq({ 'Confidence-Threshold' => '0.5', 'Sensitivity-Level' => '0.2' }) }
    end

    describe "exporting to Rayo" do
      it "should export to XML that can be understood by its parser" do
        new_instance = Adhearsion::Rayo::RayoNode.from_xml subject.to_rayo
        expect(new_instance).to be_instance_of described_class
        expect(new_instance.grammars).to eq([described_class::Grammar.new(value: '[5 DIGITS]', content_type: 'application/grammar+custom')])
        expect(new_instance.mode).to eq(:voice)
        expect(new_instance.terminator).to eq('#')
        expect(new_instance.max_silence).to eq(1000)
        expect(new_instance.recognizer).to eq('default')
        expect(new_instance.language).to eq('en-US')
        expect(new_instance.initial_timeout).to eq(2000)
        expect(new_instance.inter_digit_timeout).to eq(2000)
        expect(new_instance.recognition_timeout).to eq(0)
        expect(new_instance.sensitivity).to eq(0.5)
        expect(new_instance.min_confidence).to eq(0.5)
        expect(new_instance.headers).to eq({ 'Confidence-Threshold' => '0.5', 'Sensitivity-Level' => '0.2' })
      end

      it "should wrap the grammar value in CDATA" do
        grammar_node = subject.to_rayo.at_xpath('ns:grammar', ns: described_class.registered_ns)
        expect(grammar_node.children.first).to be_a Nokogiri::XML::CDATA
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

  describe "from a stanza" do
    let :stanza do
      <<-MESSAGE
<input xmlns="urn:xmpp:rayo:input:1"
       mode="voice"
       terminator="#"
       max-silence="1000"
       recognizer="default"
       language="en-US"
       initial-timeout="2000"
       inter-digit-timeout="2000"
       recognition-timeout="0"
       sensitivity="0.5"
       min-confidence="0.5">
  <grammar content-type="application/grammar+custom">
    <![CDATA[ [5 DIGITS] ]]>
  </grammar>
  <grammar content-type="application/grammar+custom">
    <![CDATA[ [10 DIGITS] ]]>
  </grammar>
  <header xmlns='urn:xmpp:rayo:1' name="Confidence-Threshold" value="0.5" />
  <header xmlns='urn:xmpp:rayo:1' name="Sensitivity-Level" value="0.2" />
</input>
      MESSAGE
    end

    subject { Adhearsion::Rayo::RayoNode.from_xml parse_stanza(stanza).root, '9f00061', '1' }

    it { is_expected.to be_instance_of described_class }

    describe '#grammars' do
      subject { super().grammars }
      it { is_expected.to eq([described_class::Grammar.new(:value => '[5 DIGITS]', :content_type => 'application/grammar+custom'), described_class::Grammar.new(:value => '[10 DIGITS]', :content_type => 'application/grammar+custom')]) }
    end

    describe '#mode' do
      subject { super().mode }
      it { is_expected.to eq(:voice) }
    end

    describe '#terminator' do
      subject { super().terminator }
      it { is_expected.to eq('#') }
    end

    describe '#max_silence' do
      subject { super().max_silence }
      it { is_expected.to eq(1000) }
    end

    describe '#recognizer' do
      subject { super().recognizer }
      it { is_expected.to eq('default') }
    end

    describe '#language' do
      subject { super().language }
      it { is_expected.to eq('en-US') }
    end

    describe '#initial_timeout' do
      subject { super().initial_timeout }
      it { is_expected.to eq(2000) }
    end

    describe '#inter_digit_timeout' do
      subject { super().inter_digit_timeout }
      it { is_expected.to eq(2000) }
    end

    describe '#recognition_timeout' do
      subject { super().recognition_timeout }
      it { is_expected.to eq(0) }
    end

    describe '#sensitivity' do
      subject { super().sensitivity }
      it { is_expected.to eq(0.5) }
    end

    describe '#min_confidence' do
      subject { super().min_confidence }
      it { is_expected.to eq(0.5) }
    end

    context "without any grammars" do
      let(:stanza) { '<input xmlns="urn:xmpp:rayo:input:1"/>' }

      describe '#grammars' do
        subject { super().grammars }
        it { is_expected.to eq([]) }
      end
    end

    describe '#headers' do
      subject { super().headers }
      it { is_expected.to eq({ 'Confidence-Threshold' => '0.5', 'Sensitivity-Level' => '0.2' }) }
    end
  end

  def grxml_doc(mode = :dtmf)
    RubySpeech::GRXML.draw :mode => mode.to_s, :root => 'digits' do
      rule id: 'digits' do
        one_of do
          0.upto(1) { |d| item { d.to_s } }
        end
      end
    end
  end

  describe described_class::Grammar do
    describe "when not passing a content type" do
      subject { described_class.new :value => grxml_doc }

      describe '#content_type' do
        subject { super().content_type }
        it { is_expected.to eq('application/srgs+xml') }
      end
    end

    describe 'with a GRXML grammar' do
      subject { described_class.new :value => grxml_doc, :content_type => 'application/srgs+xml' }

      describe '#content_type' do
        subject { super().content_type }
        it { is_expected.to eq('application/srgs+xml') }
      end

      describe '#value' do
        subject { super().value }
        it { is_expected.to eq(grxml_doc) }
      end

      describe "comparison" do
        let(:grammar2) { described_class.new :value => grxml_doc }
        let(:grammar3) { described_class.new :value => grxml_doc(:voice) }

        it { is_expected.to eq(grammar2) }
        it { is_expected.not_to eq(grammar3) }
      end

      it "has children nested inside" do
        expect(subject.to_rayo.children.first).to be_a Nokogiri::XML::CDATA
      end
    end

    describe 'with a grammar reference by URL' do
      let(:url) { 'http://foo.com/bar.grxml' }

      subject { described_class.new :url => url }

      describe '#url' do
        subject { super().url }
        it { is_expected.to eq(url) }
      end

      describe '#content_type' do
        subject { super().content_type }
        it { is_expected.to be nil}
      end

      describe "comparison" do
        it "should be the same with the same url" do
          expect(described_class.new(:url => url)).to eq(described_class.new(:url => url))
        end

        it "should be different with a different url" do
          expect(described_class.new(:url => url)).not_to eq(described_class.new(:url => 'http://doo.com/dah'))
        end
      end
    end

    describe "with a CPA grammar" do
      subject { described_class.new url: "urn:xmpp:rayo:cpa:beep:1" }

      it "has no children" do
        expect(subject.to_rayo.children.count).to eq(0)
      end
    end
  end

  describe "actions" do
    let(:mock_client) { double 'Client' }
    let(:command) { described_class.new grammar: {value: '[5 DIGITS]', content_type: 'application/grammar+custom'} }

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
          expect { command.stop! }.to raise_error(Adhearsion::Rayo::Component::InvalidActionError, "Cannot stop a Input that is new")
        end
      end
    end
  end

  describe described_class::Complete::Match do
    let :nlsml_string do
      '''
<result xmlns="http://www.ietf.org/xml/ns/mrcpv2" grammar="http://flight">
  <interpretation confidence="0.60">
    <input mode="voice">I want to go to Pittsburgh</input>
    <instance>
      <airline>
        <to_city>Pittsburgh</to_city>
      </airline>
    </instance>
  </interpretation>
  <interpretation confidence="0.40">
    <input>I want to go to Stockholm</input>
    <instance>
      <airline>
        <to_city>Stockholm</to_city>
      </airline>
    </instance>
  </interpretation>
</result>
      '''
    end

    let :stanza do
      <<-MESSAGE
<complete xmlns='urn:xmpp:rayo:ext:1'>
  <match xmlns="urn:xmpp:rayo:input:complete:1" content-type="application/nlsml+xml">
    <![CDATA[#{nlsml_string}]]>
  </match>
</complete>
      MESSAGE
    end

    let :expected_nlsml do
      RubySpeech.parse nlsml_string
    end

    subject { Adhearsion::Rayo::RayoNode.from_xml(parse_stanza(stanza).root).reason }

    it { is_expected.to be_instance_of described_class }

    describe '#name' do
      subject { super().name }
      it { is_expected.to eq(:match) }
    end

    describe '#content_type' do
      subject { super().content_type }
      it { is_expected.to eq('application/nlsml+xml') }
    end

    describe '#nlsml' do
      subject { super().nlsml }
      it { is_expected.to eq(expected_nlsml) }
    end

    describe '#mode' do
      subject { super().mode }
      it { is_expected.to eq(:voice) }
    end

    describe '#confidence' do
      subject { super().confidence }
      it { is_expected.to eq(0.6) }
    end

    describe '#interpretation' do
      subject { super().interpretation }
      it { is_expected.to eq({ airline: { to_city: 'Pittsburgh' } }) }
    end

    describe '#utterance' do
      subject { super().utterance }
      it { is_expected.to eq('I want to go to Pittsburgh') }
    end

    describe "when creating from an NLSML document" do
      subject do
        described_class.new :nlsml => expected_nlsml
      end

      describe '#content_type' do
        subject { super().content_type }
        it { is_expected.to eq('application/nlsml+xml') }
      end

      describe '#nlsml' do
        subject { super().nlsml }
        it { is_expected.to eq(expected_nlsml) }
      end

      describe '#mode' do
        subject { super().mode }
        it { is_expected.to eq(:voice) }
      end

      describe '#confidence' do
        subject { super().confidence }
        it { is_expected.to eq(0.6) }
      end

      describe '#interpretation' do
        subject { super().interpretation }
        it { is_expected.to eq({ airline: { to_city: 'Pittsburgh' } }) }
      end

      describe '#utterance' do
        subject { super().utterance }
        it { is_expected.to eq('I want to go to Pittsburgh') }
      end
    end

    context "when not enclosed in CDATA, but escaped" do
      let :stanza do
        <<-MESSAGE
<complete xmlns='urn:xmpp:rayo:ext:1'>
  <match xmlns="urn:xmpp:rayo:input:complete:1" content-type="application/nlsml+xml">
    &lt;result xmlns=&quot;http://www.ietf.org/xml/ns/mrcpv2&quot; grammar=&quot;http://flight&quot;/&gt;
  </match>
</complete>
        MESSAGE
      end

      it "should parse the NLSML correctly" do
        expect(subject.nlsml.grammar).to eq("http://flight")
      end
    end

    context "when nested directly" do
      let :stanza do
        <<-MESSAGE
<complete xmlns='urn:xmpp:rayo:ext:1'>
  <match xmlns="urn:xmpp:rayo:input:complete:1" content-type="application/nlsml+xml">
    #{nlsml_string}
  </match>
</complete>
        MESSAGE
      end

      it "should parse the NLSML correctly" do
        expect(subject.nlsml.grammar).to eq("http://flight")
      end
    end

    describe "comparison" do
      context "with the same nlsml" do
        it "should be equal" do
          expect(subject).to eq(Adhearsion::Rayo::RayoNode.from_xml(parse_stanza(stanza).root).reason)
        end
      end

      context "with different nlsml" do
        let :other_stanza do
          <<-MESSAGE
<complete xmlns='urn:xmpp:rayo:ext:1'>
  <match xmlns="urn:xmpp:rayo:input:complete:1">
    <![CDATA[<result xmlns="http://www.ietf.org/xml/ns/mrcpv2" grammar="http://flight"/>]]>
  </match>
</complete>
          MESSAGE
        end

        it "should not be equal" do
          expect(subject).not_to eq(Adhearsion::Rayo::RayoNode.from_xml(parse_stanza(other_stanza).root).reason)
        end
      end
    end
  end

  describe described_class::Complete::NoMatch do
    let :stanza do
      <<-MESSAGE
<complete xmlns='urn:xmpp:rayo:ext:1'>
  <nomatch xmlns='urn:xmpp:rayo:input:complete:1' />
</complete>
      MESSAGE
    end

    subject { Adhearsion::Rayo::RayoNode.from_xml(parse_stanza(stanza).root).reason }

    it { is_expected.to be_instance_of described_class }

    describe '#name' do
      subject { super().name }
      it { is_expected.to eq(:nomatch) }
    end
  end

  describe described_class::Complete::NoInput do
    let :stanza do
      <<-MESSAGE
<complete xmlns='urn:xmpp:rayo:ext:1'>
  <noinput xmlns='urn:xmpp:rayo:input:complete:1' />
</complete>
      MESSAGE
    end

    subject { Adhearsion::Rayo::RayoNode.from_xml(parse_stanza(stanza).root).reason }

    it { is_expected.to be_instance_of described_class }

    describe '#name' do
      subject { super().name }
      it { is_expected.to eq(:noinput) }
    end
  end

  describe described_class::Signal do
    let :stanza do
      <<-MESSAGE
<signal xmlns="urn:xmpp:rayo:cpa:1" type="urn:xmpp:rayo:cpa:beep:1" duration="1000" value="8000"/>
      MESSAGE
    end

    subject { Adhearsion::Rayo::RayoNode.from_xml(parse_stanza(stanza).root) }

    it { is_expected.to be_instance_of described_class }
    it { is_expected.to be_a Adhearsion::Event }

    describe '#name' do
      subject { super().name }
      it { is_expected.to eq(:signal) }
    end

    describe '#type' do
      subject { super().type }
      it { is_expected.to eq('urn:xmpp:rayo:cpa:beep:1') }
    end

    describe '#duration' do
      subject { super().duration }
      it { is_expected.to eq(1000) }
    end

    describe '#value' do
      subject { super().value }
      it { is_expected.to eq('8000') }
    end

    describe "when creating from options" do
      subject do
        described_class.new type: 'urn:xmpp:rayo:cpa:beep:1', duration: 1000, value: '8000'
      end

      describe '#name' do
        subject { super().name }
        it { is_expected.to eq(:signal) }
      end

      describe '#type' do
        subject { super().type }
        it { is_expected.to eq('urn:xmpp:rayo:cpa:beep:1') }
      end

      describe '#duration' do
        subject { super().duration }
        it { is_expected.to eq(1000) }
      end

      describe '#value' do
        subject { super().value }
        it { is_expected.to eq('8000') }
      end
    end

    context "when in a complete event" do
      let :stanza do
        <<-MESSAGE
<complete xmlns='urn:xmpp:rayo:ext:1'>
  <signal xmlns="urn:xmpp:rayo:cpa:1" type="urn:xmpp:rayo:cpa:beep:1" duration="1000" value="8000"/>
</complete>
        MESSAGE
      end

      subject { Adhearsion::Rayo::RayoNode.from_xml(parse_stanza(stanza).root).reason }

      it { is_expected.to be_instance_of described_class }

      describe '#name' do
        subject { super().name }
        it { is_expected.to eq(:signal) }
      end

      describe '#type' do
        subject { super().type }
        it { is_expected.to eq('urn:xmpp:rayo:cpa:beep:1') }
      end

      describe '#duration' do
        subject { super().duration }
        it { is_expected.to eq(1000) }
      end

      describe '#value' do
        subject { super().value }
        it { is_expected.to eq('8000') }
      end
    end

    describe "comparison" do
      context "with the same options" do
        it "should be equal" do
          expect(subject).to eq(Adhearsion::Rayo::RayoNode.from_xml(parse_stanza(stanza).root))
        end
      end

      context "with different type" do
        let(:other_stanza) { '<signal xmlns="urn:xmpp:rayo:cpa:1" type="urn:xmpp:rayo:cpa:ring:1" duration="1000" value="8000"/>' }

        it "should not be equal" do
          expect(subject).not_to eq(Adhearsion::Rayo::RayoNode.from_xml(parse_stanza(other_stanza).root))
        end
      end

      context "with different duration" do
        let(:other_stanza) { '<signal xmlns="urn:xmpp:rayo:cpa:1" type="urn:xmpp:rayo:cpa:beep:1" duration="100" value="8000"/>' }

        it "should not be equal" do
          expect(subject).not_to eq(Adhearsion::Rayo::RayoNode.from_xml(parse_stanza(other_stanza).root))
        end
      end

      context "with different value" do
        let(:other_stanza) { '<signal xmlns="urn:xmpp:rayo:cpa:1" type="urn:xmpp:rayo:cpa:beep:1" duration="1000" value="7000"/>' }

        it "should not be equal" do
          expect(subject).not_to eq(Adhearsion::Rayo::RayoNode.from_xml(parse_stanza(other_stanza).root))
        end
      end
    end
  end
end
