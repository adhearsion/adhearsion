# encoding: utf-8

require 'future-resource'
require 'has_guarded_handlers'
require 'adhearsion/rayo/command_node'

module Adhearsion
  module Rayo
    module Component
      class ComponentNode < CommandNode
        include HasGuardedHandlers

        def initialize(*args)
          super
          @complete_event_resource = FutureResource.new
          @mutex = Mutex.new
          register_internal_handlers
        end

        def register_internal_handlers
          register_handler :internal, Event::Complete do |event|
            self.complete_event = event
            throw :pass
          end
        end

        def add_event(event)
          trigger_handler :internal, event
        end

        def trigger_event_handler(event)
          trigger_handler :event, event
        end

        def register_event_handler(*guards, &block)
          register_handler :event, *guards, &block
        end

        def write_action(action)
          client.execute_command action, :target_call_id => target_call_id, :component_id => component_id
          action
        end

        def response=(other)
          @mutex.synchronize do
            if other.is_a?(Ref)
              @component_id = other.component_id
              @source_uri = other.uri.to_s
              client.register_component self if client
            end
            super
          end
        end

        def complete_event(timeout = nil)
          @complete_event_resource.resource timeout
        end

        def complete_event=(other)
          @mutex.synchronize do
            return if @complete_event_resource.set_yet?
            client.delete_component_registration self if client
            complete!
            @complete_event_resource.resource = other
          end
        rescue StateMachine::InvalidTransition => e
          e.message << " for component #{self}"
          raise e
        end

        ##
        # Create a Rayo stop message
        #
        # @return [Stop] a Rayo stop message
        #
        def stop_action
          Stop.new :component_id => component_id, :target_call_id => target_call_id
        end

        ##
        # Sends a Rayo stop message for the current component
        #
        def stop!(options = {})
          raise InvalidActionError, "Cannot stop a #{self.class.name.split("::").last} that is #{state}" unless executing?
          stop_action.tap { |action| write_action action }
        end
      end
    end
  end
end
