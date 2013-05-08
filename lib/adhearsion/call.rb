# encoding: utf-8

require 'has_guarded_handlers'
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

    execute_block_on_receiver :register_handler, :register_tmp_handler, :register_handler_with_priority, :register_event_handler, :on_joined, :on_unjoined, :on_end, :execute_controller

    def self.new(*args, &block)
      super.tap do |proxy|
        def proxy.method_missing(*args)
          super
        rescue Celluloid::DeadActorError
          raise ExpiredError, "This call is expired and is no longer accessible"
        end
      end
    end

    attr_reader :end_reason, :commands, :controllers, :variables

    delegate :[], :[]=, :to => :variables
    delegate :to, :from, :to => :offer, :allow_nil => true

    def initialize(offer = nil)
      register_initial_handlers

      @offer        = nil
      @tags         = []
      @commands     = CommandRegistry.new
      @variables    = {}
      @controllers  = []
      @end_reason   = nil
      @peers        = {}

      self << offer if offer
    end

    #
    # @return [String, nil] The globally unique ID for the call
    #
    def id
      offer.target_call_id if offer
    end

    #
    # @return [Array] The set of labels with which this call has been tagged.
    #
    def tags
      @tags.clone
    end

    #
    # Tag a call with an arbitrary label
    #
    # @param [String, Symbol] label String or Symbol with which to tag this call
    #
    def tag(label)
      abort ArgumentError.new "Tag must be a String or Symbol" unless [String, Symbol].include?(label.class)
      @tags << label
    end

    #
    # Remove a label
    #
    # @param [String, Symbol] label
    #
    def remove_tag(label)
      @tags.reject! { |tag| tag == label }
    end

    #
    # Establish if the call is tagged with the provided label
    #
    # @param [String, Symbol] label
    #
    def tagged_with?(label)
      @tags.include? label
    end

    #
    # Hash of joined peers
    # @return [Hash<String => Adhearsion::Call>]
    #
    def peers
      @peers.clone
    end

    def register_event_handler(*guards, &block)
      register_handler :event, *guards, &block
    end

    def deliver_message(message)
      logger.debug "Receiving message: #{message.inspect}"
      catching_standard_errors { trigger_handler :event, message }
    end
    alias << deliver_message

    # @private
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

      on_joined do |event|
        target = event.call_id || event.mixer_name
        @peers[target] = Adhearsion.active_calls[target]
        signal :joined, target
      end

      on_unjoined do |event|
        target = event.call_id || event.mixer_name
        @peers.delete target
        signal :unjoined, target
      end

      on_end do |event|
        logger.info "Call ended"
        clear_from_active_calls
        @end_reason = event.reason
        commands.terminate
        after(Adhearsion.config.platform.after_hangup_lifetime) { terminate }
        throw :pass
      end
    end

    ##
    # Registers a callback for when this call is joined to another call or a mixer
    #
    # @param [Call, String, Hash, nil] target the target to guard on. May be a Call object, a call ID (String, Hash) or a mixer name (Hash)
    # @option target [String] call_id The call ID to guard on
    # @option target [String] mixer_name The mixer name to guard on
    #
    def on_joined(target = nil, &block)
      register_event_handler Punchblock::Event::Joined, *guards_for_target(target) do |event|
        block.call event
        throw :pass
      end
    end

    ##
    # Registers a callback for when this call is unjoined from another call or a mixer
    #
    # @param [Call, String, Hash, nil] target the target to guard on. May be a Call object, a call ID (String, Hash) or a mixer name (Hash)
    # @option target [String] call_id The call ID to guard on
    # @option target [String] mixer_name The mixer name to guard on
    #
    def on_unjoined(target = nil, &block)
      register_event_handler Punchblock::Event::Unjoined, *guards_for_target(target) do |event|
        block.call event
        throw :pass
      end
    end

    # @private
    def guards_for_target(target)
      target ? [join_options_with_target(target)] : []
    end

    def on_end(&block)
      register_event_handler Punchblock::Event::End do |event|
        block.call event
        throw :pass
      end
    end

    #
    # @return [Boolean] if the call is currently active or not (disconnected)
    #
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
      Adhearsion::Events.trigger_immediately :call_rejected, call: current_actor, reason: reason
    end

    def hangup(headers = nil)
      return false unless active?
      logger.info "Hanging up"
      @end_reason = true
      write_and_await_response Punchblock::Command::Hangup.new(:headers => headers)
    end

    # @private
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
      command = Punchblock::Command::Join.new options.merge(join_options_with_target(target))
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

    # @private
    def join_options_with_target(target)
      case target
      when Call
        { :call_id => target.id }
      when String
        { :call_id => target }
      when Hash
        abort ArgumentError.new "You cannot specify both a call ID and mixer name" if target.has_key?(:call_id) && target.has_key?(:mixer_name)
        target
      else
        abort ArgumentError.new "Don't know how to join to #{target.inspect}"
      end
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
      write_and_await_response Punchblock::Command::Mute.new
    end

    def unmute
      write_and_await_response Punchblock::Command::Unmute.new
    end

    # @private
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
    rescue Timeout::Error
      abort CommandTimeout.new(command.to_s)
    end

    # @private
    def write_command(command)
      abort Hangup.new(@end_reason) unless active? || command.is_a?(Punchblock::Command::Hangup)
      variables.merge! command.headers_hash if command.respond_to? :headers_hash
      logger.debug "Executing command #{command.inspect}"
      client.execute_command command, :call_id => id, :async => true
    end

    # @private
    def logger_id
      "#{self.class}: #{id}"
    end

    # @private
    def to_ary
      [current_actor]
    end

    # @private
    def inspect
      attrs = [:offer, :end_reason, :commands, :variables, :controllers, :to, :from].map do |attr|
        "#{attr}=#{send(attr).inspect}"
      end
      "#<#{self.class}:#{id} #{attrs.join ', '}>"
    end

    def execute_controller(controller = nil, completion_callback = nil, &block)
      raise ArgumentError, "Cannot supply a controller and a block at the same time" if controller && block_given?
      controller ||= CallController.new current_actor, &block
      logger.info "Executing controller #{controller.inspect}"
      controller.bg_exec completion_callback
    end

    # @private
    def register_controller(controller)
      @controllers << controller
    end

    # @private
    def pause_controllers
      controllers.each(&:pause!)
    end

    # @private
    def resume_controllers
      controllers.each(&:resume!)
    end

    private

    def offer
      @offer
    end

    def client
      @client
    end

    # @private
    class CommandRegistry < ThreadSafeArray
      def terminate
        hangup = Hangup.new
        each { |command| command.response = hangup if command.requested? }
      end
    end

  end
end
