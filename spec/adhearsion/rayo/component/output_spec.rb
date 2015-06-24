# encoding: utf-8

require 'spec_helper'

describe Adhearsion::Rayo::Component::Output do
  it 'registers itself' do
    expect(Adhearsion::Rayo::RayoNode.class_from_registration(:output, 'urn:xmpp:rayo:output:1')).to eq(described_class)
  end

  describe 'default values' do
    describe '#interrupt_on' do
      subject { super().interrupt_on }
      it { is_expected.to be nil }
    end

    describe '#start_offset' do
      subject { super().start_offset }
      it { is_expected.to be nil }
    end

    describe '#start_paused' do
      subject { super().start_paused }
      it { is_expected.to be nil }
    end

    describe '#repeat_interval' do
      subject { super().repeat_interval }
      it { is_expected.to be nil }
    end

    describe '#repeat_times' do
      subject { super().repeat_times }
      it { is_expected.to be nil }
    end

    describe '#max_time' do
      subject { super().max_time }
      it { is_expected.to be nil }
    end

    describe '#voice' do
      subject { super().voice }
      it { is_expected.to be nil }
    end

    describe '#renderer' do
      subject { super().renderer }
      it { is_expected.to be nil }
    end

    describe '#render_documents' do
      subject { super().render_documents }
      it { is_expected.to eq([]) }
    end
  end

  def ssml_doc(mode = :ordinal)
    RubySpeech::SSML.draw do
      say_as(:interpret_as => mode) { string '100' }
    end
  end

  describe "when setting options in initializer" do
    subject(:command) do
      described_class.new  :interrupt_on     => :voice,
                  :start_offset     => 2000,
                  :start_paused     => false,
                  :repeat_interval  => 2000,
                  :repeat_times     => 10,
                  :max_time         => 30000,
                  :voice            => 'allison',
                  :renderer         => 'swift',
                  :render_document  => {:value => ssml_doc},
                  :headers          => { 'Jump-Size' => '2', 'Kill-On-Barge-In' => 'false' }
    end

    describe '#interrupt_on' do
      subject { super().interrupt_on }
      it { is_expected.to eq(:voice) }
    end

    describe '#start_offset' do
      subject { super().start_offset }
      it { is_expected.to eq(2000) }
    end

    describe '#start_paused' do
      subject { super().start_paused }
      it { is_expected.to eq(false) }
    end

    describe '#repeat_interval' do
      subject { super().repeat_interval }
      it { is_expected.to eq(2000) }
    end

    describe '#repeat_times' do
      subject { super().repeat_times }
      it { is_expected.to eq(10) }
    end

    describe '#max_time' do
      subject { super().max_time }
      it { is_expected.to eq(30000) }
    end

    describe '#voice' do
      subject { super().voice }
      it { is_expected.to eq('allison') }
    end

    describe '#renderer' do
      subject { super().renderer }
      it { is_expected.to eq('swift') }
    end

    describe '#render_documents' do
      subject { super().render_documents }
      it { is_expected.to eq([described_class::Document.new(:value => ssml_doc)]) }
    end

    context "using #ssml=" do
      subject do
        described_class.new :ssml => ssml_doc
      end

      describe '#render_documents' do
        subject { super().render_documents }
        it { is_expected.to eq([described_class::Document.new(:value => ssml_doc)]) }
      end
    end

    context "with multiple documents" do
      subject do
        described_class.new :render_documents => [
          {:value => ssml_doc},
          {:value => ssml_doc(:cardinal)}
        ]
      end

      describe '#render_documents' do
        subject { super().render_documents }
        it { is_expected.to eq([
        described_class::Document.new(:value => ssml_doc),
        described_class::Document.new(:value => ssml_doc(:cardinal))
      ])}
      end
    end

    context "with a urilist" do
      subject do
        described_class.new render_document: {
          content_type: 'text/uri-list',
          value: Adhearsion::URIList.new('http://example.com/hello.mp3')
        }
      end

      describe '#render_documents' do
        subject { super().render_documents }
        it { is_expected.to eq([described_class::Document.new(content_type: 'text/uri-list', value: ['http://example.com/hello.mp3'])]) }
      end

      describe "exporting to Rayo" do
        it "should export to XML that can be understood by its parser" do
          new_instance = Adhearsion::Rayo::RayoNode.from_xml Nokogiri::XML(subject.to_rayo.to_xml, nil, nil, Nokogiri::XML::ParseOptions::NOBLANKS).root
          expect(new_instance.render_documents).to eq([described_class::Document.new(content_type: 'text/uri-list', value: ['http://example.com/hello.mp3'])])
        end
      end
    end

    context "with a nil document" do
      it "removes all documents" do
        subject.render_document = nil
        expect(subject.render_documents).to eq([])
      end
    end

    context "without any documents" do
      subject { described_class.new }

      describe '#render_documents' do
        subject { super().render_documents }
        it { is_expected.to eq([]) }
      end
    end

    describe '#headers' do
      subject { super().headers }
      it { is_expected.to eq({ 'Jump-Size' => '2', 'Kill-On-Barge-In' => 'false' }) }
    end

    describe "exporting to Rayo" do
      it "should export to XML that can be understood by its parser" do
        new_instance = Adhearsion::Rayo::RayoNode.from_xml Nokogiri::XML(subject.to_rayo.to_xml, nil, nil, Nokogiri::XML::ParseOptions::NOBLANKS).root
        expect(new_instance).to be_instance_of described_class
        expect(new_instance.interrupt_on).to eq(:voice)
        expect(new_instance.start_offset).to eq(2000)
        expect(new_instance.start_paused).to eq(false)
        expect(new_instance.repeat_interval).to eq(2000)
        expect(new_instance.repeat_times).to eq(10)
        expect(new_instance.max_time).to eq(30000)
        expect(new_instance.voice).to eq('allison')
        expect(new_instance.renderer).to eq('swift')
        expect(new_instance.render_documents).to eq([described_class::Document.new(:value => ssml_doc)])
        expect(new_instance.headers).to eq({ 'Jump-Size' => '2', 'Kill-On-Barge-In' => 'false' })
      end

      it "should wrap the document value in CDATA" do
        grammar_node = subject.to_rayo.at_xpath('ns:document', ns: described_class.registered_ns)
        expect(grammar_node.children.first).to be_a Nokogiri::XML::CDATA
      end

      it "should render to a parent node if supplied" do
        doc = Nokogiri::XML::Document.new
        parent = Nokogiri::XML::Node.new 'foo', doc
        doc.root = parent
        rayo_doc = subject.to_rayo(parent)
        expect(rayo_doc).to eq(parent)
      end

      context "with a string SSML document" do
        let(:ssml_string) { "<speak/>" }

        subject do
          described_class.new ssml: ssml_string
        end

        it "passes the string right through" do
          content = subject.to_rayo.at_xpath('//ns:output/ns:document/text()', ns: described_class.registered_ns).content
          expect(content).to eq(ssml_string)
        end
      end
    end
  end

  describe "from a stanza" do
    let :stanza do
      <<-MESSAGE
