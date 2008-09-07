require 'gserver'
module Adhearsion
  module VoIP
    module Asterisk
      module AGI
        class Server
          
          class RubyServer < GServer
            
            def initialize(port, host)
              super(port, host, (1.0/0.0)) # (1.0/0.0) == Infinity
            end
            
            def serve(io)
              Hooks::BeforeCall.trigger_hooks
          	  call = Adhearsion.receive_call_from(io)
          	  ahn_log.agi "Handling call with variables #{call.variables.inspect}"
          	  
          	  return DialPlan::ConfirmationManager.handle(call) if DialPlan::ConfirmationManager.confirmation_call?(call)
          	  
      	      # This is what happens 99.9% of the time.
      	      
      	      DialPlan::Manager.handle call
            rescue DialPlan::Manager::NoContextError => e
              ahn_log.agi e.message
              call.hangup!
            rescue FailedExtensionCallException => failed_call
              begin
                ahn_log.agi "Received \"failed\" meta-call with :failed_reason => #{failed_call.call.failed_reason.inspect}. Executing OnFailedCall hooks."
                Hooks::OnFailedCall.trigger_hooks(failed_call.call)
                call.hangup!
              rescue => e
                ahn_log.agi.error e
              end
            rescue HungupExtensionCallException => hungup_call
              begin
                ahn_log.agi "Received \"h\" meta-call. Executing OnHungupCall hooks."
                Hooks::OnHungupCall.trigger_hooks(hungup_call.call)
                call.hangup!
              rescue => e
                ahn_log.agi.error e
              end
            rescue UselessCallException
              ahn_log.agi "Ignoring meta-AGI request"
              call.hangup!
        	  # TBD: (may have more hooks than what Jay has defined in hooks.rb)
            rescue => e
              ahn_log.agi.error e.inspect
              ahn_log.agi.error e.backtrace.map { |s| " " * 5 + s }.join("\n")
            ensure
              Adhearsion.remove_inactive_call call rescue nil
            end
            
          end
         
          DEFAULT_OPTIONS = { :server_class => RubyServer, :port => 4573, :host => "0.0.0.0" } unless defined? DEFAULT_OPTIONS
          attr_reader :host, :port, :server_class, :server

          def initialize(options = {})
            options                     = DEFAULT_OPTIONS.merge options
            @host, @port, @server_class = options.values_at(:host, :port, :server_class)
            @server                     = server_class.new(port, host)
          end

          def start
            server.start
          end

          def shutdown
            server.stop
          end
          
          def join
            server.join
          end
          
        end
      end
    end
  end
end