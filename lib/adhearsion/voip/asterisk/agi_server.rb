require 'gserver'
module Adhearsion
  module VoIP
    module Asterisk
      module AGI
        class Server
          Thread.current.abort_on_exception=true
          
          class RubyServer < GServer
            
            def initialize(port, host)
              super(port, host, (1.0/0.0)) # (1.0/0.0) == Infinity
            end
            
            def serve(io)
              begin
            	  call = Adhearsion.receive_call_from io
            	  ahn_log.agi "Handling call with variables #{call.variables.inspect}"
            	  dialplan_manager = Adhearsion::DialPlan::Manager.new
                dialplan_manager.handle call
              rescue Adhearsion::DialPlan::Manager::NoContextError => e
                ahn_log.agi e.message
                call.hangup!
              rescue Adhearsion::FailedExtensionCallException => failed_call
                begin
                  ahn_log.agi "Received \"failed\" meta-call with :failed_reason => #{failed_call.call.failed_reason.inspect}. Executing OnFailedCall hooks."
                  Adhearsion::Hooks::OnFailedCall.trigger_hooks(failed_call.call)
                  call.hangup!
                rescue => e
                  p e
                end
              rescue Adhearsion::UselessCallException
                ahn_log.agi "Ignoring meta-AGI request"
                call.hangup!
              rescue => e
                ahn_log.agi.error e.inspect
                ahn_log.agi.error e.backtrace.map { |s| " " * 5 + s }.join("\n")
              end
          	  # TBD: (may have more hooks than what Jay has defined in hooks.rb)
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