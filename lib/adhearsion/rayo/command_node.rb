# encoding: utf-8

require 'state_machine'
require 'future-resource'
require 'adhearsion/rayo/rayo_node'

module Adhearsion
  module Rayo
    class CommandNode < RayoNode

      attribute :request_id, String, default: ->(*) { Adhearsion.new_request_id }

      def initialize(*args)
        super
        @response = FutureResource.new
      end

      state_machine :state, :initial => :new do
        event :request do
          transition :new => :requested
        end

        event :execute do
          transition :requested => :executing
        end

        event :complete do
          transition :executing => :complete
        end
      end

      def response(timeout = nil)
        @response.resource timeout
      end

      def response=(other)
        return if @response.set_yet?
        @response.resource = other
        execute!
      rescue StateMachine::InvalidTransition => e
        e.message << " for command #{self}"
        raise e
      rescue FutureResource::ResourceAlreadySetException
      end
    end
  end
end
