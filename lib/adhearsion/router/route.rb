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
    end
  end
end
