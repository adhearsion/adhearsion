# encoding: utf-8

require 'spec_helper'

describe Adhearsion::Rayo::Client do
  let(:connection) { Adhearsion::Rayo::Connection::XMPP.new :username => '1@call.rayo.net', :password => 1 }

  subject { described_class.new :connection => connection }

  describe '#connection' do
    subject { super().connection }
    it { is_expected.to be connection }
  end

  describe '#component_registry' do
    subject { super().component_registry }
    it { is_expected.to be_a described_class::ComponentRegistry }
  end

  let(:call_id)         { 'abc123' }
  let(:mock_event)      { double('Event').as_null_object }
  let(:component_id)    { 'abc123' }
  let(:component_uri)   { 'callid@server/abc123' }
  let(:mock_component)  { double 'Component', source_uri: component_uri }
  let(:mock_command)    { double 'Command' }

  describe '#run' do
    it 'should start up the connection' do
      expect(connection).to receive(:run).once
      subject.run
    end
  end

  describe '#stop' do
    it 'should stop the connection' do
      expect(connection).to receive(:stop).once
      subject.stop
    end
  end

  describe '#send_message' do
    it 'should send a message' do
      args = [ "someone", "example.org", "Hello World!" ]
      expect(connection).to receive(:send_message).with(*args).once
      subject.send_message *args
    end
  end

  describe '#new_call_uri' do
    it 'should return the connection-specific fresh call ID' do
      stub_uuids 'foobar'
      expect(subject.new_call_uri).to eq('xmpp:foobar@call.rayo.net')
    end
  end

  it 'should handle connection events' do
    expect(subject).to receive(:handle_event).with(mock_event).once
    connection.event_handler.call mock_event
  end

  describe '#handle_event' do
    it "sets the event's client" do
      event = Adhearsion::Event::Offer.new
      subject.handle_event event
      expect(event.client).to be subject
    end

    context 'if the event can be associated with a source component' do
      before do
        allow(mock_event).to receive_messages :source => mock_component
        expect(mock_component).to receive(:add_event).with mock_event
      end

      it 'should not call event handlers' do
        handler = double 'handler'
        expect(handler).to receive(:call).never
        subject.register_event_handler do |event|
          handler.call event
        end
        subject.handle_event mock_event
      end
    end

    context 'if the event cannot be associated with a source component' do
      before do
        allow(mock_event).to receive_messages :source => nil
      end

      it 'should call registered event handlers' do
        handler = double 'handler'
        expect(handler).to receive(:call).once.with mock_event
        subject.register_event_handler do |event|
          handler.call event
        end
        subject.handle_event mock_event
      end
    end
  end

  it 'should be able to register and retrieve components' do
    subject.register_component mock_component
    expect(subject.find_component_by_uri(component_uri)).to be mock_component
  end

  describe '#execute_command' do
    let(:component) { Adhearsion::Rayo::Component::Output.new }
    let(:event)     { Adhearsion::Event::Complete.new }

    before do
      expect(connection).to receive(:write).once.with component, :call_id => call_id
    end

    let :execute_command do
      subject.execute_command component, :call_id => call_id
    end

    it 'should write the command to the connection' do
      execute_command
    end

    it "should set the command's client" do
      execute_command
      expect(component.client).to be subject
    end

    it "should handle a component's events" do
      expect(subject).to receive(:trigger_handler).with(:event, event).once
      execute_command
      component.request!
      component.execute!
      component.add_event event
    end
  end
end
