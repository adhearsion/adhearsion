require 'thread'

module Celluloid
  module ClassMethods
    def ===(other)
      other.kind_of? self
    end
  end

  class ActorProxy
    def is_a?(klass)
      Actor.call @mailbox, :is_a?, klass
    end

    def kind_of?(klass)
      Actor.call @mailbox, :kind_of?, klass
    end
  end
end

module Adhearsion
  ##
  # Encapsulates call-related data and behavior.
  #
  class Call

    include Celluloid
    include HasGuardedHandlers

    attr_accessor :offer, :client, :end_reason, :commands, :variables

    delegate :[], :[]=, :to => :variables
    delegate :to, :from, :to => :offer, :allow_nil => true

    def initialize(offer = nil)
      register_initial_handlers

      @tag_mutex        = Mutex.new
      @tags             = []
      @end_reason_mutex = Mutex.new
      @commands         = CommandRegistry.new
      @variables        = {}

      self << offer if offer
    end

    def id
      offer.call_id if offer
    end

    def tags
      @tag_mutex.synchronize { @tags.clone }
    end

    # This may still be a symbol, but no longer requires the tag to be a symbol although beware
    # that using a symbol would create a memory leak if used improperly
    # @param [String, Symbol] label String or Symbol with which to tag this call
    def tag(label)
      abort ArgumentError.new "Tag must be a String or Symbol" unless [String, Symbol].include?(label.class)
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
      logger.debug "Receiving message: #{message.inspect}"
      trigger_handler :event, message
    end

    alias << deliver_message

    def register_initial_handlers
      register_event_handler Punchblock::Event::Offer do |offer|
        @offer  = offer
        @client = offer.client
        throw :pass
      end

      register_event_handler Punchblock::HasHeaders do |event|
        variables.merge! event.headers_hash
        throw :pass
      end

      on_end do |event|
        clear_from_active_calls
        @end_reason_mutex.synchronize { @end_reason = event.reason }
        commands.terminate
        after(5) { current_actor.terminate! }
      end
    end

    def on_end(&block)
      register_event_handler Punchblock::Event::End do |event|
        block.call event
        throw :pass
      end
    end

    def active?
      @end_reason_mutex.synchronize { !end_reason }
    end

    def accept(headers = nil)
      @accept_command ||= write_and_await_response Punchblock::Command::Accept.new(:headers => headers)
    end

    def answer(headers = nil)
      write_and_await_response Punchblock::Command::Answer.new(:headers => headers)
    end

    def reject(reason = :busy, headers = nil)
      write_and_await_response Punchblock::Command::Reject.new(:reason => reason, :headers => headers)
    end

    def hangup(headers = nil)
      return false unless active?
      @end_reason_mutex.synchronize { @end_reason = true }
      write_and_await_response Punchblock::Command::Hangup.new(:headers => headers)
    end

    def clear_from_active_calls
      Adhearsion.active_calls.remove_inactive_call current_actor
    end

    ##
    # Joins this call to another call or a mixer
    #
    # @param [Call, String, Hash] target the target to join to. May be a Call object, a call ID (String, Hash) or a mixer name (Hash)
    # @option target [String] call_id The call ID to join to
    # @option target [String] mixer_name The mixer to join to
    # @param [Hash, Optional] options further options to be joined with
    #
    def join(target, options = {})
      case target
      when Call
        options[:other_call_id] = target.id
      when String
        options[:other_call_id] = target
      when Hash
        abort ArgumentError.new "You cannot specify both a call ID and mixer name" if target.has_key?(:call_id) && target.has_key?(:mixer_name)
        target.tap do |t|
          t[:other_call_id] = t[:call_id]
          t.delete :call_id
        end

        options.merge! target
      else
        abort ArgumentError.new "Don't know how to join to #{target.inspect}"
      end
      command = Punchblock::Command::Join.new options
      write_and_await_response command
    end

    def mute
      write_and_await_response ::Punchblock::Command::Mute.new
    end

    def unmute
      write_and_await_response ::Punchblock::Command::Unmute.new
    end

    def with_command_lock
      @command_monitor ||= Monitor.new
      @command_monitor.synchronize { yield }
    end

    def write_and_await_response(command, timeout = 60)
      # TODO: Put this back once we figure out why it's causing CI to fail
      # logger.trace "Executing command #{command.inspect}"
      commands << command
      write_command command
      begin
        response = command.response timeout
      rescue Timeout::Error => e
        abort e
      end
      abort response if response.is_a? Exception
      command
    end

    def write_command(command)
      abort Hangup.new unless active? || command.is_a?(Punchblock::Command::Hangup)
      variables.merge! command.headers_hash if command.respond_to? :headers_hash
      client.execute_command command, :call_id => id
    end

    def logger_id
      "#{self.class}: #{id}"
    end

    def logger
      super
    end

    def to_ary
      [current_actor]
    end

    def execute_controller(controller, latch = nil)
      Adhearsion::Process.important_threads << Thread.new do
        catching_standard_errors do
          begin
            CallController.exec controller
          ensure
            hangup
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
