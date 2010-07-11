require 'blather/client/client'
require 'blather/client/dsl'

module Adhearsion
  class XMPPBot

    cattr_accessor :client
    class << self
      include Blather::DSL

      def start(jid, password, server, port)
        Blather.logger = ahn_log.xmpp
        setup_client_object(jid, password, server, port)
        register_event_namespaces
        register_default_client_handlers
        Events.register_callback(:after_initialized) do
          connect
        end
      end
      
      def stop
        shutdown
      end

      private

      def setup_client_object(jid, password, server, port)
        self.client = Blather::Client.setup(jid, password, server, port)
      end
      
      def connect
        EventMachine.run {client.connect}
      end
      
      def register_event_namespaces
        Events.register_namespace_name "/xmpp"
      end
      
      def register_default_client_handlers
        client.register_handler(:ready) do
          ahn_log.xmpp.info "Connected to XMPP server! Send messages to #{client.jid.stripped}."
        end
        
        client.register_handler(:disconnected) do
          ahn_log.xmpp.error "Disconnected. Restart Adhearsion to connect again."
          # Events.trigger :shutdown
          # TODO: fix this to reconnect XMPP Bot cleanly
        end
      end

    end

  end
end