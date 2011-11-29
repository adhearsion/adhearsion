module Adhearsion
  module DSL
    class Dialplan

      extend ActiveSupport::Autoload

      autoload :CommandDispatcher
      autoload :ContextsEnvelope
      autoload :EventCommand
      autoload :ThreadMixin

      ContextNotFoundException = Class.new StandardError
      Hangup = Class.new StandardError

      ExitingEventCommand = Class.new EventCommand

      # A ControlPassingException is used internally to stop execution of one
      # dialplan context and begin execution of another proc instead. It is
      # most notably used by the ~@ unary operator that can be called on a
      # context name within a dialplan to transfer control entirely to that
      # particular context. The serve() method in the servlet_container actually
      # rescues these exceptions specifically and then does +e.target to execute
      # that code.
      class ControlPassingException < StandardError
        attr_reader :target

        def initialize(target)
          super()
          @target = target
        end
      end

      class ReturnValue < StandardError
        attr_reader :obj
        def initialize(obj)
          @obj = obj
          super
        end
      end

      class NoOpEventCommand < EventCommand
        attr_reader :timeout, :on_keypress

        def initialize(timeout = nil, hash = {})
          @timeout = timeout
          @on_keypress = hash[:on_keypress]
        end
      end
    end
  end
end
