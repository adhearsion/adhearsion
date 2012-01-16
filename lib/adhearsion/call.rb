require 'thread'

module Adhearsion
  ##
  # Encapsulates call-related data and behavior.
  #
  class Call

    include HasGuardedHandlers

    attr_accessor :offer, :client, :end_reason, :commands

    def initialize(offer = nil)
      if offer
        @offer  = offer
        @client = offer.client
      end

      @tag_mutex        = Mutex.new
      @tags             = []
      @end_reason_mutex = Mutex.new
      end_reason        = nil
      @commands         = CommandRegistry.new

      register_initial_handlers
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

    def register_event_handler(*guards, &block)
      register_handler :event, *guards, &block
    end

    def deliver_message(message)
      trigger_handler :event, message
    end
    alias << deliver_message

    def register_initial_handlers
      on_end do |event|
        hangup
        @end_reason_mutex.synchronize { @end_reason = event.reason }
        commands.terminate
      end
    end

    def on_end(&block)
      register_event_handler :class => Punchblock::Event::End do |event|
        block.call event
        throw :pass
      end
    end

    def active?
      @end_reason_mutex.synchronize { !end_reason }
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
      return false unless active?
      @end_reason_mutex.synchronize { @end_reason = true }
      write_and_await_response Punchblock::Command::Hangup.new(:headers => headers)
    end

    def hangup
      Adhearsion.active_calls.remove_inactive_call self
    end

    def join(other_call_id)
      write_and_await_response Punchblock::Command::Join.new :other_call_id => other_call_id
    end

    # Lock the socket for a command.  Can be used to allow the console to take
    # control of the thread in between AGI commands coming from the dialplan.
    def with_command_lock
      @command_monitor ||= Monitor.new
      @command_monitor.synchronize { yield }
    end

    def write_and_await_response(command, timeout = 60)
      logger.trace "Executing command #{command.inspect}"
      commands << command
      write_command command
      response = command.response timeout
      raise response if response.is_a? Exception
      command
    end

    def write_command(command)
      raise Hangup unless active? || command.is_a?(Punchblock::Command::Hangup)
      client.execute_command command, :call_id => id
    end

    # Sanitize the offer id
    def logger_id
      id
    end

    def variables
      offer ? offer.headers_hash : nil or {}
    end

    def execute_controller(controller, latch = nil)
      Adhearsion::Process.important_threads << Thread.new do
        catching_standard_errors do
          begin
            CallController.exec controller
          ensure
            hangup!
          end
          latch.countdown! if latch
        end
      end
    end

    class CommandRegistry < ThreadSafeArray
      def terminate
        hangup = Hangup.new
        each { |command| command.response = hangup if command.requested? }
      end
    end

    class Registry
      @registry = Hash.new
      @mutex = Mutex.new

      def self.[](k)
        @mutex.synchronize do
          @registry[k]
        end
      end

      def self.[]=(k, value)
        @mutex.synchronize do
          @registry[k] = value
        end
      end
    end#Registry

  end#Call
end#Adhearsion
