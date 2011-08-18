module Adhearsion
  module Asterisk
    module Commands
      class QueueProxy
        class QueueAgentsListProxy
          include Enumerable

          attr_reader :proxy, :agents

          def initialize(proxy, cached=false)
            @proxy  = proxy
            @cached = cached
          end

          def count
            if cached? && @cached_count
              @cached_count
            else
              @cached_count = proxy.environment.variable("QUEUE_MEMBER_COUNT(#{proxy.name})").to_i
            end
          end
          alias size count
          alias length count

          # @param [Hash] args
          # :name value will be viewable in the queue_log
          # :penalty is the penalty assigned to this agent for answering calls on this queue
          def new(*args)
            options   = args.last.kind_of?(Hash) ? args.pop : {}
            interface = args.shift

            raise ArgumentError, "You must specify an interface to add." if interface.nil?
            raise ArgumentError, "You may only supply an interface and a Hash argument!" if args.any?

            penalty             = options.delete(:penalty)            || ''
            name                = options.delete(:name)               || ''
            state_interface     = options.delete(:state_interface)    || ''

            raise ArgumentError, "Unrecognized argument(s): #{options.inspect}" if options.any?

            proxy.environment.execute("AddQueueMember", proxy.name, interface, penalty, '', name, state_interface)

            added = case proxy.environment.variable("AQMSTATUS")
                    when "ADDED"         then true
                    when "MEMBERALREADY" then false
                    when "NOSUCHQUEUE"   then raise QueueDoesNotExistError.new(proxy.name)
                    else
                      raise "UNRECOGNIZED AQMSTATUS VALUE!"
                    end

            if added
              check_agent_cache!
              AgentProxy.new(interface, proxy).tap do |agent_proxy|
                @agents << agent_proxy
              end
            else
              false
            end
          end

          # Logs a pre-defined agent into this queue and waits for calls. Pass in :silent => true to stop
          # the message which says "Agent logged in".
          def login!(*args)
            options = args.last.kind_of?(Hash) ? args.pop : {}

            silent = options.delete(:silent).equal?(false) ? '' : 's'
            id     = args.shift
            id   &&= AgentProxy.id_from_agent_channel(id)
            raise ArgumentError, "Unrecognized Hash options to login(): #{options.inspect}" if options.any?
            raise ArgumentError, "Unrecognized argument to login(): #{args.inspect}" if args.any?

            proxy.environment.execute('AgentLogin', id, silent)
          end

          # Removes the current channel from this queue
          def logout!
            # TODO: DRY this up. Repeated in the AgentProxy...
            proxy.environment.execute 'RemoveQueueMember', proxy.name
            case proxy.environment.variable("RQMSTATUS")
            when "REMOVED"     then true
            when "NOTINQUEUE"  then false
            when "NOSUCHQUEUE"
              raise QueueDoesNotExistError.new(proxy.name)
            else
              raise "Unrecognized RQMSTATUS variable!"
            end
          end

          def each(&block)
            check_agent_cache!
            agents.each(&block)
          end

          def first
            check_agent_cache!
            agents.first
          end

          def last
            check_agent_cache!
            agents.last
          end

          def cached?
            @cached
          end

          def to_a
            check_agent_cache!
            @agents
          end

          private

          def check_agent_cache!
            if cached?
              load_agents! unless agents
            else
              load_agents!
            end
          end

          def load_agents!
            raw_data = proxy.environment.variable "QUEUE_MEMBER_LIST(#{proxy.name})"
            @agents = raw_data.split(',').map(&:strip).reject(&:empty?).map do |agent|
              AgentProxy.new(agent, proxy)
            end
            @cached_count = @agents.size
          end

        end
      end
    end
  end
end
