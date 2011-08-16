require 'punchblock'

module Adhearsion
  class Initializer
    class PunchblockInitializer
      cattr_accessor :config, :client

      class << self
        def start
          self.config = AHN_CONFIG.punchblock
          self.client = Punchblock::Rayo.new config

          Events.register_callback(:after_initialized) do
            begin
              IMPORTANT_THREADS << client.run
            rescue => e
              ahn_log.fatal "Failed to start Punchblock client! #{e.inspect}"
              abort
            end
          end

          # Make sure we stop everything when we shutdown
          Events.register_callback(:shutdown) do
            ahn_log.info "Shutting down with #{Adhearsion.active_calls.size} active calls"
            client.stop
          end
        end
      end
    end # PunchblockInitializer
  end # Initializer
end # Adhearsion
