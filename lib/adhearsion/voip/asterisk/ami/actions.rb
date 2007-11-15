module Adhearsion
  module VoIP
    module Asterisk
      class AMI
        module Actions
          class Action
            @@subclasses = []
            @@actions = {}
            
            attr_accessor :action
            attr_accessor :action_id
            
            class << self              
              # Return a new instance of the command. Make sure to return an instance
              # of the command-specific subclass if it exists.
              def build(name, hash, &block)
                name = name.to_s
                entry = @@subclasses.find { |klass| klass.downcase == name.downcase }
                klass = entry ? Actions.const_get("#{entry}Action") : self
                obj = klass.new(name, hash, &block)
                self[obj.action_id] = obj
              end

              # Keep a list of the subclasses.
              def inherited(klass)
                @@subclasses << klass.to_s.split("::").last.match(/(.*?)Action/)[1]
              end
              
              def [](key)
                @@actions[key]
              end

              def []=(key, action)
                @@actions[key] = action
              end
            end

            def initialize(name, hash, &block)
              @action = name.downcase
              @action_id = __action_id
              @arguments = {}
              @packets = []
              @sync_complete = false
              @error = nil

              # Normalize the keys
              hash.each_pair { |k,v| @arguments[k.to_s.downcase] = v }

              if block and not async?
                raise RuntimeError, "Cannot specify completion callback for synchronous command"
              end
              @async_completion_callback = block
            end
            
            def <<(packet)
              if packet.error?
                @error = packet.message
                complete_sync!
              end
              
              # We don't keep every packet, just the important ones.
              @packets << packet if keep?(packet)

              # Check if the synchronous portion of the action is done.
              if completed_by?(packet)
                # The synchronous portion is done.
                complete_sync!
                
                # We're totally done if it is not asynchronous.
                complete! if not async?
              end

              # Check if this is an asynchronous action, and we have received the last event
              complete_async! if completed_by_async?(packet)
            end
            
            def done?
              @sync_complete
            end
            
            def packets!
              packets, @packets = @packets, []
              packets.inject([]) do |arr, pkt|
                pkt = pkt.body.inject({}) do |hash, (k, v)|
                  hash[k] = v
                  hash
                end
                arr << pkt if not pkt.blank?
                arr
              end
            end
            
            def check_error!
              raise ActionError, @error if @error
            end
            
            # Return true if this is an 'immediate' command, i.e., it returns raw
            # results synchronously without a response header.
            # Don't bother doing this in subclasses. It is easy enough.
            def immediate?
              %w(iaxpeers queues).include? @action
            end
            
            # Return true if this action will return matching events that we will wait on.
            def waits_for_events?
              follows? or %w(dbget).include? @action
            end

            # Return true if this action returns matching events that we will not wait on,
            # but can access at a later time.
            def async?
              false
            end

            # Actions of the form "Response: <Action> results will follow"
            def follows?
              %w(parkedcalls queuestatus agents status sippeers zapshowchannels).include? @action
            end

            # Virtually all commands return a response. There is at least one
            # exception, handled with a command-specific subclass.
            def has_response?
              true
            end

            # Return true if this packet completes the command, i.e., there is
            # no more synchronous response data to receive for this command.
            def completed_by?(packet)
              return true if not waits_for_events?
              return false if not packet.is_event?
              packet.event.downcase == "#{@action}complete"
            end

            # Return true if this packet completes the matching asynchronous
            # events for this command.
            def completed_by_async?(packet)
              return false if not async?
              return false if not packet.is_event?
              statuses = %w(success failure).collect { |status| "#{@action}#{status}" }
              statuses.include?(packet.event.downcase)
            end
            
            def complete_sync!
              @sync_complete = true
            end

            def complete_async!
              @async_completion_callback.call(self.packets) if @async_completion_callback
              complete!
            end

            def complete!
							Action[@action_id] = nil
            end

            # Return true if the packet should be included in the response. Raw and
            # synchronous responses are kept. Some event responses are rejected.
            def keep?(packet)
              return true if not waits_for_events?
              return false if not packet.is_event?
              return keep_event?(packet)
            end
            
            # By default, we keep any event packet, unless it is the completion
            # packet for a 'follows' command. These are just marker packets that
            # signify the end of the event stream for the response.
            # TODO: They do contain a count of the events generated, which perhaps
            # we want to verify matches the number we think we have received?
            def keep_event?(packet)
              return false if (follows? and completed_by?(packet))
              true
            end

            def to_s
              __args_to_str
            end
            
            private

            # Immediate commands do not return response headers, so there is no
            # chance (or need) to get an action id. We'll make those packets
            # action ids to be 0 artificially.
            def __action_id
              immediate? ? 0 : Time.now.to_f.to_s
            end

            def __args_to_str
              action = ""
              action << "action: #{@action}\r\n"
              action << "actionid: #{@action_id}\r\n"
              @arguments.keys.sort { |a,b| a.to_s <=> b.to_s }.each { |k| action << "#{k}: #{@arguments[k]}\r\n" }
              action << "\r\n"
            end
          end

          class OriginateAction < Action
            # Return true if this action will return events, i.e. it is asynchronous.
            # This is controlled by the 'Async' argument to the command.
            def async?
              @arguments['async'] == true
            end
          end
          
          class DBGetAction < Action
            # Needed only because this asynchronous response (when the
            # command succeeds) does not return a response with the
            # name "DBGetComplete".
            def completed_by?(packet)
              return true if not waits_for_events?
              return false if not packet.is_event?
              packet.event == "DBGetResponse"
            end
          end

          class SIPpeersAction < Action
            # Sigh. The only reason for this is that the naming
            # convention differs.
            def completed_by?(packet)
              return true if not waits_for_events?
              return false if not packet.is_event?
              packet.event == "PeerlistComplete"
            end
          end
          
          class EventsAction < Action
            # Again, this is a command that is subclassed due to interface
            # inconsistency. If the command turns on events with the mask
            # of "On", there is no response. If it is "Off" or set on for
            # specific events, there is a reponse. Ugly.
            def has_response?
              @arguments['eventmask'] !~ /^on$/i
            end
          end
        end
      end
    end
  end
end