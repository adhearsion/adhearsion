module Adhearsion
  class Router
    extend ActiveSupport::Autoload

    autoload :Route

    attr_reader :routes

    def initialize(&block)
      @routes = []
      instance_exec &block
    end

    def route(*args, &block)
      Route.new(*args, &block).tap do |route|
        @routes << route
      end
    end

    def match(call)
      @routes.find { |route| route.match? call }
    end

    def handle(call)
      return unless route = match(call)
      route.dispatcher
    end
  end
end
