require 'thread'

module Adhearsion
  ##
  # Encapsulates call-related data and behavior.
  #
  class Call
    attr_accessor :offer, :originating_voip_platform, :inbox, :context, :connection

    def initialize(offer)
      @offer      = offer
      @connection = offer.connection
      @tag_mutex  = Mutex.new
      @tags       = []
      @context    = :adhearsion
      set_originating_voip_platform!
    end

    def id
      @offer.call_id
    end

    def tags
      @tag_mutex.synchronize { @tags.clone }
    end

    # This may still be a symbol, but no longer requires the tag to be a symbol although beware
    # that using a symbol would create a memory leak if used improperly
    # @param [String, Symbol] label String or Symbol with which to tag this call
    def tag(label)
      raise ArgumentError, "Tag must be a String or Symbol" unless [String, Symbol].include?(label.class)
      @tag_mutex.synchronize { @tags << label }
    end

    def remove_tag(symbol)
      @tag_mutex.synchronize do
        @tags.reject! { |tag| tag == symbol }
      end
    end

    def tagged_with?(symbol)
      @tag_mutex.synchronize { @tags.include? symbol }
    end

    def deliver_message(message)
      inbox << message
    end
    alias << deliver_message

    def can_use_messaging?
      inbox.open == true
    end

    def inbox
      @inbox ||= CallMessageQueue.new
    end

    def hangup!
      Adhearsion.remove_inactive_call self
    end

    # Lock the socket for a command.  Can be used to allow the console to take
    # control of the thread in between AGI commands coming from the dialplan.
    def with_command_lock
      @command_monitor ||= Monitor.new
      @command_monitor.synchronize { yield }
    end

    def write_command(command)
      connection.async_write id, command
    end

    def ahn_log(*args)
      Adhearsion::Logging::DefaultAdhearsionLogger.send Adhearsion::Logging::AdhearsionLogger.sanitized_logger_name(id), *args
    end

    private

    def set_originating_voip_platform!
      # TODO: Determine this from the headers somehow
      self.originating_voip_platform = :rayo
    end

    ##
    # Wraps the Queue object (subclasses it) so we can handle runaway threads,
    # namely those originating from using with_next_message in commands.rb - this
    # overrides << to check for the :cancel symbol and trigger the automessaging_tainted
    # instance variable.
    class CallMessageQueue < Queue
      InboxClosedException = Class.new StandardError # This gets raised when the :cancel message is delivered to the queue and with_next_message (or similar auto-message-iteration) features are called.

      attr_reader :open

      def initialize
        @open = true
        super
      end

      def <<(queue_obj)
        @open = false if queue_obj == :cancel
        super
      end

      def pop
        raise InboxClosedException, "The message queue for this call has aleady been disabled." unless @open
        super
      end
    end
  end
end
