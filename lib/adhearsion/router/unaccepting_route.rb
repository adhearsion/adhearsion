# encoding: utf-8

module Adhearsion
  class Router
    module UnacceptingRoute
      def accepting?
        false
      end
    end
  end
end