<output xmlns='urn:xmpp:rayo:output:1'
        interrupt-on='voice'
        start-offset='2000'
        start-paused='false'
        repeat-interval='2000'
        repeat-times='10'
        max-time='30000'
        voice='allison'
        renderer='swift'>
  <document content-type="application/ssml+xml">
    <![CDATA[
      <speak version="1.0"
            xmlns="http://www.w3.org/2001/10/synthesis"
            xml:lang="en-US">
        <say-as interpret-as="ordinal">100</say-as>
      </speak>
    ]]>
  </document>
  <document content-type="application/ssml+xml">
    <![CDATA[
      <speak version="1.0"
            xmlns="http://www.w3.org/2001/10/synthesis"
            xml:lang="en-US">
        <say-as interpret-as="ordinal">100</say-as>
      </speak>
    ]]>
  </document>
  <header xmlns='urn:xmpp:rayo:1' name="Jump-Size" value="2" />
  <header xmlns='urn:xmpp:rayo:1' name="Kill-On-Barge-In" value="false" />
</output>
      MESSAGE
    end

    subject { Adhearsion::Rayo::RayoNode.from_xml parse_stanza(stanza).root, '9f00061', '1' }

    it { is_expected.to be_instance_of described_class }

    describe '#interrupt_on' do
      subject { super().interrupt_on }
      it { is_expected.to eq(:voice) }
    end

    describe '#start_offset' do
      subject { super().start_offset }
      it { is_expected.to eq(2000) }
    end

    describe '#start_paused' do
      subject { super().start_paused }
      it { is_expected.to eq(false) }
    end

    describe '#repeat_interval' do
      subject { super().repeat_interval }
      it { is_expected.to eq(2000) }
    end

    describe '#repeat_times' do
      subject { super().repeat_times }
      it { is_expected.to eq(10) }
    end

    describe '#max_time' do
      subject { super().max_time }
      it { is_expected.to eq(30000) }
    end

    describe '#voice' do
      subject { super().voice }
      it { is_expected.to eq('allison') }
    end

    describe '#renderer' do
      subject { super().renderer }
      it { is_expected.to eq('swift') }
    end

    describe '#render_documents' do
      subject { super().render_documents }
      it { is_expected.to eq([described_class::Document.new(:value => ssml_doc), described_class::Document.new(:value => ssml_doc)]) }
    end

    context "with a urilist" do
      let :stanza do
        <<-MESSAGE
