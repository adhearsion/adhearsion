module Adhearsion
  class Router
    extend ActiveSupport::Autoload

    autoload :Route

    attr_reader :routes

    def initialize(&block)
      @routes = []
      instance_exec &block
    end

    def route
      @routes << Route.new
    end
  end
end
