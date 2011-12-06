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
  end
end