<output xmlns='urn:xmpp:rayo:output:1'>
  <document content-type="text/uri-list">
    <![CDATA[
      http://example.com/hello.mp3
      http://example.com/goodbye.mp3
    ]]>
  </document>
</output>
        MESSAGE
      end

      describe '#render_documents' do
        subject { super().render_documents }
        it { is_expected.to eq([described_class::Document.new(content_type: 'text/uri-list', value: ['http://example.com/hello.mp3', 'http://example.com/goodbye.mp3'])]) }
      end
    end

    describe '#headers' do
      subject { super().headers }
      it { is_expected.to eq({ 'Jump-Size' => '2', 'Kill-On-Barge-In' => 'false' }) }
    end
  end

  describe described_class::Document do
    describe "when not passing a content type" do
      subject { described_class.new :value => ssml_doc }

      describe '#content_type' do
        subject { super().content_type }
        it { is_expected.to eq('application/ssml+xml') }
      end
    end

    describe 'with an SSML document' do
      subject { described_class.new :value => ssml_doc, :content_type => 'application/ssml+xml' }

      describe '#content_type' do
        subject { super().content_type }
        it { is_expected.to eq('application/ssml+xml') }
      end

      describe '#value' do
        subject { super().value }
        it { is_expected.to eq(ssml_doc) }
      end

      describe "comparison" do
        let(:document2) { described_class.new :value => ssml_doc }
        let(:document3) { described_class.new :value => ssml_doc(:normal) }

        it { is_expected.to eq(document2) }
        it { is_expected.not_to eq(document3) }
      end
    end

    describe 'with a urilist' do
      subject { described_class.new content_type: 'text/uri-list', value: Adhearsion::URIList.new('http://example.com/hello.mp3', 'http://example.com/goodbye.mp3') }

      describe '#value' do
        subject { super().value }
        it { is_expected.to eq(Adhearsion::URIList.new('http://example.com/hello.mp3', 'http://example.com/goodbye.mp3')) }
      end

      describe "comparison" do
        let(:document2) { described_class.new content_type: 'text/uri-list', value: Adhearsion::URIList.new('http://example.com/hello.mp3', 'http://example.com/goodbye.mp3') }
        let(:document3) { described_class.new value: '<speak xmlns="http://www.w3.org/2001/10/synthesis" version="1.0" xml:lang="en-US"><say-as interpret-as="ordinal">100</say-as></speak>' }
        let(:document4) { described_class.new content_type: 'text/uri-list', value: Adhearsion::URIList.new('http://example.com/hello.mp3') }
        let(:document5) { described_class.new content_type: 'text/uri-list', value: Adhearsion::URIList.new('http://example.com/goodbye.mp3', 'http://example.com/hello.mp3') }

        it { is_expected.to eq(document2) }
        it { is_expected.not_to eq(document3) }
        it { is_expected.not_to eq(document4) }
        it { is_expected.not_to eq(document5) }
      end
    end

    describe 'with a document reference by URL' do
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
  end

  describe "actions" do
    let(:mock_client) { double 'Client' }
    let(:command) { described_class.new }

    before do
      command.component_id = 'abc123'
      command.target_call_id = '123abc'
      command.client = mock_client
    end

    describe '#pause_action' do
      subject { command.pause_action }

      describe '#to_xml' do
        subject { super().to_xml }
        it { is_expected.to eq('<pause xmlns="urn:xmpp:rayo:output:1"/>') }
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

    describe '#pause!' do
      describe "when the command is executing" do
        before do
          command.request!
          command.execute!
        end

        it "should send its command properly" do
          expect(mock_client).to receive(:execute_command).with(command.pause_action, :target_call_id => '123abc', :component_id => 'abc123').and_return true
          expect(command).to receive :paused!
          command.pause!
        end
      end

      describe "when the command is not executing" do
        it "should raise an error" do
          expect { command.pause! }.to raise_error(Adhearsion::Rayo::Component::InvalidActionError, "Cannot pause a Output that is not executing")
        end
      end
    end

    describe "#paused!" do
      before do
        command.request!
        command.execute!
        command.paused!
      end

      describe '#state_name' do
        subject { command.state_name }
        it { is_expected.to eq(:paused) }
      end

      it "should raise a StateMachine::InvalidTransition when received a second time" do
        expect { command.paused! }.to raise_error(StateMachine::InvalidTransition)
      end
    end

    describe '#resume_action' do
      subject { command.resume_action }

      describe '#to_xml' do
        subject { super().to_xml }
        it { is_expected.to eq('<resume xmlns="urn:xmpp:rayo:output:1"/>') }
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

    describe '#resume!' do
      describe "when the command is paused" do
        before do
          command.request!
          command.execute!
          command.paused!
        end

        it "should send its command properly" do
          expect(mock_client).to receive(:execute_command).with(command.resume_action, :target_call_id => '123abc', :component_id => 'abc123').and_return true
          expect(command).to receive :resumed!
          command.resume!
        end
      end

      describe "when the command is not paused" do
        it "should raise an error" do
          expect { command.resume! }.to raise_error(Adhearsion::Rayo::Component::InvalidActionError, "Cannot resume a Output that is not paused.")
        end
      end
    end

    describe "#resumed!" do
      before do
        command.request!
        command.execute!
        command.paused!
        command.resumed!
      end

      describe '#state_name' do
        subject { command.state_name }
        it { is_expected.to eq(:executing) }
      end

      it "should raise a StateMachine::InvalidTransition when received a second time" do
        expect { command.resumed! }.to raise_error(StateMachine::InvalidTransition)
      end
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
          expect { command.stop! }.to raise_error(Adhearsion::Rayo::Component::InvalidActionError, "Cannot stop a Output that is new")
        end
      end
    end # #stop!

    describe "seeking" do
      let(:seek_options) { {:direction => :forward, :amount => 1500} }

      describe '#seek_action' do
        subject { command.seek_action seek_options }

        describe '#to_xml' do
          subject { super().to_xml }
          it { is_expected.to eq(Nokogiri::XML('<seek xmlns="urn:xmpp:rayo:output:1" direction="forward" amount="1500"/>').root.to_xml) }
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

      describe '#seek!' do
        describe "when not seeking" do
          before do
            command.request!
            command.execute!
          end

          it "should send its command properly" do
            seek_action = command.seek_action seek_options
            allow(command).to receive(:seek_action).and_return seek_action
            expect(mock_client).to receive(:execute_command).with(seek_action, :target_call_id => '123abc', :component_id => 'abc123').and_return true
            expect(command).to receive :seeking!
            expect(command).to receive :stopped_seeking!
            command.seek! seek_options
            seek_action.request!
            seek_action.execute!
          end
        end

        describe "when seeking" do
          before { command.seeking! }

          it "should raise an error" do
            expect { command.seek! }.to raise_error(Adhearsion::Rayo::Component::InvalidActionError, "Cannot seek an Output that is already seeking.")
          end
        end
      end

      describe "#seeking!" do
        before do
          command.request!
          command.execute!
          command.seeking!
        end

        describe '#seek_status_name' do
          subject { command.seek_status_name }
          it { is_expected.to eq(:seeking) }
        end

        it "should raise a StateMachine::InvalidTransition when received a second time" do
          expect { command.seeking! }.to raise_error(StateMachine::InvalidTransition)
        end
      end

      describe "#stopped_seeking!" do
        before do
          command.request!
          command.execute!
          command.seeking!
          command.stopped_seeking!
        end

        describe '#seek_status_name' do
          subject { super().seek_status_name }
          it { is_expected.to eq(:not_seeking) }
        end

        it "should raise a StateMachine::InvalidTransition when received a second time" do
          expect { command.stopped_seeking! }.to raise_error(StateMachine::InvalidTransition)
        end
      end
    end

    describe "adjusting speed" do
      describe '#speed_up_action' do
        subject { command.speed_up_action }

        describe '#to_xml' do
          subject { super().to_xml }
          it { is_expected.to eq('<speed-up xmlns="urn:xmpp:rayo:output:1"/>') }
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

      describe '#speed_up!' do
        describe "when not altering speed" do
          before do
            command.request!
            command.execute!
          end

          it "should send its command properly" do
            speed_up_action = command.speed_up_action
            allow(command).to receive(:speed_up_action).and_return speed_up_action
            expect(mock_client).to receive(:execute_command).with(speed_up_action, :target_call_id => '123abc', :component_id => 'abc123').and_return true
            expect(command).to receive :speeding_up!
            expect(command).to receive :stopped_speeding!
            command.speed_up!
            speed_up_action.request!
            speed_up_action.execute!
          end
        end

        describe "when speeding up" do
          before { command.speeding_up! }

          it "should raise an error" do
            expect { command.speed_up! }.to raise_error(Adhearsion::Rayo::Component::InvalidActionError, "Cannot speed up an Output that is already speeding.")
          end
        end

        describe "when slowing down" do
          before { command.slowing_down! }

          it "should raise an error" do
            expect { command.speed_up! }.to raise_error(Adhearsion::Rayo::Component::InvalidActionError, "Cannot speed up an Output that is already speeding.")
          end
        end
      end

      describe "#speeding_up!" do
        before do
          command.request!
          command.execute!
          command.speeding_up!
        end

        describe '#speed_status_name' do
          subject { command.speed_status_name }
          it { is_expected.to eq(:speeding_up) }
        end

        it "should raise a StateMachine::InvalidTransition when received a second time" do
          expect { command.speeding_up! }.to raise_error(StateMachine::InvalidTransition)
        end
      end

      describe '#slow_down_action' do
        subject { command.slow_down_action }

        describe '#to_xml' do
          subject { super().to_xml }
          it { is_expected.to eq('<speed-down xmlns="urn:xmpp:rayo:output:1"/>') }
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

      describe '#slow_down!' do
        describe "when not altering speed" do
          before do
            command.request!
            command.execute!
          end

          it "should send its command properly" do
            slow_down_action = command.slow_down_action
            allow(command).to receive(:slow_down_action).and_return slow_down_action
            expect(mock_client).to receive(:execute_command).with(slow_down_action, :target_call_id => '123abc', :component_id => 'abc123').and_return true
            expect(command).to receive :slowing_down!
            expect(command).to receive :stopped_speeding!
            command.slow_down!
            slow_down_action.request!
            slow_down_action.execute!
          end
        end

        describe "when speeding up" do
          before { command.speeding_up! }

          it "should raise an error" do
            expect { command.slow_down! }.to raise_error(Adhearsion::Rayo::Component::InvalidActionError, "Cannot slow down an Output that is already speeding.")
          end
        end

        describe "when slowing down" do
          before { command.slowing_down! }

          it "should raise an error" do
            expect { command.slow_down! }.to raise_error(Adhearsion::Rayo::Component::InvalidActionError, "Cannot slow down an Output that is already speeding.")
          end
        end
      end

      describe "#slowing_down!" do
        before do
          command.request!
          command.execute!
          command.slowing_down!
        end

        describe '#speed_status_name' do
          subject { command.speed_status_name }
          it { is_expected.to eq(:slowing_down) }
        end

        it "should raise a StateMachine::InvalidTransition when received a second time" do
          expect { command.slowing_down! }.to raise_error(StateMachine::InvalidTransition)
        end
      end

      describe "#stopped_speeding!" do
        before do
          command.request!
          command.execute!
          command.speeding_up!
          command.stopped_speeding!
        end

        describe '#speed_status_name' do
          subject { command.speed_status_name }
          it { is_expected.to eq(:not_speeding) }
        end

        it "should raise a StateMachine::InvalidTransition when received a second time" do
          expect { command.stopped_speeding! }.to raise_error(StateMachine::InvalidTransition)
        end
      end
    end

    describe "adjusting volume" do
      describe '#volume_up_action' do
        subject { command.volume_up_action }

        describe '#to_xml' do
          subject { super().to_xml }
          it { is_expected.to eq('<volume-up xmlns="urn:xmpp:rayo:output:1"/>') }
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

      describe '#volume_up!' do
        describe "when not altering volume" do
          before do
            command.request!
            command.execute!
          end

          it "should send its command properly" do
            volume_up_action = command.volume_up_action
            allow(command).to receive(:volume_up_action).and_return volume_up_action
            expect(mock_client).to receive(:execute_command).with(volume_up_action, :target_call_id => '123abc', :component_id => 'abc123').and_return true
            expect(command).to receive :voluming_up!
            expect(command).to receive :stopped_voluming!
            command.volume_up!
            volume_up_action.request!
            volume_up_action.execute!
          end
        end

        describe "when voluming up" do
          before { command.voluming_up! }

          it "should raise an error" do
            expect { command.volume_up! }.to raise_error(Adhearsion::Rayo::Component::InvalidActionError, "Cannot volume up an Output that is already voluming.")
          end
        end

        describe "when voluming down" do
          before { command.voluming_down! }

          it "should raise an error" do
            expect { command.volume_up! }.to raise_error(Adhearsion::Rayo::Component::InvalidActionError, "Cannot volume up an Output that is already voluming.")
          end
        end
      end

      describe "#voluming_up!" do
        before do
          command.request!
          command.execute!
          command.voluming_up!
        end

        describe '#volume_status_name' do
          subject { command.volume_status_name }
          it { is_expected.to eq(:voluming_up) }
        end

        it "should raise a StateMachine::InvalidTransition when received a second time" do
          expect { command.voluming_up! }.to raise_error(StateMachine::InvalidTransition)
        end
      end

      describe '#volume_down_action' do
        subject { command.volume_down_action }

        describe '#to_xml' do
          subject { super().to_xml }
          it { is_expected.to eq('<volume-down xmlns="urn:xmpp:rayo:output:1"/>') }
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

      describe '#volume_down!' do
        describe "when not altering volume" do
          before do
            command.request!
            command.execute!
          end

          it "should send its command properly" do
            volume_down_action = command.volume_down_action
            allow(command).to receive(:volume_down_action).and_return volume_down_action
            expect(mock_client).to receive(:execute_command).with(volume_down_action, :target_call_id => '123abc', :component_id => 'abc123').and_return true
            expect(command).to receive :voluming_down!
            expect(command).to receive :stopped_voluming!
            command.volume_down!
            volume_down_action.request!
            volume_down_action.execute!
          end
        end

        describe "when voluming up" do
          before { command.voluming_up! }

          it "should raise an error" do
            expect { command.volume_down! }.to raise_error(Adhearsion::Rayo::Component::InvalidActionError, "Cannot volume down an Output that is already voluming.")
          end
        end

        describe "when voluming down" do
          before { command.voluming_down! }

          it "should raise an error" do
            expect { command.volume_down! }.to raise_error(Adhearsion::Rayo::Component::InvalidActionError, "Cannot volume down an Output that is already voluming.")
          end
        end
      end

      describe "#voluming_down!" do
        before do
          command.request!
          command.execute!
          command.voluming_down!
        end

        describe '#volume_status_name' do
          subject { command.volume_status_name }
          it { is_expected.to eq(:voluming_down) }
        end

        it "should raise a StateMachine::InvalidTransition when received a second time" do
          expect { command.voluming_down! }.to raise_error(StateMachine::InvalidTransition)
        end
      end

      describe "#stopped_voluming!" do
        before do
          command.request!
          command.execute!
          command.voluming_up!
          command.stopped_voluming!
        end

        describe '#volume_status_name' do
          subject { command.volume_status_name }
          it { is_expected.to eq(:not_voluming) }
        end

        it "should raise a StateMachine::InvalidTransition when received a second time" do
          expect { command.stopped_voluming! }.to raise_error(StateMachine::InvalidTransition)
        end
      end
    end
  end
end

{
  Adhearsion::Rayo::Component::Output::Complete::Finish => :finish,
  Adhearsion::Rayo::Component::Output::Complete::MaxTime => :'max-time',
}.each do |klass, element_name|
  describe klass do
    let :stanza do
      <<-MESSAGE
<complete xmlns='urn:xmpp:rayo:ext:1'>
<#{element_name} xmlns='urn:xmpp:rayo:output:complete:1' />
</complete>
      MESSAGE
    end

    subject { Adhearsion::Rayo::RayoNode.from_xml(parse_stanza(stanza).root).reason }

    it { is_expected.to be_instance_of klass }

    describe '#name' do
      subject { super().name }
      it { is_expected.to eq(element_name) }
    end
  end
end
