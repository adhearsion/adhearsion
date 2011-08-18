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
              if event.is_a?(Punchblock::Rayo::Event::Offer)
                ahn_log.punchblock.events.info "Offer received for call ID #{event.call_id}"
                handle_call_from_offer event
              else
                # TODO: Dispatch the event to the appropriate call
                ahn_log.punchblock.events.error "Unknown event: #{event.inspect}"
              end
            end
          end
        end

        def handle_call_from_offer(offer)
          call = Adhearsion.receive_call_from event

          Events.trigger_immediately [:before_call], call
          ahn_log.punchblock.notice "Handling call with ID #{call.id}"

          DialPlan::Manager.handle call
        rescue Hangup
          ahn_log.punchblock "HANGUP event for call with id #{call.id}"
          Events.trigger_immediately [:after_call], call
          call.hangup!
        rescue DialPlan::Manager::NoContextError => e
          ahn_log.punchblock e.message
          call.hangup!
        rescue SyntaxError, StandardError => e
          Events.trigger ['exception'], e
        ensure
          Adhearsion.remove_inactive_call call
        end
      end
    end # PunchblockInitializer
  end # Initializer
end # Adhearsion
