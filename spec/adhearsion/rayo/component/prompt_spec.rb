# encoding: utf-8

require 'spec_helper'

describe Adhearsion::Rayo::Component::Prompt do
  it 'registers itself' do
    expect(Adhearsion::Rayo::RayoNode.class_from_registration(:prompt, 'urn:xmpp:rayo:prompt:1')).to eq(described_class)
  end

  describe "when setting options in initializer" do
    let(:output)  { Adhearsion::Rayo::Component::Output.new :render_document => {content_type: 'text/uri-list', value: Adhearsion::URIList.new('http://example.com/hello.mp3')} }
    let(:input)   { Adhearsion::Rayo::Component::Input.new :mode => :voice }
    subject       { described_class.new output, input, :barge_in => true }

    describe '#output' do
      subject { super().output }
      it { is_expected.to eq(output) }
    end

    describe '#input' do
      subject { super().input }
      it { is_expected.to eq(input) }
    end

    describe '#barge_in' do
      subject { super().barge_in }
      it { is_expected.to be_truthy }
    end

    context "with barge-in unset" do
      subject { described_class.new output, input }

      describe '#barge_in' do
        subject { super().barge_in }
        it { is_expected.to be_nil }
      end
    end

    context "with options for sub-components" do
      subject { described_class.new({renderer: :foo}, {recognizer: :bar}) }

      describe '#output' do
        subject { super().output }
        it { is_expected.to eq(Adhearsion::Rayo::Component::Output.new(renderer: :foo)) }
      end

      describe '#input' do
        subject { super().input }
        it { is_expected.to eq(Adhearsion::Rayo::Component::Input.new(recognizer: :bar)) }
      end
    end

    describe "exporting to Rayo" do
      it "should export to XML that can be understood by its parser" do
        new_instance = Adhearsion::Rayo::RayoNode.from_xml subject.to_rayo
        expect(new_instance).to be_instance_of described_class
        expect(new_instance.output).to eq(output)
        expect(new_instance.input).to eq(input)
        expect(new_instance.barge_in).to be_truthy
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
    let :ssml do
      RubySpeech::SSML.draw do
        audio :src => 'http://foo.com/bar.mp3'
      end
    end

    let :stanza do
      <<-MESSAGE
<prompt xmlns="urn:xmpp:rayo:prompt:1" barge-in="true">
  <output xmlns="urn:xmpp:rayo:output:1" voice="allison">
    <document content-type="application/ssml+xml">
      <![CDATA[
        <speak version="1.0"
              xmlns="http://www.w3.org/2001/10/synthesis"
              xml:lang="en-US">
          <audio src="http://foo.com/bar.mp3"/>
        </speak>
      ]]>
    </document>
  </output>
  <input xmlns="urn:xmpp:rayo:input:1" mode="voice">
    <grammar content-type="application/grammar+custom">
      <![CDATA[ [5 DIGITS] ]]>
    </grammar>
  </input>
</prompt>
      MESSAGE
    end

    subject { Adhearsion::Rayo::RayoNode.from_xml parse_stanza(stanza).root, '9f00061', '1' }

    it { is_expected.to be_instance_of described_class }

    describe '#barge_in' do
      subject { super().barge_in }
      it { is_expected.to be_truthy }
    end

    describe '#output' do
      subject { super().output }
      it { is_expected.to eq(Adhearsion::Rayo::Component::Output.new(:voice => 'allison', :render_document => {:value => ssml})) }
    end

    describe '#input' do
      subject { super().input }
      it { is_expected.to eq(Adhearsion::Rayo::Component::Input.new(:mode => :voice, :grammar => {:value => '[5 DIGITS]', :content_type => 'application/grammar+custom'})) }
    end
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
          expect { command.stop! }.to raise_error(Adhearsion::Rayo::Component::InvalidActionError, "Cannot stop a Prompt that is new")
        end
      end
    end
  end
end
