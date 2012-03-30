# encoding: utf-8

require 'thread'

module Adhearsion
  ##
  # Encapsulates call-related data and behavior.
  #
  class Call

    Hangup          = Class.new Adhearsion::Error
    CommandTimeout  = Class.new Adhearsion::Error
    ExpiredError    = Class.new Celluloid::DeadActorError

    include Celluloid
    include HasGuardedHandlers

    def self.new(*args, &block)
      super.tap do |proxy|
        def proxy.method_missing(*args)
          super
        rescue Celluloid::DeadActorError
          raise ExpiredError, "This call is expired and is no longer accessible"
        end
      end
    end

    attr_accessor :offer, :client, :end_reason, :commands, :variables, :controllers

    delegate :[], :[]=, :to => :variables
    delegate :to, :from, :to => :offer, :allow_nil => true

    def initialize(offer = nil)
      register_initial_handlers

      @tags         = []
      @commands     = CommandRegistry.new
      @variables    = {}
      @controllers  = []
      @end_reason   = nil

      self << offer if offer
    end

    def id
      offer.target_call_id if offer
    end

    def tags
      @tags.clone
    end

    # This may still be a symbol, but no longer requires the tag to be a symbol although beware
    # that using a symbol would create a memory leak if used improperly
    # @param [String, Symbol] label String or Symbol with which to tag this call
    def tag(label)
      abort ArgumentError.new "Tag must be a String or Symbol" unless [String, Symbol].include?(label.class)
      @tags << label
    end

    def remove_tag(symbol)
      @tags.reject! { |tag| tag == symbol }
    end

    def tagged_with?(symbol)
      @tags.include? symbol
    end

    def register_event_handler(*guards, &block)
      register_handler :event, *guards, &block
    end

    def deliver_message(message)
      logger.debug "Receiving message: #{message.inspect}"
      catching_standard_errors { trigger_handler :event, message }
    end

    alias << deliver_message

    def register_initial_handlers # :nodoc:
      register_event_handler Punchblock::Event::Offer do |offer|
        @offer  = offer
        @client = offer.client
        throw :pass
      end

      register_event_handler Punchblock::HasHeaders do |event|
        variables.merge! event.headers_hash
        throw :pass
      end

      register_event_handler Punchblock::Event::Joined do |event|
        target = event.call_id || event.mixer_name
        signal :joined, target
        throw :pass
      end

      register_event_handler Punchblock::Event::Unjoined do |event|
        target = event.call_id || event.mixer_name
        signal :unjoined, target
        throw :pass
      end

      on_end do |event|
        logger.info "Call ended"
        clear_from_active_calls
        @end_reason = event.reason
        commands.terminate
        after(after_end_hold_time) { current_actor.terminate! }
      end
    end

    def after_end_hold_time # :nodoc:
      30
    end

    def on_end(&block)
      register_event_handler Punchblock::Event::End do |event|
        block.call event
        throw :pass
      end
    end

    def active?
      !end_reason
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
      logger.info "Hanging up"
      @end_reason = true
      write_and_await_response Punchblock::Command::Hangup.new(:headers => headers)
    end

    def clear_from_active_calls # :nodoc:
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
      command = Punchblock::Command::Join.new join_options_with_target(target, options)
      write_and_await_response command
    end

    ##
    # Unjoins this call from another call or a mixer
    #
    # @param [Call, String, Hash] target the target to unjoin from. May be a Call object, a call ID (String, Hash) or a mixer name (Hash)
    # @option target [String] call_id The call ID to unjoin from
    # @option target [String] mixer_name The mixer to unjoin from
    #
    def unjoin(target)
      command = Punchblock::Command::Unjoin.new join_options_with_target(target)
      write_and_await_response command
    end

    def join_options_with_target(target, options = {})
      options.merge(case target
      when Call
        { :call_id => target.id }
      when String
        { :call_id => target }
      when Hash
        abort ArgumentError.new "You cannot specify both a call ID and mixer name" if target.has_key?(:call_id) && target.has_key?(:mixer_name)
        target
      else
        abort ArgumentError.new "Don't know how to join to #{target.inspect}"
      end)
    end

    def wait_for_joined(expected_target)
      target = nil
      until target == expected_target do
        target = wait :joined
      end
    end

    def wait_for_unjoined(expected_target)
      target = nil
      until target == expected_target do
        target = wait :unjoined
      end
    end

    def mute
      write_and_await_response ::Punchblock::Command::Mute.new
    end

    def unmute
      write_and_await_response ::Punchblock::Command::Unmute.new
    end

    def write_and_await_response(command, timeout = 60)
      commands << command
      write_command command

      case (response = command.response timeout)
      when Punchblock::ProtocolError
        if response.name == :item_not_found
          abort Hangup.new(@end_reason)
        else
          abort response
        end
      when Exception
        abort response
      end

      command
    rescue Timeout::Error => e
      abort CommandTimeout.new(command.to_s)
    end

    def write_command(command)
      abort Hangup.new(@end_reason) unless active? || command.is_a?(Punchblock::Command::Hangup)
      variables.merge! command.headers_hash if command.respond_to? :headers_hash
      logger.debug "Executing command #{command.inspect}"
      client.execute_command command, :call_id => id, :async => true
    end

    def logger_id # :nodoc:
      "#{self.class}: #{id}"
    end

    def logger # :nodoc:
      super
    end

    def to_ary
      [current_actor]
    end

    def inspect
      attrs = [:offer, :end_reason, :commands, :variables, :controllers, :to, :from].map do |attr|
        "#{attr}=#{send(attr).inspect}"
      end
      "#<#{self.class}:#{id} #{attrs.join ', '}>"
    end

    def execute_controller(controller, completion_callback = nil)
      call = current_actor
      Thread.new do
        catching_standard_errors do
          begin
            CallController.exec controller
          ensure
            completion_callback.call call if completion_callback
          end
        end
      end.tap { |t| Adhearsion::Process.important_threads << t }
    end

    def register_controller(controller)
      @controllers << controller
    end

    def pause_controllers
      controllers.each(&:pause!)
    end

    def resume_controllers
      controllers.each(&:resume!)
    end

    class CommandRegistry < ThreadSafeArray # :nodoc:
      def terminate
        hangup = Hangup.new
        each { |command| command.response = hangup if command.requested? }
      end
    end

  end#Call
end#Adhearsion
