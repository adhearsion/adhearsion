require 'adhearsion/xmpp/connection.rb'

module Adhearsion
  class Initializer
    class XMPPInitializer

      cattr_accessor :config, :jid, :password, :server, :port
      class << self

        def start
          require_dependencies
          XMPP::Connection.extend Blather::DSL
          ahn_config    = Adhearsion::AHN_CONFIG
          self.config   = ahn_config.xmpp
          self.jid      = config.jid
          self.password = config.password
          self.server   = config.server
          self.port     = config.port

          XMPP::Connection.start(jid, password, server, port)
        end

        def stop
          XMPP::Connection.stop
        end

        private

        def require_dependencies
          begin
            require 'blather/client/client'
            require 'blather/client/dsl'
          rescue LoadError
            ahn_log.fatal "XMPP support requires the \"blather\" gem."
            # Silence the abort so we don't get an ugly backtrace
            abort ""
          end
        end
      end
    end
  end
end
