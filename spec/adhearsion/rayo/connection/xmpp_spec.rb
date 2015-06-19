# encoding: utf-8

require 'spec_helper'

describe Adhearsion::Rayo::Connection::XMPP do
  let(:options)     { { :root_domain => 'rayo.net' } }
  let(:connection)  { described_class.new({:username => '1@app.rayo.net', :password => 1}.merge(options)) }

  let(:mock_event_handler) { double('Event Handler').as_null_object }

  before do
    connection.event_handler = mock_event_handler
  end

  subject { connection }

  describe "rayo domains" do
    before { stub_uuids 'randomcallid' }

    context "with no domains specified, and a JID of 1@app.rayo.net" do
      let(:options) { { :username => '1@app.rayo.net' } }

      describe '#root_domain' do
        subject { super().root_domain }
        it { is_expected.to eq('app.rayo.net') }
      end

      describe '#new_call_uri' do
        it "should return an appropriate random call URI" do
          expect(subject.new_call_uri).to eq('xmpp:randomcallid@app.rayo.net')
        end
      end
    end

    context "with only a rayo domain set" do
      let(:options) { { :rayo_domain => 'rayo.org' } }

      describe '#root_domain' do
        subject { super().root_domain }
        it { is_expected.to eq('rayo.org') }
      end

      describe '#new_call_uri' do
        it "should return an appropriate random call URI" do
          expect(subject.new_call_uri).to eq('xmpp:randomcallid@rayo.org')
        end
      end
    end

    context "with only a root domain set" do
      let(:options) { { :root_domain => 'rayo.org' } }

      describe '#root_domain' do
        subject { super().root_domain }
        it { is_expected.to eq('rayo.org') }
      end

      describe '#new_call_uri' do
        it "should return an appropriate random call URI" do
          expect(subject.new_call_uri).to eq('xmpp:randomcallid@rayo.org')
        end
      end
    end
  end

  it 'should require a username and password to be passed in the options' do
    expect { described_class.new :password => 1 }.to raise_error ArgumentError
    expect { described_class.new :username => 1 }.to raise_error ArgumentError
  end

  it 'should properly set the Blather logger' do
    connection = described_class.new :username => '1@call.rayo.net', :password => 1
    expect(Blather.logger).to be connection.logger
  end

  it "looking up original command by command ID" do
    skip
    offer = Adhearsion::Event::Offer.new
    offer.call_id = '9f00061'
    offer.to = 'sip:whatever@127.0.0.1'
    output = <<-MSG
<output xmlns='urn:xmpp:rayo:output:1'>
  <audio url='http://acme.com/greeting.mp3'>
  Thanks for calling ACME company
  </audio>
  <audio url='http://acme.com/package-shipped.mp3'>
  Your package was shipped on
  </audio>
  <say-as interpret-as='date'>12/01/2011</say-as>
</output>
    MSG
    output = RayoNode.import parse_stanza(output).root
    expect(connection).to receive(:write_to_stream).once.and_return true
    iq = Blather::Stanza::Iq.new :set, '9f00061@call.rayo.net'
    expect(connection).to receive(:create_iq).and_return iq

    write_thread = Thread.new do
      connection.write offer.call_id, output
    end

    result = import_stanza <<-MSG
<iq type='result' from='16577@app.rayo.net/1' to='9f00061@call.rayo.net/1' id='#{iq.id}'>
  <ref id='fgh4590' xmlns='urn:xmpp:rayo:1' />
</iq>
    MSG

    sleep 0.5 # Block so there's enough time for the write thread to get to the point where it's waiting on an IQ

    connection.__send__ :handle_iq_result, result

    write_thread.join

    expect(output.state_name).to eq(:executing)

    expect(connection.original_component_from_id('fgh4590')).to eq(output)

    example_complete = import_stanza <<-MSG
<presence to='16577@app.rayo.net/1' from='9f00061@call.rayo.net/fgh4590'>
  <complete xmlns='urn:xmpp:rayo:ext:1'>
  <success xmlns='urn:xmpp:rayo:output:complete:1' />
  </complete>
