module Adhearsion
  module Asterisk
    module Commands
      class QueueProxy
        class AgentProxy

          SUPPORTED_METADATA_NAMES = %w[status password name mohclass exten channel] unless defined? SUPPORTED_METADATA_NAMES

          class << self
            def id_from_agent_channel(id)
              id = id.to_s
              id.starts_with?('Agent/') ? id[%r[^Agent/(.+)$],1] : id
            end
          end

          attr_reader :interface, :proxy, :queue_name, :id
          def initialize(interface, proxy)
            @interface  = interface
            @id         = self.class.id_from_agent_channel interface
            @proxy      = proxy
            @queue_name = proxy.name
          end

          def remove!
            proxy.environment.execute 'RemoveQueueMember', queue_name, interface
            case proxy.environment.variable("RQMSTATUS")
              when "REMOVED"     then true
              when "NOTINQUEUE"  then false
              when "NOSUCHQUEUE"
                raise QueueDoesNotExistError.new(queue_name)
              else
                raise "Unrecognized RQMSTATUS variable!"
            end
          end

          # Pauses the given agent for this queue only. If you wish to pause this agent
          # for all queues, pass in :everywhere => true. Returns true if the agent was
          # successfully paused and false if the agent was not found.
          def pause!(options={})
            everywhere = options.delete(:everywhere)
            args = [(everywhere ? nil : queue_name), interface]
            proxy.environment.execute('PauseQueueMember', *args)
            case proxy.environment.variable("PQMSTATUS")
              when "PAUSED"   then true
              when "NOTFOUND" then false
              else
                raise "Unrecognized PQMSTATUS value!"
            end
          end

          # Pauses the given agent for this queue only. If you wish to pause this agent
          # for all queues, pass in :everywhere => true. Returns true if the agent was
          # successfully paused and false if the agent was not found.
          def unpause!(options={})
            everywhere = options.delete(:everywhere)
            args = [(everywhere ? nil : queue_name), interface]
            proxy.environment.execute('UnpauseQueueMember', *args)
            case proxy.environment.variable("UPQMSTATUS")
              when "UNPAUSED" then true
              when "NOTFOUND" then false
              else
                raise "Unrecognized UPQMSTATUS value!"
            end
          end

          # Returns true/false depending on whether this agent is logged in.
          def logged_in?
            status == 'LOGGEDIN'
          end

          private

          def status
            agent_metadata 'status'
          end

          def agent_metadata(data_name)
            data_name = data_name.to_s.downcase
            raise ArgumentError, "unrecognized agent metadata name #{data_name}" unless SUPPORTED_METADATA_NAMES.include? data_name
            proxy.environment.variable "AGENT(#{id}:#{data_name})"
          end

        end
      end
    end
  end
end
