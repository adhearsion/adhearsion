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

            def disconnecting(port)
              @call.deliver_message :cancel if !@call.nil?
              super(port)
            end

            def serve(io)
              begin
                call = Adhearsion.receive_call_from(io)
              rescue EOFError
                # We didn't get the initial headers we were expecting
                return
              end

              Events.trigger_immediately([:asterisk, :before_call], call)
              ahn_log.agi.debug "Handling call with variables #{call.variables.inspect}"

              return DialPlan::ConfirmationManager.handle(call) if DialPlan::ConfirmationManager.confirmation_call?(call)

              # This is what happens 99.9% of the time.

              DialPlan::Manager.handle call
            rescue Hangup
              ahn_log.agi "HANGUP event for call with uniqueid #{call.variables[:uniqueid].inspect} and channel #{call.variables[:channel].inspect}"
              Events.trigger_immediately([:asterisk, :after_call], call)
              call.hangup!
            rescue DialPlan::Manager::NoContextError => e
              ahn_log.agi e.message
              call.hangup!
            rescue FailedExtensionCallException => failed_call
              begin
                ahn_log.agi "Received \"failed\" meta-call with :failed_reason => #{failed_call.call.failed_reason.inspect}. Executing Executing /asterisk/failed_call event callbacks."
                Events.trigger [:asterisk, :failed_call], failed_call.call
                call.hangup!
              rescue => e
                ahn_log.agi.error e
              end
            rescue HungupExtensionCallException => hungup_call
              begin
                ahn_log.agi "Received \"h\" meta-call. Executing /asterisk/hungup_call event callbacks."
                Events.trigger [:asterisk, :hungup_call], hungup_call.call
                call.hangup!
              rescue => e
                ahn_log.agi.error e
              end
            rescue UselessCallException
              ahn_log.agi "Ignoring meta-AGI request"
              call.hangup!
              # TBD: (may have more hooks than what Jay has defined in hooks.rb)
            rescue SyntaxError, StandardError => e
              Events.trigger(['exception'], e)
            ensure
              Adhearsion.remove_inactive_call call rescue nil
            end

            def log(msg)
              ahn_log.agi msg
            end

            def error(detail)
              ahn_log.agi.error detail.backtrace.join("\n")
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
            server.audit = true
            server.start
          end

          def graceful_shutdown
            if @shutting_down
              server.stop
              return
            end

            @shutting_down = true

            while server.connections > 0
              sleep 0.2
            end

            server.stop
          end

          def shutdown
            server.shutdown
          end

          def stop
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
