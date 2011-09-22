module Adhearsion
  module Asterisk
    module Commands
      class QueueProxy

        extend ActiveSupport::Autoload

        autoload :AgentProxy
        autoload :QueueAgentsListProxy

        class << self

          def format_join_hash_key_arguments(options)

            bad_argument = lambda do |(key, value)|
              raise ArgumentError, "Unrecognize value for #{key.inspect} -- #{value.inspect}"
            end

            # Direct Queue() arguments:
            timeout        = options.delete :timeout
            announcement   = options.delete :announce

            # Terse single-character options
            ring_style     = options.delete :play
            allow_hangup   = options.delete :allow_hangup
            allow_transfer = options.delete :allow_transfer
            agi            = options.delete :agi

            raise ArgumentError, "Unrecognized args to join!: #{options.inspect}" if options.any?

            ring_style = case ring_style
              when :ringing then 'r'
              when :music then   ''
              when nil
              else bad_argument[:play => ring_style]
            end.to_s

            allow_hangup = case allow_hangup
              when :caller then   'H'
              when :agent then    'h'
              when :everyone then 'Hh'
              when nil
              else bad_argument[:allow_hangup => allow_hangup]
            end.to_s

            allow_transfer = case allow_transfer
              when :caller then   'T'
              when :agent then    't'
              when :everyone then 'Tt'
              when nil
              else bad_argument[:allow_transfer => allow_transfer]
            end.to_s

            terse_character_options = ring_style + allow_transfer + allow_hangup

            [terse_character_options, '', announcement, timeout, agi].map(&:to_s)
          end

        end

        attr_reader :name, :environment
        def initialize(name, environment)
          @name, @environment = name, environment
        end

        # Makes the current channel join the queue.
        #
        # @param [Hash] options
        #
        #   :timeout        - The number of seconds to wait for an agent to answer
        #   :play           - Can be :ringing or :music.
        #   :announce       - A sound file to play instead of the normal queue announcement.
        #   :allow_transfer - Can be :caller, :agent, or :everyone. Allow someone to transfer the call.
        #   :allow_hangup   - Can be :caller, :agent, or :everyone. Allow someone to hangup with the * key.
        #   :agi            - An AGI script to be called on the calling parties channel just before being connected.
        #
        #  @example
        #    queue('sales').join!
        #  @example
        #    queue('sales').join! :timeout => 1.minute
        #  @example
        #    queue('sales').join! :play => :music
        #  @example
        #    queue('sales').join! :play => :ringing
        #  @example
        #    queue('sales').join! :announce => "custom/special-queue-announcement"
        #  @example
        #    queue('sales').join! :allow_transfer => :caller
        #  @example
        #    queue('sales').join! :allow_transfer => :agent
        #  @example
        #    queue('sales').join! :allow_hangup   => :caller
        #  @example
        #    queue('sales').join! :allow_hangup   => :agent
        #  @example
        #    queue('sales').join! :allow_hangup   => :everyone
        #  @example
        #    queue('sales').join! :agi            => 'agi://localhost/sales_queue_callback'
        #  @example
        #    queue('sales').join! :allow_transfer => :agent, :timeout => 30.seconds,
        def join!(options={})
          environment.execute("queue", name, *self.class.format_join_hash_key_arguments(options))
          normalize_queue_status_variable environment.variable("QUEUESTATUS")
        end

        # Get the agents associated with a queue
        #
        # @param [Hash] options
        # @return [QueueAgentsListProxy]
        def agents(options={})
          cached = options.has_key?(:cache) ? options.delete(:cache) : true
          raise ArgumentError, "Unrecognized arguments to agents(): #{options.inspect}" if options.keys.any?
          if cached
            @cached_proxy ||= QueueAgentsListProxy.new(self, true)
          else
            @uncached_proxy ||=  QueueAgentsListProxy.new(self, false)
          end
        end

        # Check how many channels are waiting in the queue
        # @return [Integer]
        # @raise QueueDoesNotExistError
        def waiting_count
          raise QueueDoesNotExistError.new(name) unless exists?
          environment.variable("QUEUE_WAITING_COUNT(#{name})").to_i
        end

        # Check whether the waiting count is zero
        # @return [Boolean]
        def empty?
          waiting_count == 0
        end

        # Check whether any calls are waiting in the queue
        # @return [Boolean]
        def any?
          waiting_count > 0
        end

        # Check whether a queue exists/is defined in Asterisk
        # @return [Boolean]
        def exists?
          environment.execute('RemoveQueueMember', name, 'SIP/AdhearsionQueueExistenceCheck')
          environment.variable("RQMSTATUS") != 'NOSUCHQUEUE'
        end

        private

        # Ensure the queue exists by interpreting the QUEUESTATUS variable
        #
        # According to http://www.voip-info.org/wiki/view/Asterisk+cmd+Queue
        # possible values are:
        #
        # TIMEOUT      => :timeout
        # FULL         => :full
        # JOINEMPTY    => :joinempty
        # LEAVEEMPTY   => :leaveempty
        # JOINUNAVAIL  => :joinunavail
        # LEAVEUNAVAIL => :leaveunavail
        # CONTINUE     => :continue
        #
        # If the QUEUESTATUS variable is not set the call was successfully connected,
        # and Adhearsion will return :completed.
        #
        # @param [String] QUEUESTATUS variable from Asterisk
        # @return [Symbol] Symbolized version of QUEUESTATUS
        # @raise QueueDoesNotExistError
        def normalize_queue_status_variable(variable)
          variable = "COMPLETED" if variable.nil?
          variable.downcase.to_sym
        end

        class QueueDoesNotExistError < StandardError
          def initialize(queue_name)
            super "Queue #{queue_name} does not exist!"
          end
        end

      end
    end
  end
end
