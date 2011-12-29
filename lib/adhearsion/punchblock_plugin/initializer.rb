module Adhearsion
  class PunchblockPlugin
    class Initializer
      cattr_accessor :config, :client, :dispatcher

      class << self
        def start
          self.config = Adhearsion.config[:punchblock]
          connection_class = case (self.config.platform || :xmpp)
          when :xmpp
            ::Punchblock::Connection::XMPP
          when :asterisk
            ::Punchblock::Connection::Asterisk
          end
          connection_options = {
            :username         => self.config.username,
            :password         => self.config.password,
            :auto_reconnect   => self.config.auto_reconnect,
            :host             => self.config.host,
            :port             => self.config.port,
            :root_domain      => self.config.root_domain,
            :calls_domain     => self.config.calls_domain,
            :mixers_domain    => self.config.mixers_domain
          }

          connection = connection_class.new connection_options
          self.client = ::Punchblock::Client.new :connection => connection

          # Tell the Punchblock connection that we are ready to process calls.
          Events.register_callback(:after_initialization) do
            connection.ready!
          end

          # When a stop is requested, change our status to "Do Not Disturb"
          # This should prevent the telephony engine from sending us any new calls.
          Events.register_callback(:stop_requested) do
            connection.not_ready!
          end

          # Make sure we stop everything when we shutdown
          Events.register_callback(:shutdown) do
            client.stop
          end

          # Handle events from Punchblock via events system
          self.client.register_event_handler do |event|
            Events.trigger :punchblock, event
          end

          Events.punchblock ::Punchblock::Event::Offer do |offer|
            dispatch_offer offer
          end

          Events.punchblock proc { |e| e.respond_to?(:source) }, :source do |event|
            event.source.trigger_event_handler event
          end

          Events.punchblock proc { |e| e.respond_to?(:call_id) }, :call_id do |event|
            dispatch_call_event event
          end

          connect
        end

        def connect
          begin
            logger.info "Starting connection to server"

            m = Mutex.new
            blocker = ConditionVariable.new
            Events.punchblock ::Punchblock::Connection::Connected do
              logger.info "Connected to server."
              m.synchronize { blocker.broadcast }
            end
            Adhearsion::Process.important_threads << Thread.new do
              catching_standard_errors do
                begin
                  client.run
                rescue ::Punchblock::ProtocolError => e
                  logger.fatal "The connection failed due to a protocol error: #{e.name}."
                  m.synchronize { blocker.broadcast }
                end
              end
            end

            # Wait for the connection to establish
            m.synchronize { blocker.wait(m) }
          rescue => e
            logger.fatal "Failed to start Punchblock client! #{e.inspect}"
            abort
          end
        end

        def dispatch_offer(offer)
          catching_standard_errors do
            call = Adhearsion.active_calls.from_offer offer
            case Adhearsion::Process.state_name
            when :booting, :rejecting
              call.reject :decline
            when :running
              dispatcher = Adhearsion.router.handle call
              dispatcher.call call
            else
              call.reject :error
            end
          end
        end

        def dispatch_call_event(event, latch = nil)
          if call = Adhearsion.active_calls.find(event.call_id)
            logger.debug "Event received for call #{call.id}: #{event.inspect}"
            Thread.new do
              call << event
              latch.countdown! if latch
            end
          else
            logger.error "Event received for inactive call #{event.call_id}: #{event.inspect}"
          end
        end
      end
    end # Punchblock
  end # Plugin
end # Adhearsion
