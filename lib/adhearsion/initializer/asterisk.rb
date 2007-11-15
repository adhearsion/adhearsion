require 'adhearsion/voip/asterisk'
module Adhearsion
  class Initializer
    
    class AsteriskInitializer
      
      cattr_accessor :config, :agi_server, :ami_server
      class << self
        
        def start
          self.config     = Adhearsion::AHN_CONFIG.asterisk
          self.agi_server = initialize_agi
          self.ami_server = initialize_ami if config.ami_enabled?
          join_server_thread_after_initialized
        end

        def stop
          agi_server.stop
          ami_server.disconnect! if ami_server
        end

        private

        def initialize_agi
          Adhearsion::VoIP::Asterisk::AGI::Server.new :host => config.listening_host,
                                                      :port => config.listening_port
        end
        
        def initialize_ami
          options = ami_options
          start_ami_after_initialized
          Adhearsion::VoIP::Asterisk::AMI.new options[:username], options[:password],
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
          Adhearsion::Hooks::AfterInitialized.create_hook do
            agi_server.start
            agi_server.join
          end
        end
        
        def start_ami_after_initialized
          Adhearsion::Hooks::AfterInitialized.create_hook do
            ami_server.connect!
          end
        end

      end
    end
    
  end
end
