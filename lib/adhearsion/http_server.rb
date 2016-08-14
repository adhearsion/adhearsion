# encoding: utf-8

require 'reel'
require 'reel/rack'

module Adhearsion
  # @private
  class HTTPServer < Reel::Rack::Server
    include Celluloid::Internals::Logger

    def self.start
      config = Adhearsion.config.core.http

      return unless config.enable

      rackup = File.join(Adhearsion.root, config.rackup)
      unless File.exists?(rackup)
        logger.error "Cannot start HTTP server because the Rack configuration does not exist at #{rackup}"
        return
      end

      app, options = ::Rack::Builder.parse_file rackup
      options = {
        Host: config.host,
        Port: config.port,
      }.merge(options)

      app = Rack::CommonLogger.new(app, logger)

      logger.info "Starting HTTP server listening on #{config.host}:#{config.port}"

      supervisor = self.supervise(as: :ahn_http_server, args: [app, options])

      Adhearsion::Events.register_callback :shutdown do
        supervisor.terminate
      end
    end
  end
end
