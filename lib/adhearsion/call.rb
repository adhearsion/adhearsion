require 'thread'

module Adhearsion
  ##
  # Encapsulates call-related data and behavior.
  #
  class Call
    attr_accessor :offer, :originating_voip_platform, :inbox, :context, :connection, :end_reason, :commands

    def initialize(offer = nil)
      if offer
        @offer      = offer
        @connection = offer.connection
      end

      @tag_mutex        = Mutex.new
      @tags             = []
      @context          = :adhearsion
      @end_reason_mutex = Mutex.new
      end_reason        = nil
      @commands         = CommandRegistry.new
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
      if message.is_a?(Punchblock::Event::End)
        process_end message
      else
        inbox << message
      end
    end
    alias << deliver_message

    def process_end(event)
      hangup
      @end_reason_mutex.synchronize { @end_reason = event.reason }
      commands.terminate
    end

    def can_use_messaging?
      inbox.open == true
    end

    def active?
      @end_reason_mutex.synchronize { !end_reason }
    end

    def inbox
      @inbox ||= CallMessageQueue.new
    end

    def accept(headers = nil)
      write_and_await_response Punchblock::Command::Accept.new(:headers => headers)
    end

    def answer(headers = nil)
      write_and_await_response Punchblock::Command::Answer.new(:headers => headers)
    end

    def reject(reason = :busy, headers = nil)
      write_and_await_response Punchblock::Command::Reject.new(:reason => reason, :headers => headers)
    end

    def hangup!(headers = nil)
      return unless active?
      @end_reason_mutex.synchronize { @end_reason = true }
      write_and_await_response Punchblock::Command::Hangup.new(:headers => headers)
    end

    def hangup
      Adhearsion.remove_inactive_call self
    end

    # Lock the socket for a command.  Can be used to allow the console to take
    # control of the thread in between AGI commands coming from the dialplan.
    def with_command_lock
      @command_monitor ||= Monitor.new
      @command_monitor.synchronize { yield }
    end

    def write_and_await_response(command, timeout = 60.seconds)
      commands << command
      write_command command
      response = command.response timeout
      raise response if response.is_a? Exception
      command
    end

    def write_command(command)
      raise Hangup unless active? || command.is_a?(Punchblock::Command::Hangup)
      connection.async_write id, command
    end

    def ahn_log(*args)
      Adhearsion::Logging::DefaultAdhearsionLogger.send Adhearsion::Logging::AdhearsionLogger.sanitized_logger_name("call_#{id}"), *args
    end

    def variables
      offer.headers_hash
    end

    def define_variable_accessors(recipient = self)
      variables.each do |key, value|
        define_singleton_accessor_with_pair key, value, recipient
      end
    end

    private

    def define_singleton_accessor_with_pair(key, value, recipient = self)
      recipient.metaclass.send :attr_accessor, key unless recipient.class.respond_to?("#{key}=")
      recipient.metaclass.send :public, key, "#{key}=".to_sym
      recipient.send "#{key}=", value
    end

    def set_originating_voip_platform!
      # TODO: Determine this from the headers somehow
      self.originating_voip_platform = :rayo
    end

    class CommandRegistry
      include Enumerable

      def initialize
        @commands = []
      end

      def self.synchronized_delegate(*args)
        args.each do |method_name|
          class_eval <<-EOS
            def #{method_name}(*args, &block)
              synchronize { @commands.__send__ #{method_name.inspect}, *args, &block }
            end
          EOS
        end
      end

      synchronized_delegate :empty?, :<<, :delete, :each

      def terminate
        hangup = Hangup.new
        each { |command| command.response = hangup if command.requested? }
      end
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
