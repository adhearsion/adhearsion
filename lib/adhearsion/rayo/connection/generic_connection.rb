# encoding: utf-8

module Adhearsion
  module Rayo
    module Connection
      class GenericConnection
        def initialize
          @event_handler = lambda { |event| raise 'No event handler set' }
        end

        def ready!
        end

        def not_ready!
        end

        def connected?
        end
      end
    end
  end
end
