require 'timeout'

module Adhearsion
  class Initializer
    class Punchblock
      cattr_accessor :config, :client, :dispatcher

      class << self
        def start
          self.config = AHN_CONFIG.punchblock
          connection = ::Punchblock::Connection::XMPP.new self.config.connection_options
          self.client = ::Punchblock::Client.new :connection => connection
          self.dispatcher = Dispatcher.new self.client.event_queue

          # Make sure we stop everything when we shutdown
          Events.register_callback(:shutdown) do
            logger.info "Shutting down with #{Adhearsion.active_calls.size} active calls"
            client.stop
          end

          connect
        end

        def connect
          Events.register_callback(:after_initialized) do
            begin
              IMPORTANT_THREADS << Thread.new do
                catching_standard_errors { client.run }
              end
              first_event = nil
              Timeout::timeout(30) { first_event = client.event_queue.pop }
              if first_event == client.connected
                logger.info "Connected via Punchblock"
                IMPORTANT_THREADS << dispatcher.start
              else
                logger.fatal "Failed to connect via Punchblock"
              end
            rescue => e
              logger.fatal "Failed to start Punchblock client! #{e.inspect}"
              abort
            end
          end
        end
      end
    end # PunchblockInitializer
  end # Initializer
end # Adhearsion
