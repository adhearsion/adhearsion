# encoding: utf-8

require 'spec_helper'

describe Adhearsion::Rayo::Connection::Asterisk do
  let :options do
    {
      :host     => '127.0.0.1',
      :port     => 5038,
      :username => 'test',
      :password => 'test'
    }
  end

  let(:mock_event_handler) { double('Event Handler').as_null_object }

  subject(:connection) { described_class.new options }

  before do
    connection.event_handler = mock_event_handler
  end

  describe '#ami_client' do
    subject { connection.ami_client }

    it { is_expected.to be_a described_class::RubyAMIStreamProxy }
  end

  describe '#ami_client' do
    describe '#stream' do
      subject { connection.ami_client.stream }

      it { is_expected.to be_a RubyAMI::Stream }
    end
  end

  it 'should set the connection on the translator' do
    expect(subject.translator.connection).to be subject
  end

  describe '#run' do
    it 'starts the RubyAMI::Stream' do
      skip "Replace with integration tests"
      expect(subject.ami_client.wrapped_object).to receive(:run).once do
        subject.ami_client.terminate
      end
      expect { subject.run }.to raise_error Adhearsion::Rayo::DisconnectedError
    end

    it 'rebuilds the RubyAMI::Stream if dead' do
      skip
      expect(subject.ami_client.async).to receive(:run).once do
        subject.ami_client.terminate
      end
      expect { subject.run }.to raise_error DisconnectedError
      expect(subject.ami_client.alive?).to be_falsey
      expect(subject).to receive(:new_ami_stream).once do
        expect(subject.ami_client.alive?).to be true
        expect(subject.ami_client.async).to receive(:run).once
      end
      expect { subject.run }.not_to raise_error
    end
  end

  describe '#stop' do
    it 'stops the RubyAMI::Stream' do
      expect(subject.ami_client).to receive(:terminate).once
      subject.stop
    end

    it 'shuts down the translator' do
      expect(subject.translator).to receive(:terminate).once
      subject.stop
    end
  end

  it 'sends events from RubyAMI to the translator' do
    skip "Replace with integration tests"
    event = RubyAMI::Event.new 'FullyBooted'
    expect(subject.translator.async).to receive(:handle_ami_event).once.with event
    expect(subject.translator.async).to receive(:handle_ami_event).once.with RubyAMI::Stream::Disconnected.new
    subject.ami_client.message_received event
  end

  describe '#write' do
    it 'sends a command to the translator' do
      skip "Replace with integration tests"
      command = double 'Command'
      options = {:foo => :bar}
      expect(subject.translator.async).to receive(:execute_command).once.with command, options
      subject.write command, options
    end
  end

  describe 'when a rayo event is received from the translator' do
    it 'should call the event handler with the event' do
      offer = Adhearsion::Event::Offer.new
      offer.target_call_id = '9f00061'

      expect(mock_event_handler).to receive(:call).once.with offer
      subject.handle_event offer
    end
  end

  describe '#new_call_uri' do
    it "should return a random UUID" do
      stub_uuids 'foobar'
      expect(subject.new_call_uri).to eq('foobar')
    end
  end

  describe '#send_message' do
    it 'passes the message to the translator for dispatch' do
      expect(subject.translator).to receive(:send_message).once.with(:foo)
      subject.send_message :foo
    end
  end
end
