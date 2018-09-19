# encoding: utf-8

require 'adhearsion/rayo/command_node'
require 'adhearsion/has_headers'

module Adhearsion
  module Rayo
    module Command
      class App < CommandNode
        register :app, :core

        include HasHeaders

        #@return The application to run
        attribute :app

        #@return The arguments to pass
        attribute :args

        def rayo_attributes
          {'app' => app, 'args' => args}
        end

        def response=(resp)
          logger.debug "RESPONSE GETTING SET TO #{resp.inspect}"
          super
        end
      end
    end
  end
end



