# encoding: utf-8

require 'has_guarded_handlers'
require 'active_support/core_ext/module/delegation'

module Adhearsion
  module Rayo
    class Client
      include HasGuardedHandlers

      attr_reader :connection, :component_registry

      delegate :run, :stop, :send_message, :new_call_uri, :to => :connection

      # @param [Hash] options
      # @option options [Connection::XMPP] :connection The connection to use for this session
      #
      def initialize(options = {})
        @connection = options[:connection]
        @connection.event_handler = lambda { |event| self.handle_event event } if @connection
        @component_registry = ComponentRegistry.new
      end

      def handle_event(event)
        event.client = self
        if event.source
          event.source.add_event event
        else
          trigger_handler :event, event
        end
      end

      def register_event_handler(*guards, &block)
        register_handler :event, *guards, &block
      end

      def register_component(component)
        component_registry << component
      end

      def find_component_by_uri(uri)
        component_registry.find_by_uri uri
      end

      def delete_component_registration(component)
        component_registry.delete component
      end

      def execute_command(command, options = {})
        command.client = self
        if command.respond_to?(:register_handler)
          command.register_handler :internal do |event|
            trigger_handler :event, event
          end
        end
        connection.write(command, **options)
      end
    end
  end
end

require 'adhearsion/rayo/client/component_registry'
