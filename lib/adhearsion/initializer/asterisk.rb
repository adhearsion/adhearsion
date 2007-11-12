require 'adhearsion/voip/asterisk'
module Adhearsion
  class Initializer
    
    class AsteriskInitializer
      
      class << self
        
        def start
          @@config = Adhearsion::AHN_CONFIG.asterisk
          @@agi_server = Adhearsion::VoIP::Asterisk::AGI::Server.new :host => @@config.listening_host,
                                                                     :port => @@config.listening_port
          if @@config.ami_enabled?
            require 'adhearsion/voip/asterisk/ami'
            @@ami = Adhearsion::VoIP::Asterisk::AMI.new @@config.ami.username,
              @@config.ami.password,
              # Same as Asterisk host
              @@config.listening_host,
              # But a different port
              { :port => @@config.ami.port, :events => @@config.ami.events }
            start_ami_after_initialized
          end

          join_server_thread_after_initialized
        end

        def stop
          @@agi_server.stop
          @@ami.disconnect! if @@ami
        end

        private
        
        def join_server_thread_after_initialized
          Adhearsion::Hooks::AfterInitialized.create_hook do
            @@agi_server.start
            @@agi_server.join
          end
        end
        
        def start_ami_after_initialized
          Adhearsion::Hooks::AfterInitialized.create_hook do
            @@ami.connect!
          end
        end

      end
    end
    
  end
end
