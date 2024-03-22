# encoding: utf-8

require 'blather'
require 'active_support/core_ext/class/attribute_accessors'

module Adhearsion
  module Rayo
    class Initializer
      cattr_accessor :config, :client, :dispatcher, :attempts

      self.attempts = 0

      class << self
        def init
          self.config = Adhearsion.config.core

          username = self.config.username
          if (self.config.type || :xmpp) == :xmpp
            username = Blather::JID.new username
            username = Blather::JID.new username.node, username.domain, resource unless username.resource
            username = username.to_s
          end

          connection_options = {
            :username           => username,
            :password           => self.config.password,
            :connection_timeout => self.config.connection_timeout,
            :host               => self.config.host,
            :port               => self.config.port,
            :certs              => self.config.certs_directory,
            :root_domain        => self.config.root_domain
          }

          self.client = Adhearsion.client_with_connection(self.config.type, **connection_options)

          # Tell the connection that we are ready to process calls.
          Events.register_callback :after_initialized do
            connection.ready!
          end

          # When quiescence is requested, change our status to "Do Not Disturb"
          # This should prevent the telephony engine from sending us any new calls.
          Events.register_callback :quiesced do
            connection.not_ready! if connection.connected?
          end

          # Make sure we stop everything when we shutdown
          Events.register_callback :shutdown do
            client.stop
          end

          # Handle events from connection via events system
          self.client.register_event_handler do |event|
            handle_event event
          end

          Events.rayo Adhearsion::Rayo::Connection::Connected do |event|
            logger.info "Connected to Rayo server"
            self.attempts = 0
          end

          Events.rayo Adhearsion::Event::Offer do |offer|
            dispatch_offer offer
          end

          Events.rayo proc { |e| e.respond_to?(:source) }, :source do |event|
            event.source.trigger_event_handler event
          end

          Events.rayo proc { |e| e.respond_to?(:target_call_id) }, :target_call_id do |event|
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

          Events.rayo Adhearsion::Rayo::Connection::Connected do
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

          throw :boot_aborted if self.attempts >= self.config.reconnect_attempts
        end

        def connect_to_server
          logger.info "Starting connection to server"
          client.run
        rescue Adhearsion::Rayo::DisconnectedError => e
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
        rescue Adhearsion::ProtocolError => e
          logger.fatal "The connection failed due to a protocol error: #{e.name}."
          raise e
        end

        def dispatch_offer(offer)
          catching_standard_errors do
            call = Call.new(offer)
            Adhearsion.active_calls << call
            call.async.route
          end
        end

        def dispatch_call_event(event)
          if call = Adhearsion.active_calls[event.target_call_id]
            call.async.deliver_message event
          else
            logger.warn "Event received for inactive call #{event.target_call_id}: #{event.inspect}"
            Events.trigger :inactive_call, event
          end
        end

        def handle_event(event)
          Events.trigger :rayo, event
          case event
          when Adhearsion::Event::Asterisk::AMI
            Events.trigger :ami, event
          end
        end

        def resource
          [machine_identifier, ::Process.pid].join '-'
        end

        def machine_identifier
          Adhearsion::Process.fqdn
        rescue SocketError
          Socket.gethostname
        end

        def connection
          client.connection
        end
      end
    end
  end
end
