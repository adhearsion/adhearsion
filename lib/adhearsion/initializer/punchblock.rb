require 'punchblock'
require 'timeout'

module Adhearsion
  class Initializer
    class PunchblockInitializer
      cattr_accessor :config, :client

      class << self
        def start
          self.config = AHN_CONFIG.punchblock
          self.client = Punchblock::Rayo.new self.config.connection_options

          # Make sure we stop everything when we shutdown
          Events.register_callback(:shutdown) do
            ahn_log.info "Shutting down with #{Adhearsion.active_calls.size} active calls"
            client.stop
          end

          connect
        end

        def connect
          Events.register_callback(:after_initialized) do
            begin
              IMPORTANT_THREADS << client.run
              first_event = nil
              Timeout::timeout(30) { first_event = client.event_queue.pop }
              ahn_log.punchblock.info "Connected via Punchblock" if first_event == client.connected
              poll_queue
            rescue => e
              ahn_log.punchblock.fatal "Failed to start Punchblock client! #{e.inspect}"
              abort
            end
          end
        end

        def poll_queue
          Thread.new do
            loop do
              event = client.event_queue.pop
              ahn_log.punchblock.events.notice "#{event.class} event for call: #{event.call_id}"
              case event
              when Punchblock::Rayo::Event::Offer
                ahn_log.punchblock.events.info "Offer received for call ID #{event.call_id}"
              else
                ahn_log.punchblock.events.error "Unknown event: #{event.inspect}"
              end
            end
          end
        end
      end
    end # PunchblockInitializer
  end # Initializer
end # Adhearsion
