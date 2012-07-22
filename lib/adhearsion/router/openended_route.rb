# encoding: utf-8

module Adhearsion
  class Router
    module OpenendedRoute
      def openended?
        true
      end

      def dispatch(call, callback = nil)
        call[:ahn_prevent_hangup] = true
        super
      end
    end
  end
end
