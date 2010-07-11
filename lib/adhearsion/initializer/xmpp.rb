require 'adhearsion/xmpp_bot.rb'

module Adhearsion
  class Initializer
    class XMPPInitializer

      cattr_accessor :config, :jid, :password, :server, :port
      class << self

        def start
          ahn_config    = Adhearsion::AHN_CONFIG
          self.config   = ahn_config.xmpp
          self.jid      = config.jid
          self.password = config.password
          self.server   = config.server
          self.port     = config.port
          
          XMPPBot.start(jid, password, server, port)
        end
        
        def stop
          XMPPBot.stop
        end

      end

    end
  end
end
