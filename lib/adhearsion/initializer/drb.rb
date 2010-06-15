require 'drb'
require 'drb/acl'
require 'thread'

module Adhearsion
  class Initializer

    class DrbInitializer

      class << self

        def start
          config = Adhearsion::AHN_CONFIG.drb
          DRb.install_acl ACL.new(config.acl) if config.acl

          drb_door = Object.new
          Components.component_manager.extend_object_with(drb_door, :rpc)

          DRb.start_service "druby://#{config.host}:#{config.port}", drb_door

          ahn_log "Starting DRb on #{config.host}:#{config.port}"
        end

        def stop
          DRb.stop_service
        end

      end
    end
  end
end
