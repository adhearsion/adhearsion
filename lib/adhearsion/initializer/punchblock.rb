require 'timeout'

module Adhearsion
  class Initializer
    class Punchblock
      cattr_accessor :config, :client, :dispatcher

      class << self
        def start
          self.config = Adhearsion.config.punchblock
          connection_class = case (self.config.connection_options.delete(:platform) || :xmpp)
          when :xmpp
            ::Punchblock::Connection::XMPP
          when :asterisk
            ::Punchblock::Connection::Asterisk
          end
          connection = connection_class.new self.config.connection_options
          self.client = ::Punchblock::Client.new :connection => connection

          # Make sure we stop everything when we shutdown
          Events.register_callback(:shutdown) do
            logger.info "Shutting down with #{Adhearsion.active_calls.size} active calls"
            client.stop
          end

          # Handle events from Punchblock via events system
          self.client.register_event_handler do |event|
            logger.debug "Received event from Punchblock: #{event.inspect}"
            Events.trigger :punchblock, event
          end

          Events.register_callback :punchblock, ::Punchblock::Event::Offer do |offer|
            dispatch_offer offer
          end

          Events.register_callback :punchblock, proc { |e| e.respond_to?(:call_id) }, :call_id do |event|
            dispatch_call_event event
          end

          connect
        end

        def connect
          Events.register_callback(:after_initialized) do
            begin
              logger.info "Waiting for connection via Punchblock"
              IMPORTANT_THREADS << Thread.new do
                catching_standard_errors { client.run }
              end
              Events.register_callback :punchblock, ::Punchblock::Connection::Connected do
                logger.info "Connected via Punchblock"
              end
            rescue => e
              logger.fatal "Failed to start Punchblock client! #{e.inspect}"
              abort
            end
          end
        end

        def dispatch_offer(offer)
          catching_standard_errors do
            DialPlan::Manager.handle Adhearsion.receive_call_from(offer)
          end
        end

        def dispatch_call_event(event, latch = nil)
          if call = Adhearsion.active_calls.find(event.call_id)
            logger.info "Event received for call #{call.id}: #{event.inspect}"
            Thread.new do
              call << event
              latch.countdown! if latch
            end
          else
            logger.error "Event received for inactive call #{event.call_id}: #{event.inspect}"
          end
        end
      end
    end # PunchblockInitializer
  end # Initializer
end # Adhearsion
