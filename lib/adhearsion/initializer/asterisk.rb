require 'adhearsion/voip/asterisk'
module Adhearsion
  class Initializer
    
    class AsteriskInitializer
      
      class << self
        
        def start
          @@config = Adhearsion::AHN_CONFIG.asterisk
          @@agi_server = Adhearsion::VoIP::Asterisk::AGI::Server.new :host => @@config.listening_host,
                                                                     :port => @@config.listening_port
          join_server_thread_after_initialized
        end

        def stop
          @@agi_server.stop
        end

        private
        
        def join_server_thread_after_initialized
          Adhearsion::Hooks::AfterInitialized.create_hook do
            @@agi_server.start
            @@agi_server.join
          end
        end

      end
    end
    
  end
end
