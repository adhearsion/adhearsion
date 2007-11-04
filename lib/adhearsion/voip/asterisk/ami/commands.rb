module Adhearsion
  module VoIP
    module Asterisk
      class AMI
        module Commands
          class Command
            @@subclasses = []
            
            attr_accessor :action
            attr_accessor :action_id
            
            class << self
              # Return a new instance of the command. Make sure to return an instance
              # of the command-specific subclass if it exists.
              def build(name, hash)
                name = name.to_s
                entry = @@subclasses.find { |klass| klass.downcase == name.downcase }
                klass = entry ? Commands.const_get("#{entry}Command") : self
                klass.new(name, hash)
              end

              # Keep a list of the subclasses.
              def inherited(klass)
                @@subclasses << klass.to_s.split("::").last.match(/(.*?)Command/)[1]
              end
            end

            def initialize(name, hash)
              @action = name.downcase
              @action_id = __action_id
              @arguments = {}
              # Normalize the keys
              hash.each_pair { |k,v| @arguments[k.to_s.downcase] = v }
            end
            
            # Return true if this is an 'immediate' command, i.e., it returns raw
            # results synchronously without a response header.
            # Don't bother doing this in subclasses. It is easy enough.
            def immediate?
              %w(iaxpeers queues).include? @action
            end
            
            # Return true if this action will return events that we will wait on.
            def async?
              follows? or %w(dbget originate).include? @action
            end

            # Commands of the form "Response: <Command> results will follow"
            def follows?
              %w(parkedcalls queuestatus agents status sippeers zapshowchannels).include? @action
            end

            # Virtually all commands return a response. There is at least one
            # exception, handled with a command-specific subclass.
            def has_response?
              true
            end

            # Return true if this packet completes the command, i.e., there is
            # no more response data to receive for this command.
            def completed_by?(packet)
              return true if not async?
              return false if not packet.is_event?
              packet.event.downcase == "#{@action}complete"
            end

            # Return true if the packet should be included in the response. Raw and
            # synchronous responses are kept. Some event responses are rejected.
            def keep?(packet)
              return true if not async?
              return false if not packet.is_event?
              return keep_event?(packet)
            end
            
            # By default, we keep any event packet, unless it is the completion
            # packet for a 'follows' command. These are just marker packets that
            # signify the end of the event stream for the response.
            # TODO: They do contain a count of the events generated, which perhaps
            # we want to verify matches the number we think we have received?
            def keep_event?(packet)
              !(completed_by?(packet) and follows?)
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

          class OriginateCommand < Command
            # Return true if this action will return events, i.e. it is asynchronous.
            # This is controlled by the 'Async' argument to the command.
            def async?
              @arguments['async'] == true
            end

            # Returns true when the terminating marker packets are seen when the
            # command is invoked asyncrhonously.
            def completed_by?(packet)
              return true if not async?
              return false if not packet.is_event?
              %w(Hangup OriginateFailed).include?(packet.message)
            end
          end
          
          class DBGetCommand < Command
            # Needed only because this asynchronous response (when the
            # command succeeds) does not return a response with the
            # name "DBGetComplete".
            def completed_by?(packet)
              return true if not async?
              return false if not packet.is_event?
              packet.event == "DBGetResponse"
            end
          end

          class SIPpeersCommand < Command
            # Sigh. The only reason for this is that the naming
            # convention differs.
            def completed_by?(packet)
              return true if not async?
              return false if not packet.is_event?
              packet.event == "PeerlistComplete"
            end
          end
          
          class EventsCommand < Command
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