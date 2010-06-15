require 'adhearsion/voip/freeswitch/basic_connection_manager'
module Adhearsion
  module VoIP
    module FreeSwitch
      class InboundConnectionManager < BasicConnectionManager

        DEFAULTS = { :pass => "ClueCon", :host => '127.0.0.1', :port => 8021 }

        def initialize(arg)
          if arg.kind_of? Hash
            @opts = DEFAULTS.merge arg
            @io = TCPSocket.new(@opts[:host], @opts[:port])
            super @io
            unless login(@opts[:pass])
              raise "Your FreeSwitch Event Socket password for #{@opts[:host]} was invalid!"
            end
          else arg.kind_of? IO
            @io = arg
            super @io
          end
        end

        def enable_events!(which='ALL')
          self << "event plain #{which}"
          get_raw_header
        end

        # Only called when nothing has been sent over the socket.
        def login(pass)
          get_raw_header
          self << "auth #{pass}"
          get_raw_header.include? "+OK"
        end

      end
    end
  end
end
