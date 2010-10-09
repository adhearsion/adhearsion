require 'gserver'

require 'adhearsion/voip/dsl/dialplan/thread_mixin'
require 'adhearsion/voip/dsl/dialplan/parser'
require 'adhearsion/voip/dsl/dialplan/dispatcher'
require 'adhearsion/voip/freeswitch/basic_connection_manager'
require 'adhearsion/voip/freeswitch/freeswitch_dialplan_command_factory'

module Adhearsion
  module VoIP
    module FreeSwitch
      class OesServer < GServer

        def initialize(port, host=nil)
          @port, @host = port || 4572, host || "0.0.0.0"
          @cache_lock = Mutex.new
          super @port, @host, (1.0/0.0)
          log "Starting FreeSwitch OES Server"
        end

        def serve(io)

          log "Incoming call on the FreeSwitch outbound event socket..."
          Thread.me.extend DSL::Dialplan::ThreadMixin
          Thread.me.call.io = io
          conn = BasicConnectionManager.new io

          Thread.my.call.mgr = conn
          conn << "connect"
          @vars = conn.get_header
          answered = @vars['variable_endpoint_disposition'] == "ANSWER"

          conn << "myevents"
          myevents_response = conn.get_header
          answered ||= myevents_response['Event-Name'] == 'CHANNEL_ANSWER'

          log "Connected to Freeswitch. Waiting for answer state."

          until answered
            answered ||= conn.get_header['Event-Name'] == 'CHANNEL_ANSWER'
          end

          log "Loading cached dialplan"
          contexts, dispatcher = cached_dialplan_data
          log "Finished loading cached dialplans"

          first_context_name  = @vars['variable_context'] || @vars["Channel-Context"]
          first_context       = contexts[first_context_name.to_sym]

          log "Found context #{first_context_name} from call variables."

          # If the target context does not exist, warn and don't handle the call
          unless first_context
            log "No context '#{first_context_name}' found in " +
                "#{AHN_CONFIG.files_from_setting("paths", "").to_sentence(:connector => "or")}. Ignoring request!"
            return
          end

          # Enable events

          # Now that we have the code, let's dispatch it back.

          pretty_vars = rubyize_keys_for @vars
          dispatcher.def_keys! pretty_vars
          dispatcher.instance_eval(&first_context.block)

        rescue => e
          p e
          puts e.backtrace.map {|x| " " * 4 + x }
        end

        def cached_dialplan_data
          @cache_lock.synchronize do
            log "Checking whether the contexts should be reloaded"
            if should_reload_contexts?
              log "Getting the contexts"
              @abstract_contexts = DSL::Dialplan::DialplanParser.get_contexts
              log "Creating a new OesDispatcher"
              @abstract_dispatcher = OesDispatcher.new @vars['Channel-Unique-ID']
              log "Done creating it"
              @abstract_dispatcher.def_keys! @abstract_contexts
            else
              log "Should not reload context."
              @abstract_dispatcher.instance_variable_set :@uuid, @vars['Channel-Unique-ID']
            end
            return [@abstract_contexts.clone, @abstract_dispatcher.clone]
          end
        end

        # TODO. This is broken. Always returns true. Should cache the last reload
        # time.
        def should_reload_contexts?
          !@abstract_contexts || !@abstract_dispatcher ||
            AHN_CONFIG.files_from_setting("paths", "dialplan").map { |x| File.mtime(x) }.max < Time.now
        end

        def rubyize_keys_for(hash)
          {}.tap do |pretty|
            hash.each { |k,v| pretty[k.to_s.underscore] = v }
          end
        end

        class OesDispatcher < DSL::Dialplan::CommandDispatcher

          def initialize(uuid=nil)
            super FreeSwitchDialplanCommandFactory, uuid
          end

          def dispatch!(event)
            if event.kind_of?(DSL::Dialplan::NoOpEventCommand) && event.on_keypress
              return_value = nil
              dispatch = lambda do
                loop do
                  Thread.my.call.mgr.get_raw_header
                  async_event = Thread.my.call.mgr.get_header
                  if async_event['Event-Name'] == 'DTMF'
                    key = async_event['DTMF-String']
                    return_value = event.on_keypress.call(('0'..'9').include?(key) ? key.to_i : key)
                  end
                end
              end
              if event.timeout
                begin
                  Timeout.timeout event.timeout, &dispatch
                rescue Timeout::Error
                  break!
                  return_value
                end
              else dispatch.call
              end

            else
              log "Not a noop. Sending #{event.app}(#{event.args.to_a * " "})"
              Thread.my.call.mgr << "SendMsg\ncall-command: execute\nexecute-app-name: " +
                "#{event.app}\nexecute-app-arg: #{event.args.to_a * " "}"

              if event.kind_of? DSL::Dialplan::ExitingEventCommand
                Thread.my.call.io.close
                Thread.me.exit
              end

              # Useless "command/reply" +OK and content-length headers
              lambda do
                Thread.my.call.mgr.get_raw_header
                redo if Thread.my.call.mgr.get_header['Event-Name'] == "CHANNEL_EXECUTE_COMPLETE"
              end.call

              # Main event information. Keep track of the Core-UUID and wait for
              # it to come back to us as a CHANNEL_EXECUTE_COMPLETE event.
              execution_header = Thread.my.call.mgr.get_header
              execution_uuid = execution_header['Core-UUID']

              loop do
                log "Waiting for either a DTMF or the app to finish"
                hdr = Thread.my.call.mgr.get_raw_header
                log "Got head #{hdr}"

                if hdr == "Content-Type: api/response\nContent-Length: 0"
                  break
                end

                async_event = Thread.my.call.mgr.get_header
                event_name = async_event['Event-Name']
                if event_name == 'DTMF' && event.on_keypress
                  key = async_event['DTMF-String']
                  event.on_keypress.call(('0'..'9') === key ? key.to_i : key)
                elsif event_name == 'CHANNEL_EXECUTE_COMPLETE' && async_event['Core-UUID'] == execution_uuid
                  break async_event
                else

                end
              end
            end
          rescue DSL::Dialplan::ReturnValue => r
            log "Dispatch!: Got a return value with #{r.obj}"
            break!
            raise r
          rescue DSL::Dialplan::Hangup
            Thread.my.call.mgr << "SendMsg\ncall-command: hangup"
            Thread.my.call.mgr.io.close rescue nil
          end

          def break!(uuid=@context)
            log "Breaking with #{uuid}"
            Thread.my.call.mgr << "api break #{uuid}"
            Thread.my.call.mgr.get_raw_header
            # Thread.my.call.mgr.get_raw_header
            # Thread.my.call.mgr.get_raw_header
          end
        end

      end
    end
  end
end
