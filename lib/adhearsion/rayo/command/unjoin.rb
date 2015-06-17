# encoding: utf-8

require 'adhearsion/rayo/command_node'

module Adhearsion
  module Rayo
    module Command
      class Unjoin < CommandNode
        register :unjoin, :core

        # @return [String] the call ID to unjoin
        attribute :call_uri
        alias :call_id= :call_uri=

        # @return [String] the mixer name to unjoin
        attribute :mixer_name

        def rayo_attributes
          {'call-uri' => call_uri, 'mixer-name' => mixer_name}
        end
      end
    end
  end
end
