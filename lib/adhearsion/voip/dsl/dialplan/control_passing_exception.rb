module Adhearsion
  module VoIP
    module DSL
      module Dialplan
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

        class ContextNotFoundException < StandardError; end
      end
    end
  end
end