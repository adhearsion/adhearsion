# encoding: utf-8

require 'spec_helper'

describe Adhearsion::Rayo::Initializer do

  def reset_default_config
    Adhearsion.config.platform do |config|
      config.type               = :xmpp
      config.username           = "usera@127.0.0.1"
      config.password           = "1"
      config.host               = nil
      config.port               = nil
      config.certs_directory    = nil
      config.root_domain        = nil
      config.connection_timeout = 60
      config.reconnect_attempts = 1.0/0.0
      config.reconnect_timer    = 5
    end
  end

  def initialize_rayo(options = {})
    reset_default_config
    allow(described_class).to receive(:connect)
    Adhearsion.config.platform do |config|
      config.type               = options[:type] if options.has_key?(:type)
      config.username           = options[:username] if options.has_key?(:username)
      config.password           = options[:password] if options.has_key?(:password)
      config.host               = options[:host] if options.has_key?(:host)
      config.port               = options[:port] if options.has_key?(:port)
      config.certs_directory    = options[:certs_directory] if options.has_key?(:certs_directory)
      config.root_domain        = options[:root_domain] if options.has_key?(:root_domain)
      config.connection_timeout = options[:connection_timeout] if options.has_key?(:connection_timeout)
      config.reconnect_attempts = options[:reconnect_attempts] if options.has_key?(:reconnect_attempts)
      config.reconnect_timer    = options[:reconnect_timer] if options.has_key?(:reconnect_timer)
    end

    described_class.init
    Adhearsion.config.platform
  end

  let(:call_id)     { rand }
  let(:offer)       { Adhearsion::Event::Offer.new :target_call_id => call_id }
  let(:mock_call)   { Adhearsion::Call.new }
  let(:mock_client) { double 'Client' }

  before do
    allow(mock_call).to receive_messages :id => call_id
    mock_client.as_null_object
    allow(mock_client).to receive_messages :event_handler= => true
    Adhearsion::Events.refresh!
    allow(Adhearsion::Process).to receive_messages :fqdn => 'hostname'
    allow(::Process).to receive_messages :pid => 1234
  end

  describe "starts the client with the default values" do
    subject { initialize_rayo }

    it "should set properly the username value" do
      expect(subject.username).to eq('usera@127.0.0.1')
    end

    it "should set properly the password value" do
      expect(subject.password).to eq('1')
    end

    it "should set properly the host value" do
      expect(subject.host).to be_nil
    end

    it "should set properly the port value" do
      expect(subject.port).to be_nil
    end

    it "should set properly the certs_directory value" do
      expect(subject.certs_directory).to be_nil
    end

    it "should set properly the root_domain value" do
      expect(subject.root_domain).to be_nil
    end

    it "should properly set the reconnect_attempts value" do
      expect(subject.reconnect_attempts).to eq(1.0/0.0)
    end

    it "should properly set the reconnect_timer value" do
      expect(subject.reconnect_timer).to eq(5)
    end
  end

  it "starts the client with the correct resource" do
    username = "usera@127.0.0.1/hostname-1234"

    expect(Adhearsion::Rayo::Connection::XMPP).to receive(:new).once.with(hash_including :username => username).and_return mock_client
    initialize_rayo
  end

  context "when the fqdn is not available" do
    it "should use the local hostname instead" do
      allow(Adhearsion::Process).to receive(:fqdn).and_raise SocketError
      allow(Socket).to receive(:gethostname).and_return 'local_hostname'

      username = "usera@127.0.0.1/local_hostname-1234"

      expect(Adhearsion::Rayo::Connection::XMPP).to receive(:new).once.with(hash_including :username => username).and_return mock_client
      initialize_rayo
    end
  end

  it "starts the client with any overridden settings" do
    expect(Adhearsion::Rayo::Connection::XMPP).to receive(:new).once.with(username: 'userb@127.0.0.1/foo', password: '123', host: 'foo.bar.com', port: 200, certs: '/foo/bar', connection_timeout: 20, root_domain: 'foo.com').and_return mock_client
    initialize_rayo username: 'userb@127.0.0.1/foo', password: '123', host: 'foo.bar.com', port: 200, certs_directory: '/foo/bar', connection_timeout: 20, root_domain: 'foo.com'
  end

  describe "#connect" do
    it 'should block until the connection is established' do
      reset_default_config
      mock_connection = double :mock_connection
      expect(mock_connection).to receive(:register_event_handler).once
      expect(Adhearsion::Rayo::Client).to receive(:new).once.and_return mock_connection
      expect(mock_connection).to receive(:run).once
      t = Thread.new { described_class.init; described_class.run }
      t.join 5
      expect(t.status).to eq("sleep")
      Adhearsion::Events.trigger_immediately :rayo, Adhearsion::Rayo::Connection::Connected.new
      t.join
    end
  end

  describe '#connect_to_server' do
    before :each do
      Adhearsion::Process.reset
      described_class.config = reset_default_config
      described_class.config.reconnect_attempts = 1
      expect(Adhearsion::Logging.get_logger(described_class)).to receive(:fatal).at_most(:once)
      allow(described_class).to receive(:client).and_return mock_client
    end

    after :each do
      Adhearsion::Process.reset
    end

    it 'should reset the Adhearsion process state to "booting"' do
      Adhearsion::Process.booted
      expect(Adhearsion::Process.state_name).to eq(:running)
      allow(mock_client).to receive(:run).and_raise Adhearsion::Rayo::DisconnectedError
      expect(Adhearsion::Process).to receive(:reset).at_least(:once)
      described_class.connect_to_server
    end

    it 'should retry the connection the specified number of times' do
      described_class.config.reconnect_attempts = 3
      allow(mock_client).to receive(:run).and_raise Adhearsion::Rayo::DisconnectedError
      described_class.connect_to_server
      expect(described_class.attempts).to eq(3)
    end

    it 'should preserve a Adhearsion::ProtocolError exception and give up' do
      allow(mock_client).to receive(:run).and_raise Adhearsion::ProtocolError
      expect { described_class.connect_to_server }.to raise_error Adhearsion::ProtocolError
    end

    it 'should not attempt to reconnect if Adhearsion is shutting down' do
      Adhearsion::Process.booted
      Adhearsion::Process.shutdown
      allow(mock_client).to receive(:run).and_raise Adhearsion::Rayo::DisconnectedError
      expect { described_class.connect_to_server }.not_to raise_error
    end
  end

  describe 'using Asterisk' do
    let(:overrides) { {:username => 'test', :password => '123', :host => 'foo.bar.com', :port => 200, :certs => nil, :connection_timeout => 20, :root_domain => 'foo.com'} }

    it 'should start an Asterisk PB connection' do
      expect(Adhearsion::Rayo::Connection::Asterisk).to receive(:new).once.with(overrides).and_return mock_client
      initialize_rayo overrides.merge(:type => :asterisk)
    end
  end

  it 'should place events into the event handler' do
    expect(Adhearsion::Events.instance).to receive(:trigger).once.with(:rayo, offer)
    initialize_rayo
    described_class.client.handle_event offer
  end

  describe "dispatching an offer" do
    before do
      initialize_rayo
      expect(Adhearsion::Process).to receive(:state_name).once.and_return process_state
      expect(Adhearsion::Call).to receive(:new).once.and_return mock_call
    end

    context "when the Adhearsion::Process is :booting" do
      let(:process_state) { :booting }

      it 'should reject a call with cause :declined' do
        expect(mock_call).to receive(:reject).once.with(:decline)
      end
    end

    [ :running, :stopping ].each do |state|
      context "when when Adhearsion::Process is in :#{state}" do
        let(:process_state) { state }

        it "should dispatch via the router" do
          Adhearsion.router do
            route 'foobar', Class.new
          end
          expect(Adhearsion.router).to receive(:handle).once.with mock_call
        end
      end
    end

    context "when when Adhearsion::Process is in :rejecting" do
      let(:process_state) { :rejecting }

      it 'should reject a call with cause :declined' do
        expect(mock_call).to receive(:reject).once.with(:decline)
      end
    end

    context "when when Adhearsion::Process is not :running, :stopping or :rejecting" do
      let(:process_state) { :foobar }

      it 'should reject a call with cause :error' do
        expect(mock_call).to receive(:reject).once.with(:error)
      end
    end

    after { Adhearsion::Events.trigger_immediately :rayo, offer }
  end

  describe "dispatching a component event" do
    let(:component)   { double 'ComponentNode' }
    let(:mock_event)  { double 'Event' }

    before { allow(mock_event).to receive_messages target_call_id: call_id, source: component }

    before do
      initialize_rayo
    end

    it "should place the event in the call's inbox" do
      expect(component).to receive(:trigger_event_handler).once.with mock_event
      Adhearsion::Events.trigger_immediately :rayo, mock_event
    end
  end

  describe "dispatching a call event" do
    let(:mock_event)  { double 'Event' }

    before { allow(mock_event).to receive_messages target_call_id: call_id }

    describe "with an active call" do
      before do
        initialize_rayo
        Adhearsion.active_calls << mock_call
      end

      it "should forward the event to the call actor" do
        events = []
        mock_call.register_event_handler do |event|
          events << event
        end
        described_class.dispatch_call_event mock_event
        sleep 0.5
        expect(events).to eql([mock_event])
      end

      it "should not block on the call handling the event" do

        mock_call.register_event_handler do |event|
          sleep 5
        end
        start_time = Time.now
        described_class.dispatch_call_event mock_event
        sleep 0.5
        expect(Time.now - start_time).to be < 1
      end
    end

    describe "with an inactive call" do
      it "should log a warning" do
        expect(Adhearsion::Logging.get_logger(described_class)).to receive(:warn).once.with("Event received for inactive call #{call_id}: #{mock_event.inspect}")
        described_class.dispatch_call_event mock_event
      end
    end

    describe "when the registry contains a dead call" do
      before do
        mock_call.terminate
        Adhearsion.active_calls[mock_call.id] = mock_call
      end

      it "should log a warning" do
        expect(Adhearsion::Logging.get_logger(described_class)).to receive(:warn).once.with("Event received for inactive call #{call_id}: #{mock_event.inspect}")
        described_class.dispatch_call_event mock_event
      end
    end
  end

  context "rayo configuration" do
    describe "with config specified" do
      before do
        Adhearsion.config.platform do |config|
          config.username = 'userb@127.0.0.1'
          config.password = 'abc123'
        end
      end

      subject do
        Adhearsion.config.platform
      end

      it "should set properly the username value" do
        expect(subject.username).to eq('userb@127.0.0.1')
      end

      it "should set properly the password value" do
        expect(subject.password).to eq('abc123')
      end
    end
  end

  it "should allow easily registering handlers for AMI events" do
    result = nil
    ami_event = Adhearsion::Event::Asterisk::AMI.new :name => 'foobar'
    latch = CountDownLatch.new 1

    Adhearsion::Events.draw do
      ami :name => 'foobar' do |event|
        result = event
        latch.countdown!
      end
    end

    described_class.handle_event ami_event

    expect(latch.wait(1)).to be true
    expect(result).to be ami_event
  end
end
