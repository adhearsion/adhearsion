module Adhearsion
  class Router
    class Route
      attr_reader :name, :target, :guards

      def initialize(name, target = nil, guards = nil, &block)
        @name = name
        if block
          @target, @guards = block, target
        else
          @target, @guards = target, guards
        end
      end
    end
  end
end
