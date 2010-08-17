module Adhearsion
  module XMPP
    module Connection

      mattr_accessor :client
      class << self

        # Open the XMPP connection
        #
        # @param [String] jid the client/component JID to connect to
        # @param [String] password
        # @param [String] server
        # @param [Integer] port
        def start(jid, password, server, port)
          Blather.logger = ahn_log.xmpp
          setup_client_object(jid, password, server, port)
          register_event_namespaces
          register_default_client_handlers
          Events.register_callback(:after_initialized) do
            connect
          end
        end

        # Close the XMPP connection
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
            if Adhearsion.status == :running
              ahn_log.xmpp.warning "XMPP Disconnected. Reconnecting."
              connect
            end
            # TODO: fix this to reconnect XMPP cleanly
          end
        end

      end

    end
  end
end