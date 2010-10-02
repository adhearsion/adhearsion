require 'adhearsion/voip/asterisk'
module Adhearsion
  class Initializer

    class AsteriskInitializer

      cattr_accessor :config, :agi_server, :ami_client
      class << self

        def start
          self.config     = AHN_CONFIG.asterisk
          self.agi_server = initialize_agi
          self.ami_client = VoIP::Asterisk.manager_interface = initialize_ami if config.ami_enabled?
          join_server_thread_after_initialized

          # Make sure we stop everything when we shutdown
          Events.register_callback(:shutdown) do
            ahn_log.info "Shutting down with #{Adhearsion.active_calls.size} active calls"
            self.stop
          end
        end

        def stop
          agi_server.graceful_shutdown
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
          returning VoIP::Asterisk::Manager::ManagerInterface.new(options) do
            class << VoIP::Asterisk
              if respond_to?(:manager_interface)
                ahn_log.warn "Asterisk.manager_interface already initialized?"
              else
                def manager_interface
                  # ahn_log.ami.warn "Warning! This Asterisk.manager_interface() notation is for Adhearsion version 0.8.0 only. Subsequent versions of Adhearsion will use a feature called SuperManager. Migrating to use SuperManager will be very simple. See http://docs.adhearsion.com/AMI for more information."
                  Adhearsion::Initializer::AsteriskInitializer.ami_client
                end
              end
            end
          end
        end

        def ami_options
          %w(host port username password events auto_reconnect).inject({}) do |options, property|
            options[property.to_sym] = config.ami.send property
            options
          end
        end

        def join_server_thread_after_initialized
          Events.register_callback(:after_initialized) do
            begin
              agi_server.start
            rescue => e
              ahn_log.fatal "Failed to start AGI server! #{e.inspect}"
              abort
            end
          end
          IMPORTANT_THREADS << agi_server
        end

        def start_ami_after_initialized
          Events.register_callback(:after_initialized) do
            begin
              self.ami_client.connect!
            rescue Errno::ECONNREFUSED
              ahn_log.ami.error "Connection refused when connecting to AMI! Please check your configuration."
            rescue => e
              ahn_log.ami.error "Error connecting to AMI! #{e.inspect}"
            end
          end
        end

      end
    end

  end
end
