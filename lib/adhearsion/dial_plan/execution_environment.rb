module Adhearsion
  class DialPlan
    ##
    # Executable environment for a dial plan in the scope of a call. This class has all the dialplan methods mixed into it.
    #
    class ExecutionEnvironment

      class << self
        def create(*args)
          new(*args).tap { |instance| instance.stage! }
        end
      end

      attr_reader :call

      def initialize(call, entry_point)
        @call, @entry_point = call, entry_point
      end

      ##
      # Adds the methods to this ExecutionEnvironment which make it useful. e.g. dialplan-related methods, call variables,
      # and component methods.
      #
      def stage!
        extend_with_voip_commands!
        extend_with_dialplan_component_methods!
      end

      def run
        raise "Cannot run ExecutionEnvironment without an entry point!" unless entry_point
        current_context = entry_point
        answer if AHN_CONFIG.automatically_answer_incoming_calls
        begin
          instance_eval &current_context
        rescue Adhearsion::DSL::Dialplan::ControlPassingException => exception
          current_context = exception.target
          retry
        end
      end

      protected

      attr_reader :entry_point

      def extend_with_voip_commands!
        extend Adhearsion::Conveniences
        extend Adhearsion::Commands.for call.originating_voip_platform
      end

      def extend_with_dialplan_component_methods!
        Components.component_manager.extend_object_with(self, :dialplan) if Components.component_manager
      end

      def ahn_log(*args)
        @call.ahn_log *args
      end

    end
  end
end
