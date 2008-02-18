module Adhearsion

  class GenericHook
    
    def initialize
      @hooks = []
    end
    
    def create_hook(&block)
      @hooks.synchronize do
        @hooks << block
      end
    end

    def trigger_hooks
      @hooks.each &:call
    end
    
  end

  module Hooks
    
    AfterInitialized  = GenericHook.new
    
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
