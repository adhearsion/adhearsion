# encoding: utf-8

module Adhearsion
  class Router
    module EventedRoute
      def evented?
        true
      end

      def dispatch(call, callback = nil)
        target.call call, callback
      end
    end
  end
end
