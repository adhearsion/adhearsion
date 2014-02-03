# encoding: utf-8

module Adhearsion
  class Router
    module OpenendedRoute
      def openended?
        true
      end

      def dispatch(call, callback = nil)
        call.auto_hangup = false
        super
      end
    end
  end
end
