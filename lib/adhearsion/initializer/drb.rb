require 'drb'
require 'drb/acl'
require 'thread'

module Adhearsion
  class Initializer

    class Drb

      class << self

        def start
          config = Adhearsion::AHN_CONFIG.drb
          DRb.install_acl ACL.new(config.acl) if config.acl

          drb_door = Object.new
          Plugin.add_rpc_methods(drb_door)

          DRb.start_service "druby://#{config.host}:#{config.port}", drb_door

          logger.info "Starting DRb on #{config.host}:#{config.port}"
        end

        def stop
          DRb.stop_service
        end

      end
    end
  end
end
