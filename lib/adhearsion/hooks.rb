module Adhearsion


  module Hooks
    
    class GenericHook

      def initialize
        @hooks = []
      end

      def create_hook(&block)
        @hooks.synchronize do
          @hooks << block
        end
      end

      # TODO: This is hardly thread safe!
      def trigger_hooks
        @hooks.each &:call
      end
      
    end

    class HookWithArguments < GenericHook
      def trigger_hooks(*args)
        @hooks.each { |hook| hook.call(*args) }
      end
    end
    
    AfterInitialized = GenericHook.new
    OnFailedCall     = HookWithArguments.new
    
    TearDown = GenericHook.new
    class << TearDown
      def aliases
        [:before_shutdown]
      end
      
      def catch_termination_signals
        %w'INT TERM'.each do |sig|
          trap sig do
            ahn_log "Shutting down gracefully at #{Time.now}."
            Adhearsion::Hooks::TearDown.trigger_hooks
            exit
          end
        end
      end
    end
    
  end
end
