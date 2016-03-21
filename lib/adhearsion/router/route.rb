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
        Adhearsion::Events.trigger :call_routed, call: call, route: self

        call_id = call.id # Grab this to use later incase the actor is dead

        controller = if target.respond_to?(:call)
          CallController.new call, controller_metadata, &target
        else
          target.new call, controller_metadata
        end

        call.accept if accepting?

        call.execute_controller controller, lambda { |call_actor|
          begin
            if call_actor.active?
              if call_actor.auto_hangup
                logger.info "Call #{call_id} routing completed. Hanging up now."
                call_actor.hangup
              else
                logger.info "Call #{call_id} routing completed. Keeping the call alive at controller/router request."
              end
            else
              logger.info "Call #{call_id} routing completed. Call was already hung up."
            end
          rescue Call::Hangup, Call::ExpiredError
          end
          callback.call if callback
        }
      rescue Call::Hangup, Call::ExpiredError
        logger.info "Call routing could not be completed because call was unavailable."
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
