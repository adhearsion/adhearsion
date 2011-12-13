module Adhearsion
  class Router
    class Route
      include HasGuardedHandlers

      attr_reader :name, :target, :guards

      def initialize(name, target = nil, *guards, &block)
        @name = name
        if block
          @target, @guards = block, ([target] + guards)
        else
          @target, @guards = target, guards
        end
        @guards.compact!
      end

      def match?(call)
        !guarded? guards, call
      end

      def dispatcher
        @dispatcher ||= lambda do |call|
          controller = if target.respond_to?(:call)
            DialplanController.new(call).tap do |controller|
              controller.dialplan = target
            end
          else
            target.new call
          end

          call.execute_controller controller
        end
      end
    end
  end
end
