require 'adhearsion/voip/asterisk'
module Adhearsion
  class Initializer
    
    class AsteriskInitializer
      
      cattr_accessor :config, :agi_server, :ami_client
      class << self
        
        def start
          self.config     = AHN_CONFIG.asterisk
          self.agi_server = initialize_agi
          self.ami_client = initialize_ami if config.ami_enabled?
          join_server_thread_after_initialized
        end

        def stop
          agi_server.stop
          ami_client.disconnect! if ami_client
        end

        private

        def initialize_agi
          VoIP::Asterisk::AGI::Server.new :host => config.listening_host,
                                                      :port => config.listening_port
        end
        
        def initialize_ami
          options = ami_options
          start_ami_after_initialized
          VoIP::Asterisk::AMI.new options[:username], options[:password],
                                              options[:host], :port => options[:port],
                                              :events => options[:events]
        end
        
        def ami_options
          %w(host port username password events).inject({}) do |options, property|
            options[property.to_sym] = config.ami.send property
            options
          end
        end
        
        def join_server_thread_after_initialized
          Events.register_callback(:after_initialized) { agi_server.start }
          IMPORTANT_THREADS << agi_server
        end
        
        def start_ami_after_initialized
          Events.register_callback(:after_initialized) { ami_client.connect! }
        end

      end
    end
    
  end
end
