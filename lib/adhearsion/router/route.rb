# encoding: utf-8

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
        @dispatcher ||= lambda do |call, callback = nil|
          controller = if target.respond_to?(:call)
            CallController.new call, &target
          else
            target.new call
          end

          call.execute_controller controller, lambda { |call|
            begin
              call.hangup
            rescue Call::Hangup
            end
            callback.call if callback
          }
        end
      end

      def inspect
        "#<#{self.class}:#{object_id} name=#{name} target=#{target} guards=#{guards}>"
      end
      alias :to_s :inspect
    end
  end
end
