# encoding: utf-8

require 'blather'

module Adhearsion
  class PunchblockPlugin
    class Initializer
      cattr_accessor :config, :client, :connection, :dispatcher, :attempts

      self.attempts = 0

      class << self
        def init
          self.config = Adhearsion.config[:punchblock]

          username = self.config.username
          connection_class = case (self.config.platform || :xmpp)
          when :xmpp
            username = Blather::JID.new username
            username = Blather::JID.new username.node, username.domain, resource unless username.resource
            username = username.to_s
            Punchblock::Connection::XMPP
          when :asterisk
            Punchblock::Connection::Asterisk
          when :freeswitch
            Punchblock::Connection::Freeswitch
          end

          connection_options = {
            :username           => username,
            :password           => self.config.password,
            :connection_timeout => self.config.connection_timeout,
            :host               => self.config.host,
            :port               => self.config.port,
            :certs              => self.config.certs_directory,
            :root_domain        => self.config.root_domain,
            :calls_domain       => self.config.calls_domain,
            :mixers_domain      => self.config.mixers_domain,
            :media_engine       => self.config.media_engine,
            :default_voice      => self.config.default_voice
          }

          self.connection = connection_class.new connection_options
          self.client = Punchblock::Client.new :connection => connection

          # Tell the Punchblock connection that we are ready to process calls.
          Events.register_callback :after_initialized do
            connection.ready!
          end

          # When a stop is requested, change our status to "Do Not Disturb"
          # This should prevent the telephony engine from sending us any new calls.
          Events.register_callback :stop_requested do
            connection.not_ready! if connection.connected?
          end

          # Make sure we stop everything when we shutdown
          Events.register_callback :shutdown do
            client.stop
          end

          # Handle events from Punchblock via events system
          self.client.register_event_handler do |event|
            handle_event event
          end

          Events.punchblock Punchblock::Connection::Connected do |event|
            logger.info "Connected to Punchblock server"
            self.attempts = 0
          end

          Events.punchblock Punchblock::Event::Offer do |offer|
            dispatch_offer offer
          end

          Events.punchblock proc { |e| e.respond_to?(:source) }, :source do |event|
            event.source.trigger_event_handler event
          end

          Events.punchblock proc { |e| e.respond_to?(:target_call_id) }, :target_call_id do |event|
            dispatch_call_event event
          end
        end

        def run
          connect
        end

        def connect
          return unless Process.state_name == :booting
          m = Mutex.new
          blocker = ConditionVariable.new

          Events.punchblock Punchblock::Connection::Connected do
            Adhearsion::Process.booted
            m.synchronize { blocker.broadcast }
          end

          Events.shutdown do
            logger.info "Shutting down while connecting. Breaking the connection block."
            m.synchronize { blocker.broadcast }
          end

          Adhearsion::Process.important_threads << Thread.new do
            catching_standard_errors { connect_to_server }
          end

          # Wait for the connection to establish
          m.synchronize { blocker.wait m }
        end

        def connect_to_server
          logger.info "Starting connection to server"
          client.run
        rescue Punchblock::DisconnectedError => e
          # We only care about disconnects if the process is up or booting
          return unless [:booting, :running].include? Adhearsion::Process.state_name

          Adhearsion::Process.reset unless Adhearsion::Process.state_name == :booting

          self.attempts += 1

          if self.attempts >= self.config.reconnect_attempts
            logger.fatal "Connection lost. Connection retry attempts exceeded."
            Adhearsion::Process.stop!
            return
          end

          logger.error "Connection lost. Attempting reconnect #{self.attempts} of #{self.config.reconnect_attempts}"
          sleep self.config.reconnect_timer
          retry
        rescue Punchblock::ProtocolError => e
          logger.fatal "The connection failed due to a protocol error: #{e.name}."
          raise e
        end

        def dispatch_offer(offer)
          catching_standard_errors do
            call = Adhearsion.active_calls.from_offer offer
            case Adhearsion::Process.state_name
            when :booting, :rejecting
              logger.info "Declining call because the process is not yet running."
              call.reject :decline
            when :running, :stopping
              Adhearsion.router.handle call
            else
              call.reject :error
            end
          end
        end

        def dispatch_call_event(event)
          if call = Adhearsion.active_calls[event.target_call_id]
            call.async.deliver_message event
          else
            logger.error "Event received for inactive call #{event.target_call_id}: #{event.inspect}"
          end
        end

        def handle_event(event)
          Events.trigger :punchblock, event
          case event
          when Punchblock::Event::Asterisk::AMI::Event
            Events.trigger :ami, event
          end
        end

        def resource
          [Adhearsion::Process.fqdn, ::Process.pid].join '-'
        end
      end
    end # Punchblock
  end # Plugin
end # Adhearsion
