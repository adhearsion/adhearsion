# encoding: utf-8

require 'adhearsion/rayo/command_node'
require 'adhearsion/has_headers'

module Adhearsion
  module Rayo
    module Command
      class Answer < CommandNode
        register :answer, :core

        include HasHeaders
      end
    end
  end
end