</presence>
    MSG

    connection.__send__ :handle_presence, example_complete
    expect(output.complete_event(0.5).source).to eq(output)

    expect(output.component_id).to eq('fgh4590')
  end

  let(:client) { connection.send :client }
  before { allow(client).to receive :write }

  describe "sending a command" do
    let(:command) { Adhearsion::Rayo::Command::Answer.new request_id: 'fooobarrr', target_call_id: 'foo', domain: 'bar.com' }

    it "should write an IQ containing the command to the socket" do
      expect(client).to receive(:write).once.with(satisfy { |stanza|
        expect(stanza).to be_a Blather::Stanza::Iq
        expect(stanza.to).to eq('foo@bar.com')
        expect(stanza.type).to eq(:set)
      })
      connection.write command
    end

    it "should put the command in a requested state" do
      connection.write command
      expect(command).to be_requested
    end

    it "should use the command's request_id as the ID id" do
      expect(client).to receive(:write).once.with(satisfy { |stanza|
        expect(stanza.id).to eq('fooobarrr')
      })
      connection.write command
    end
  end

  it 'should send a "Chat" presence when ready' do
    expect(client).to receive(:write).once.with(satisfy { |stanza|
      expect(stanza.to).to eq('rayo.net')
      expect(stanza).to be_a Blather::Stanza::Presence::Status
      expect(stanza.chat?).to be true
    })
    connection.ready!
  end

  it 'should send a "Do Not Disturb" presence when not_ready' do
    expect(client).to receive(:write).once.with(satisfy { |stanza|
      expect(stanza.to).to eq('rayo.net')
      expect(stanza).to be_a Blather::Stanza::Presence::Status
      expect(stanza.dnd?).to be true
    })
    connection.not_ready!
  end

  describe '#send_message' do
    it 'should send a "normal" message to the given user and domain' do
      expect(client).to receive(:write).once.with(satisfy { |stanza|
        expect(stanza.to).to eq('someone@example.org')
        expect(stanza).to be_a Blather::Stanza::Message
        expect(stanza.type).to eq(:normal)
        expect(stanza.body).to eq('Hello World!')
        expect(stanza.subject).to be_nil
      })
      connection.send_message 'someone', 'example.org', 'Hello World!'
    end

    it 'should default to the root domain' do
      expect(client).to receive(:write).once.with(satisfy { |stanza|
        expect(stanza.to).to eq('someone@rayo.net')
      })
      connection.send_message "someone", nil, nil
    end

    it 'should send a message with the given subject' do
      expect(client).to receive(:write).once.with(satisfy { |stanza|
        expect(stanza.subject).to eq("Important Message")
      })
      connection.send_message nil, nil, nil, :subject => "Important Message"
    end
  end

  describe '#handle_presence' do
    let :complete_xml do
      <<-MSG
<presence to='16577@app.rayo.net/1' from='9f00061@call.rayo.net/fgh4590'>
  <complete xmlns='urn:xmpp:rayo:ext:1'>
  <success xmlns='urn:xmpp:rayo:output:complete:1' />
  </complete>
</presence>
      MSG
    end

    let(:example_complete) { import_stanza complete_xml }

    it { expect(example_complete).to be_a Blather::Stanza::Presence }

    describe "accessing the rayo node for a presence stanza" do
      it "should import the rayo node" do
        expect(example_complete.rayo_node).to be_a Adhearsion::Event::Complete
      end

      it "should be memoized" do
        expect(example_complete.rayo_node).to be example_complete.rayo_node
      end
    end

    describe "presence received" do
      let(:handle_presence) { connection.__send__ :handle_presence, example_event }

      describe "from an offer" do
        let :offer_xml do
          <<-MSG
    <presence to='16577@app.rayo.net/1' from='9f00061@call.rayo.net'>
      <offer xmlns="urn:xmpp:rayo:1" to="sip:whatever@127.0.0.1" from="sip:ylcaomxb@192.168.1.9">
      <header name="Max-Forwards" value="70"/>
      <header name="Content-Length" value="367"/>
      </offer>
    </presence>
          MSG
        end

        before do
          @now = DateTime.now
          allow(DateTime).to receive_messages now: @now
        end

        let(:example_event) { import_stanza offer_xml }

        it { expect(example_event).to be_a Blather::Stanza::Presence }

        it 'should call the event handler with the event' do
          expect(mock_event_handler).to receive(:call).once.with(satisfy { |event|
            expect(event).to be_instance_of Adhearsion::Event::Offer
            expect(event.target_call_id).to eq('9f00061')
            expect(event.source_uri).to eq('xmpp:9f00061@call.rayo.net')
            expect(event.domain).to eq('call.rayo.net')
            expect(event.transport).to eq('xmpp')
            expect(event.timestamp).to eq(@now)
          })
          handle_presence
        end

        context "with a delayed delivery timestamp" do
          let :offer_xml do
            <<-MSG
      <presence to='16577@app.rayo.net/1' from='9f00061@call.rayo.net'>
        <offer xmlns="urn:xmpp:rayo:1" to="sip:whatever@127.0.0.1" from="sip:ylcaomxb@192.168.1.9"/>
        <delay xmlns='urn:xmpp:delay' stamp='2002-09-10T23:08:25Z'/>
      </presence>
            MSG
          end

          it 'should stamp that time on the rayo event' do
            expect(mock_event_handler).to receive(:call).once.with(satisfy { |event|
              expect(event.timestamp).to eq(DateTime.new(2002, 9, 10, 23, 8, 25, 0))
            })
            handle_presence
          end
        end
      end

      describe "from something that's not a real event" do
        let :irrelevant_xml do
          <<-MSG
<presence to='16577@app.rayo.net/1' from='9f00061@call.rayo.net/fgh4590'>
  <foo bar="baz"/>
