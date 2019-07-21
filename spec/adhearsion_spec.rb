# encoding: utf-8

require 'spec_helper'

describe Adhearsion do
  describe "#root=" do
    it "should update properly the config root variable" do
      Adhearsion.root = "./"
      expect(Adhearsion.config[:core].root).to eq(Dir.getwd)
    end

    it "should update properly the config root variable when path is nil" do
      Adhearsion.root = nil
      expect(Adhearsion.config[:core].root).to be_nil
    end
  end

  describe "#root" do
    it "should return the set root" do
      Adhearsion.root = "./"
      expect(Adhearsion.root).to eq(Dir.getwd)
    end
  end

  describe "#config" do
    it "should return a Configuration instance" do
      expect(subject.config).to be_instance_of Adhearsion::Configuration
    end

    it "should execute a block" do
      foo = Object.new
      expect(foo).to receive(:bar).once
      Adhearsion.config do |config|
        foo.bar
      end
    end
  end

  describe "#router" do
    describe '#router' do
      subject { super().router }
      it { is_expected.to be_a Adhearsion::Router }
    end

    it "should always use the same router" do
      expect(Adhearsion.router).to be Adhearsion.router
    end

    it "should pass a block along to the router" do
      foo = nil
      Adhearsion.router do
        foo = self
      end

      expect(foo).to be Adhearsion.router
    end
  end

  describe "#active_calls" do
    it "should be a calls collection" do
      expect(Adhearsion.active_calls).to be_a Adhearsion::Calls
    end

    it "should return the same instance each time" do
      expect(Adhearsion.active_calls).to be Adhearsion.active_calls
    end
  end

  describe "#statistics" do
    it "should be a statistics aggregator" do
      expect(Adhearsion.statistics).to be_a Adhearsion::Statistics
    end

    it "should return the same instance each time" do
      expect(Adhearsion.statistics).to be Adhearsion.statistics
    end

    it "should create a new aggregator if the existing one dies" do
      original = Adhearsion.statistics
      original.terminate
      expect(original.alive?).to be false

      sleep 0.25

      current = Adhearsion.statistics
      expect(current).to be_alive
      expect(current).not_to be original
    end
  end

  describe "#status" do
    it "should be the process status name" do
      expect(Adhearsion.status).to eq(:booting)
    end
  end

  describe '#execute_component' do
    let(:message)     { Adhearsion::Rayo::Command::Accept.new }
    let(:response)    { :foo }
    let(:mock_client) { double 'Client' }

    let(:execute_expectation) { expect(described_class.client).to receive(:execute_command).once }

    before do
      Adhearsion::Rayo::Initializer.client = mock_client
      allow(message).to receive_messages :execute! => true
      message.response = response
      execute_expectation
    end

    it "writes a command to the client" do
      execute_expectation.with(message)
      described_class.execute_component message
    end

    it "blocks until a response is received" do
      slow_command = Adhearsion::Rayo::Command::Dial.new
      slow_command.request!
      starting_time = Time.now
      Thread.new do
        sleep 0.5
        slow_command.response = response
      end
      described_class.execute_component slow_command
      expect(Time.now - starting_time).to be >= 0.4
    end

    describe "with a successful response" do
      it "returns the executed command" do
        expect(described_class.execute_component(message)).to be message
      end
    end

    describe "with an error response" do
      let(:response) { Exception.new }

      it "raises the error" do
        expect { described_class.execute_component message }.to raise_error Exception
      end
    end
  end

  describe '#client_with_connection' do
    let(:mock_connection) { double('Connection').as_null_object }

    context 'with :xmpp' do
      it 'sets up an XMPP connection, passing options, and a client with the connection attached' do
        options = {:username => 'foo', :password => 'bar'}
        expect(Adhearsion::Rayo::Connection::XMPP).to receive(:new).once.with(options).and_return mock_connection
        client = Adhearsion.client_with_connection :xmpp, options
        expect(client).to be_a Adhearsion::Rayo::Client
        expect(client.connection).to be mock_connection
      end
    end

    context 'with :XMPP' do
      it 'sets up an XMPP connection, passing options, and a client with the connection attached' do
        options = {:username => 'foo', :password => 'bar'}
        expect(Adhearsion::Rayo::Connection::XMPP).to receive(:new).once.with(options).and_return mock_connection
        client = Adhearsion.client_with_connection :XMPP, options
        expect(client).to be_a Adhearsion::Rayo::Client
        expect(client.connection).to be mock_connection
      end
    end

    context 'with :asterisk' do
      it 'sets up an Asterisk connection, passing options, and a client with the connection attached' do
        options = {:username => 'foo', :password => 'bar'}
        expect(Adhearsion::Rayo::Connection::Asterisk).to receive(:new).once.with(options).and_return mock_connection
        client = Adhearsion.client_with_connection :asterisk, options
        expect(client).to be_a Adhearsion::Rayo::Client
        expect(client.connection).to be mock_connection
      end
    end

    context 'with :yate' do
      it 'raises ArgumentError' do
        options = {:username => 'foo', :password => 'bar'}
        expect { Adhearsion.client_with_connection :yate, options }.to raise_error(ArgumentError)
      end
    end
  end

  Dir['{bin,features,lib,spec}/**/*.rb'].each do |filename|
    it "should have an encoding in the file #{filename}" do
      File.open filename do |file|
        first_line = file.first
        expect(first_line).to eq("# encoding: utf-8\n")
      end
    end
  end
end
