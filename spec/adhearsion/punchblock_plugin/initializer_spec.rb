# encoding: utf-8

require 'spec_helper'

module Adhearsion
  class PunchblockPlugin
    describe Initializer do

      def reset_default_config
        Adhearsion.config.punchblock do |config|
          config.platform           = :xmpp
          config.username           = "usera@127.0.0.1"
          config.password           = "1"
          config.host               = nil
          config.port               = nil
          config.root_domain        = nil
          config.calls_domain       = nil
          config.mixers_domain      = nil
          config.connection_timeout = 60
          config.reconnect_attempts = 1.0/0.0
          config.reconnect_timer    = 5
          config.media_engine       = nil
          config.default_voice      = nil
        end
      end

      def initialize_punchblock(options = {})
        reset_default_config
        Initializer.stub(:connect)
        Adhearsion.config.punchblock do |config|
          config.platform           = options[:platform] if options.has_key?(:platform)
          config.username           = options[:username] if options.has_key?(:username)
          config.password           = options[:password] if options.has_key?(:password)
          config.host               = options[:host] if options.has_key?(:host)
          config.port               = options[:port] if options.has_key?(:port)
          config.root_domain        = options[:root_domain] if options.has_key?(:root_domain)
          config.calls_domain       = options[:calls_domain] if options.has_key?(:calls_domain)
          config.mixers_domain      = options[:mixers_domain] if options.has_key?(:mixers_domain)
          config.connection_timeout = options[:connection_timeout] if options.has_key?(:connection_timeout)
          config.reconnect_attempts = options[:reconnect_attempts] if options.has_key?(:reconnect_attempts)
          config.reconnect_timer    = options[:reconnect_timer] if options.has_key?(:reconnect_timer)
          config.media_engine       = options[:media_engine] if options.has_key?(:media_engine)
          config.default_voice      = options[:default_voice] if options.has_key?(:default_voice)
        end

        Initializer.init
        Adhearsion.config[:punchblock]
      end

      let(:call_id)     { rand }
      let(:offer)       { Punchblock::Event::Offer.new :target_call_id => call_id }
      let(:mock_call)   { Call.new }
      let(:mock_client) { mock 'Client' }

      before do
        mock_call.stub :id => call_id
        mock_client.as_null_object
        mock_client.stub :event_handler= => true
        Events.refresh!
        Adhearsion::Process.stub :fqdn => 'hostname'
        ::Process.stub :pid => 1234
      end

      describe "starts the client with the default values" do
        subject { initialize_punchblock }

        it "should set properly the username value" do
          subject.username.should be == 'usera@127.0.0.1'
        end

        it "should set properly the password value" do
          subject.password.should be == '1'
        end

        it "should set properly the host value" do
          subject.host.should be_nil
        end

        it "should set properly the port value" do
          subject.port.should be_nil
        end

        it "should set properly the root_domain value" do
          subject.root_domain.should be_nil
        end

        it "should set properly the calls_domain value" do
          subject.calls_domain.should be_nil
        end

        it "should set properly the mixers_domain value" do
          subject.mixers_domain.should be_nil
        end

        it "should properly set the reconnect_attempts value" do
          subject.reconnect_attempts.should be == 1.0/0.0
        end

        it "should properly set the reconnect_timer value" do
          subject.reconnect_timer.should be == 5
        end

        it "should properly set the media_engine value" do
          subject.media_engine.should be == nil
        end

        it "should properly set the default_voice value" do
          subject.default_voice.should be == nil
        end
      end

      it "starts the client with the correct resource" do
        username = "usera@127.0.0.1/hostname-1234"

        Punchblock::Connection::XMPP.should_receive(:new).once.with(hash_including :username => username).and_return mock_client
        initialize_punchblock
      end

      it "starts the client with any overridden settings" do
        overrides = {:username => 'userb@127.0.0.1/foo', :password => '123', :host => 'foo.bar.com', :port => 200, :connection_timeout => 20, :root_domain => 'foo.com', :calls_domain => 'call.foo.com', :mixers_domain => 'mixer.foo.com', :media_engine => :swift, :default_voice => :hal}

        Punchblock::Connection::XMPP.should_receive(:new).once.with(overrides).and_return mock_client
        initialize_punchblock overrides
      end

      describe "#connect" do
        it 'should block until the connection is established' do
          reset_default_config
          mock_connection = mock :mock_connection
          mock_connection.should_receive(:register_event_handler).once
          Punchblock::Client.should_receive(:new).once.and_return mock_connection
          mock_connection.should_receive(:run).once
          t = Thread.new { Initializer.init; Initializer.run }
          t.join 5
          t.status.should be == "sleep"
          Events.trigger_immediately :punchblock, Punchblock::Connection::Connected.new
          t.join
        end
      end

      describe '#connect_to_server' do
        before :each do
          Adhearsion::Process.reset
          Initializer.config = reset_default_config
          Initializer.config.reconnect_attempts = 1
          Adhearsion::Logging.get_logger(Initializer).should_receive(:fatal).at_most(:once)
          Initializer.stub(:client).and_return mock_client
        end

        after :each do
          Adhearsion::Process.reset
        end

        it 'should reset the Adhearsion process state to "booting"' do
          Adhearsion::Process.booted
          Adhearsion::Process.state_name.should be == :running
          mock_client.stub(:run).and_raise Punchblock::DisconnectedError
          Adhearsion::Process.should_receive(:reset).at_least(:once)
          Initializer.connect_to_server
        end

        it 'should retry the connection the specified number of times' do
          Initializer.config.reconnect_attempts = 3
          mock_client.stub(:run).and_raise Punchblock::DisconnectedError
          Initializer.connect_to_server
          Initializer.attempts.should be == 3
        end

        it 'should preserve a Punchblock::ProtocolError exception and give up' do
          mock_client.stub(:run).and_raise Punchblock::ProtocolError
          expect { Initializer.connect_to_server }.to raise_error Punchblock::ProtocolError
        end

        it 'should not attempt to reconnect if Adhearsion is shutting down' do
          Adhearsion::Process.booted
          Adhearsion::Process.shutdown
          mock_client.stub(:run).and_raise Punchblock::DisconnectedError
          Initializer.should_not raise_error Punchblock::DisconnectedError
        end
      end

      describe 'using Asterisk' do
        let(:overrides) { {:username => 'test', :password => '123', :host => 'foo.bar.com', :port => 200, :connection_timeout => 20, :root_domain => 'foo.com', :calls_domain => 'call.foo.com', :mixers_domain => 'mixer.foo.com', :media_engine => :swift, :default_voice => :hal} }

        it 'should start an Asterisk PB connection' do
          Punchblock::Connection::Asterisk.should_receive(:new).once.with(overrides).and_return mock_client
          initialize_punchblock overrides.merge(:platform => :asterisk)
        end
      end

      describe 'using FreeSWITCH' do
        let(:overrides) { {:username => 'test', :password => '123', :host => 'foo.bar.com', :port => 200, :connection_timeout => 20, :root_domain => 'foo.com', :calls_domain => 'call.foo.com', :mixers_domain => 'mixer.foo.com', :media_engine => :swift, :default_voice => :hal} }

        it 'should start a FreeSWITCH PB connection' do
          Punchblock::Connection::Freeswitch.should_receive(:new).once.with(overrides).and_return mock_client
          initialize_punchblock overrides.merge(:platform => :freeswitch)
        end
      end

      it 'should place events from Punchblock into the event handler' do
        Events.instance.should_receive(:trigger).once.with(:punchblock, offer)
        initialize_punchblock
        Initializer.client.handle_event offer
      end

      describe "dispatching an offer" do
        before do
          initialize_punchblock
          Adhearsion::Process.should_receive(:state_name).once.and_return process_state
          Adhearsion.active_calls.should_receive(:from_offer).once.and_return mock_call
        end

        context "when the Adhearsion::Process is :booting" do
          let(:process_state) { :booting }

          it 'should reject a call with cause :declined' do
            mock_call.should_receive(:reject).once.with(:decline)
          end
        end

        [ :running, :stopping ].each do |state|
          context "when when Adhearsion::Process is in :#{state}" do
            let(:process_state) { state }

            it "should dispatch via the router" do
              Adhearsion.router do
                route 'foobar', Class.new
              end
              Adhearsion.router.should_receive(:handle).once.with mock_call
            end
          end
        end

        context "when when Adhearsion::Process is in :rejecting" do
          let(:process_state) { :rejecting }

          it 'should reject a call with cause :declined' do
            mock_call.should_receive(:reject).once.with(:decline)
          end
        end

        context "when when Adhearsion::Process is not :running, :stopping or :rejecting" do
          let(:process_state) { :foobar }

          it 'should reject a call with cause :error' do
            mock_call.should_receive(:reject).once.with(:error)
          end
        end

        after { Events.trigger_immediately :punchblock, offer }
      end

      describe "dispatching a component event" do
        let(:component)   { mock 'ComponentNode' }
        let(:mock_event)  { mock 'Event' }

        before { mock_event.stub target_call_id: call_id, source: component }

        before do
          initialize_punchblock
        end

        it "should place the event in the call's inbox" do
          component.should_receive(:trigger_event_handler).once.with mock_event
          Events.trigger_immediately :punchblock, mock_event
        end
      end

      describe "dispatching a call event" do
        let(:mock_event)  { mock 'Event' }

        before { mock_event.stub target_call_id: call_id }

        describe "with an active call" do
          before do
            initialize_punchblock
            Adhearsion.active_calls << mock_call
          end

          it "should place the event in the call's inbox" do
            mock_call.async.should_receive(:deliver_message).once.with(mock_event)
            Initializer.dispatch_call_event mock_event
          end
        end

        describe "with an inactive call" do
          it "should log an error" do
            Adhearsion::Logging.get_logger(Initializer).should_receive(:error).once.with("Event received for inactive call #{call_id}: #{mock_event.inspect}")
            Initializer.dispatch_call_event mock_event
          end
        end
      end

      context "Punchblock configuration" do
        describe "with config specified" do
          before do
            Adhearsion.config.punchblock do |config|
              config.username = 'userb@127.0.0.1'
              config.password = 'abc123'
            end
          end

          subject do
            Adhearsion.config[:punchblock]
          end

          it "should set properly the username value" do
            subject.username.should be == 'userb@127.0.0.1'
          end

          it "should set properly the password value" do
            subject.password.should be == 'abc123'
          end
        end
      end

      it "should allow easily registering handlers for AMI events" do
        result = nil
        ami_event = Punchblock::Event::Asterisk::AMI::Event.new :name => 'foobar'
        latch = CountDownLatch.new 1

        Events.draw do
          ami :name => 'foobar' do |event|
            result = event
            latch.countdown!
          end
        end

        Initializer.handle_event ami_event

        latch.wait(1).should be true
        result.should be ami_event
      end
    end
  end
end
