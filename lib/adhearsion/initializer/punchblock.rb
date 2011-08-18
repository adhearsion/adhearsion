require 'timeout'

module Adhearsion
  class Initializer
    class Punchblock
      cattr_accessor :config, :client, :dispatcher

      class << self
        def start
          self.config = AHN_CONFIG.punchblock
          self.client = ::Punchblock::Rayo.new self.config.connection_options
          self.dispatcher = Dispatcher.new self.client

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
              dispatcher.start
            rescue => e
              ahn_log.punchblock.fatal "Failed to start Punchblock client! #{e.inspect}"
              abort
            end
          end
        end
      end
    end # PunchblockInitializer
  end # Initializer
end # Adhearsion
