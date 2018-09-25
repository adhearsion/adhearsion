# encoding: utf-8

require 'adhearsion/has_headers'

module Adhearsion
  module Rayo
    module Component
      class App < ComponentNode
        register :app, :exec

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




