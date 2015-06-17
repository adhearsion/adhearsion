# encoding: utf-8

require 'adhearsion/rayo/command_node'
require 'adhearsion/has_headers'

module Adhearsion
  module Rayo
    module Command
      class Redirect < CommandNode
        register :redirect, :core

        include HasHeaders

        # @return [String] the redirect target
        attribute :to

        def rayo_attributes
          {'to' => to}
        end
      end
    end
  end
end
