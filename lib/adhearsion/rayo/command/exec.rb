# encoding: utf-8

require 'adhearsion/rayo/command_node'
require 'adhearsion/has_headers'

module Adhearsion
  module Rayo
    module Command
      class Exec < CommandNode
        register :exec, :core

        include HasHeaders

        #@return The application to run
        attribute :api

        #@return The arguments to pass
        attribute :args

        def rayo_attributes
          {'api' => api, 'args' => args}
        end

        def xml_tag_name
          registered_name + '_'
        end

      end
    end
  end
end

