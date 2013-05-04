# encoding: utf-8

require 'has_guarded_handlers'

module Adhearsion
  class Router
    class Route
      include HasGuardedHandlers

      attr_reader :name, :target, :guards
      attr_accessor :controller_metadata

      def initialize(name, target = nil, *guards, &block)
        @name = name
        if block
          @target, @guards = block, ([target] + guards)
        else
          @target, @guards = target, guards
        end
        @guards.compact!
        @controller_metadata = nil
      end

      def match?(call)
        !guarded? guards, call
      end

      def dispatch(call, callback = nil)
        Adhearsion::Events.trigger_immediately :call_routed, call: call, route: self

        controller = if target.respond_to?(:call)
          CallController.new call, controller_metadata, &target
        else
          target.new call, controller_metadata
        end

        call.accept if accepting?

        call.execute_controller controller, lambda { |call_actor|
          begin
            if call_actor[:ahn_prevent_hangup]
              logger.info "Call routing completed, keeping the call alive at controller/router request."
            else
              call_actor.hangup
            end
          rescue Call::Hangup, Call::ExpiredError
          end
          callback.call if callback
        }
      end

      def evented?
        false
      end

      def accepting?
        true
      end

      def openended?
        false
      end

      def inspect
        "#<#{self.class}:#{object_id} name=#{name} target=#{target} guards=#{guards}>"
      end
      alias :to_s :inspect
    end
  end
end
