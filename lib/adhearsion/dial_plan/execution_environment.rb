module Adhearsion
  class DialPlan
    ##
    # Executable environment for a dial plan in the scope of a call. This class has all the dialplan methods mixed into it.
    #
    class ExecutionEnvironment < CallController

      def initialize(call, entry_point)
        super(call)
        @entry_point = entry_point
        Plugin.add_dialplan_methods(self) if Plugin
        call.define_variable_accessors self
      end

      def run
        raise "Cannot run ExecutionEnvironment without an entry point!" unless @entry_point
        current_context = @entry_point
        accept if Adhearsion.config.platform.automatically_accept_incoming_calls
        begin
          instance_eval &current_context
        rescue Adhearsion::DSL::Dialplan::ControlPassingException => exception
          current_context = exception.target
          retry
        end
      end

      def variables
        call.variables
      end

      def logger
        call.logger
      end
    end
  end
end
