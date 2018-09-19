# encoding: utf-8

require 'ruby_jid'

module Adhearsion
  module Rayo
    ##
    # A rayo Response message that provides the response to an Exec.
    #
    class Response < RayoNode
      register :response, :core

      # @return [String] the Exec result
      attribute :response

      def rayo_attributes
        { 'response' => response }
      end
    end
  end
end