</presence>
          MSG
        end

        let(:example_event) { import_stanza irrelevant_xml }

        it 'should not be considered to be a rayo event' do
          expect(example_event.rayo_event?).to be_falsey
        end

        it 'should have a nil rayo_node' do
          expect(example_event.rayo_node).to be_nil
        end

        it 'should not handle the event' do
          expect(mock_event_handler).to receive(:call).never
          expect { handle_presence }.to throw_symbol(:pass)
        end
      end
    end
  end

  describe "#handle_error" do
    let(:call_id)       { "f6d437f4-1e18-457b-99f8-b5d853f50347" }
    let(:component_id)  { 'abc123' }
    let :error_xml do
      <<-MSG
<iq type="error" id="blather000e" from="f6d437f4-1e18-457b-99f8-b5d853f50347@call.rayo.net/abc123" to="usera@rayo.net">
  <output xmlns="urn:xmpp:rayo:output:1"/>
  <error type="cancel">
    <item-not-found xmlns="urn:ietf:params:xml:ns:xmpp-stanzas"/>
    <text xmlns="urn:ietf:params:xml:ns:xmpp-stanzas" lang="en">Could not find call [id=f6d437f4-1e18-457b-99f8-b5d853f50347]</text>
  </error>
</iq>
      MSG
    end

    let(:example_error) { import_stanza error_xml }
    let(:cmd) { Adhearsion::Rayo::Component::Output.new }

    before do
      cmd.request!
      connection.__send__ :handle_error, example_error, cmd
    end

    subject { cmd.response }

    it "should have the correct call ID" do
      expect(subject.call_id).to eq(call_id)
    end

    it "should have the correct component ID" do
      expect(subject.component_id).to eq(component_id)
    end

    it "should have the correct name" do
      expect(subject.name).to eq(:item_not_found)
    end

    it "should have the correct text" do
      expect(subject.text).to eq('Could not find call [id=f6d437f4-1e18-457b-99f8-b5d853f50347]')
    end
  end

  describe "#prep_command_for_execution" do
    let(:stanza) { subject.prep_command_for_execution command }

    context "with a dial command" do
      let(:command)       { Adhearsion::Rayo::Command::Dial.new }
      let(:expected_jid)  { 'rayo.net' }

      it "should use the correct JID" do
        stanza = subject.prep_command_for_execution command
        expect(stanza.to).to eq(expected_jid)
      end
    end

    context "with a call command" do
      let(:command)       { Adhearsion::Rayo::Command::Answer.new target_call_id: 'abc123' }
      let(:expected_jid)  { 'abc123@rayo.net' }

      it "should use the correct JID" do
        expect(stanza.to).to eq(expected_jid)
      end

      context "with a domain specified" do
        let(:expected_jid)  { 'abc123@calls.rayo.net' }

        it "should use the specified domain in the JID" do
          stanza = subject.prep_command_for_execution command, domain: 'calls.rayo.net'
          expect(stanza.to).to eq(expected_jid)
        end
      end
    end

    context "with a call component" do
      let(:command)       { Adhearsion::Rayo::Component::Output.new :target_call_id => 'abc123' }
      let(:expected_jid)  { 'abc123@rayo.net' }

      it "should use the correct JID" do
        expect(stanza.to).to eq(expected_jid)
      end
    end

    context "with a call component command" do
      let(:command)       { Adhearsion::Rayo::Component::Stop.new :target_call_id => 'abc123', :component_id => 'foobar' }
      let(:expected_jid)  { 'abc123@rayo.net/foobar' }

      it "should use the correct JID" do
        expect(stanza.to).to eq(expected_jid)
      end
    end

    context "with a mixer component" do
      let(:command)       { Adhearsion::Rayo::Component::Output.new :target_mixer_name => 'abc123' }
      let(:expected_jid)  { 'abc123@rayo.net' }

      it "should use the correct JID" do
        expect(stanza.to).to eq(expected_jid)
      end
    end

    context "with a mixer component command" do
      let(:command)       { Adhearsion::Rayo::Component::Stop.new :target_mixer_name => 'abc123', :component_id => 'foobar' }
      let(:expected_jid)  { 'abc123@rayo.net/foobar' }

      it "should use the correct JID" do
        expect(stanza.to).to eq(expected_jid)
      end
    end
  end

  describe "receiving events from a mixer" do
    context "after joining the mixer" do
      before do
        expect(client).to receive :write_with_handler
        subject.write Adhearsion::Rayo::Command::Join.new(:mixer_name => 'foomixer')
      end

      let :active_speaker_xml do
        <<-MSG
<presence to='16577@app.rayo.net/1' from='foomixer@rayo.net'>
  <started-speaking xmlns="urn:xmpp:rayo:1" call-id="foocall"/>
</presence>
        MSG
      end

      let(:active_speaker_event) { import_stanza active_speaker_xml }

      it "should tag those events with a mixer name, rather than a call ID" do
        expect(mock_event_handler).to receive(:call).once.with(satisfy { |event|
          expect(event).to be_instance_of Adhearsion::Event::StartedSpeaking
          expect(event.target_mixer_name).to eq('foomixer')
          expect(event.target_call_id).to be nil
          expect(event.domain).to eq('rayo.net')
        })
        connection.__send__ :handle_presence, active_speaker_event
      end
    end
  end
end
