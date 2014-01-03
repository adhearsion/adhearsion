# encoding: utf-8

require 'has_guarded_handlers'
require 'thread'
require 'active_support/hash_with_indifferent_access'

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
    finalizer :finalize

    def self.new(*args, &block)
      super.tap do |proxy|
        def proxy.method_missing(*args)
          super
        rescue Celluloid::DeadActorError
          raise ExpiredError, "This call is expired and is no longer accessible. See http://adhearsion.com/docs/calls for further details."
        end
      end
    end

    # @return [Symbol] the reason for the call ending
    attr_reader :end_reason

    # @return [Array<Adhearsion::CallController>] the set of call controllers executing on the call
    attr_reader :controllers

    # @return [Hash<String => String>] a collection of SIP headers set during the call
    attr_reader :variables

    # @return [Time] the time at which the call began. For inbound calls this is the time at which the call was offered to Adhearsion. For outbound calls it is the time at which the remote party answered.
    attr_reader :start_time

    # @return [Time] the time at which the call began. For inbound calls this is the time at which the call was offered to Adhearsion. For outbound calls it is the time at which the remote party answered.
    attr_reader :end_time

    delegate :[], :[]=, :to => :variables

    # @return [String] the value of the To header from the signaling protocol
    delegate :to, to: :offer, allow_nil: true

    # @return [String] the value of the From header from the signaling protocol
    delegate :from, to: :offer, allow_nil: true

    def self.uri(transport, id, domain)
      return nil unless id
      s = ""
      s << transport << ":" if transport
      s << id
      s << "@" << domain if domain
      s
    end

    def initialize(offer = nil)
      register_initial_handlers

      @offer        = nil
      @tags         = []
      @commands     = CommandRegistry.new
      @variables    = HashWithIndifferentAccess.new
      @controllers  = []
      @end_reason   = nil
      @end_blocker  = Celluloid::Condition.new
      @peers        = {}
      @duration     = nil

      self << offer if offer
    end

    #
    # @return [String, nil] The globally unique ID for the call
    #
    def id
      offer.target_call_id if offer
    end
    alias :to_s :id

    #
    # @return [String, nil] The domain on which the call resides
    #
    def domain
      offer.domain if offer
    end

    #
    # @return [String, nil] The uri at which the call resides
    #
    def uri
      self.class.uri(transport, id, domain)
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

    #
    # Wait for the call to end. Returns immediately if the call has already ended, else blocks until it does so.
    # @return [Symbol] the reason for the call ending
    #
    def wait_for_end
      if end_reason
        end_reason
      else
        @end_blocker.wait
      end
    end

    def register_event_handler(*guards, &block)
      register_handler :event, *guards, &block
    end

    def deliver_message(message)
      logger.debug "Receiving message: #{message.inspect}"
      catching_standard_errors { trigger_handler :event, message }
    end
    alias << deliver_message

    def commands
      @commands.clone
    end

    # @private
    def register_initial_handlers
      register_event_handler Punchblock::Event::Offer do |offer|
        @offer  = offer
        @client = offer.client
        @start_time = Time.now
        throw :pass
      end

      register_event_handler Punchblock::HasHeaders do |event|
        merge_headers event.headers
        throw :pass
      end

      on_joined do |event|
        if event.call_uri
          target = event.call_uri
          type = :call
        else
          target = event.mixer_name
          type = :mixer
        end
        logger.info "Joined to #{type} #{target}"
        call = Adhearsion.active_calls.with_uri(target)
        @peers[call ? call.id : target] = call
        signal :joined, target
      end

      on_unjoined do |event|
        if event.call_uri
          target = event.call_uri
          type = :call
        else
          target = event.mixer_name
          type = :mixer
        end
        logger.info "Unjoined from #{type} #{target}"
        @peers.delete target
        signal :unjoined, target
      end

      on_end do |event|
        logger.info "Call ended due to #{event.reason}"
        @end_time = Time.now
        @duration = @end_time - @start_time if @start_time
        clear_from_active_calls
        @end_reason = event.reason
        @end_blocker.broadcast event.reason
        @commands.terminate
        after(Adhearsion.config.platform.after_hangup_lifetime) { terminate }
        throw :pass
      end
    end

    # @return [Float] The call duration until the current time, or until the call was disconnected, whichever is earlier
    def duration
      if @duration
        @duration
      elsif @start_time
        Time.now - @start_time
      else
        0.0
      end
    end

    ##
    # Registers a callback for when this call is joined to another call or a mixer
    #
    # @param [Call, String, Hash, nil] target the target to guard on. May be a Call object, a call ID (String, Hash) or a mixer name (Hash)
    # @option target [String] call_uri The call ID to guard on
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
    # @option target [String] call_uri The call ID to guard on
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
      target ? [target_from_join_options(join_options_with_target(target))] : []
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
    # @option target [String] call_uri The call ID to join to
    # @option target [String] mixer_name The mixer to join to
    # @param [Hash, Optional] options further options to be joined with
    #
    # @return [Hash] where :command is the issued command, :joined_waiter is a #wait responder which is triggered when the join is complete, and :unjoined_waiter is a #wait responder which is triggered when the entities are unjoined
    #
    def join(target, options = {})
      logger.info "Joining to #{target}"

      joined_condition = CountDownLatch.new(1)
      on_joined target do
        joined_condition.countdown!
      end

      unjoined_condition = CountDownLatch.new(1)
      on_unjoined target do
        unjoined_condition.countdown!
      end

      on_end do
        joined_condition.countdown!
        unjoined_condition.countdown!
      end

      command = Punchblock::Command::Join.new options.merge(join_options_with_target(target))
      write_and_await_response command
      {command: command, joined_condition: joined_condition, unjoined_condition: unjoined_condition}
    end

    ##
    # Unjoins this call from another call or a mixer
    #
    # @param [Call, String, Hash] target the target to unjoin from. May be a Call object, a call ID (String, Hash) or a mixer name (Hash)
    # @option target [String] call_uri The call ID to unjoin from
    # @option target [String] mixer_name The mixer to unjoin from
    #
    def unjoin(target)
      logger.info "Unjoining from #{target}"
      command = Punchblock::Command::Unjoin.new join_options_with_target(target)
      write_and_await_response command
    end

    # @private
    def join_options_with_target(target)
      case target
      when Call
        { :call_uri => target.uri }
      when String
        { :call_uri => self.class.uri(transport, target, domain) }
      when Hash
        abort ArgumentError.new "You cannot specify both a call URI and mixer name" if target.has_key?(:call_uri) && target.has_key?(:mixer_name)
        target
      else
        abort ArgumentError.new "Don't know how to join to #{target.inspect}"
      end
    end

    # @private
    def target_from_join_options(options)
      call_uri = options[:call_uri]
      return {call_uri: call_uri} if call_uri
      {mixer_name: options[:mixer_name]}
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
    def write_and_await_response(command, timeout = 60, fatal = false)
      @commands << command
      write_command command

      error_handler = fatal ? ->(error) { raise error } : ->(error) { abort error }

      response = defer { command.response timeout }
      case response
      when Punchblock::ProtocolError
        if response.name == :item_not_found
          error_handler[Hangup.new(@end_reason)]
        else
          error_handler[response]
        end
      when Exception
        error_handler[response]
      end

      command
    rescue Timeout::Error
      error_handler[CommandTimeout.new(command.to_s)]
    ensure
      @commands.delete command
    end

    # @private
    def write_command(command)
      abort Hangup.new(@end_reason) unless active? || command.is_a?(Punchblock::Command::Hangup)
      merge_headers command.headers if command.respond_to? :headers
      logger.debug "Executing command #{command.inspect}"
      client.execute_command command, call_id: id, domain: domain, async: true
    end

    # @private
    def logger_id
      "#{self.class}: #{id}@#{domain}"
    end
    # @private
    def inspect
      attrs = [:offer, :end_reason, :commands, :variables, :controllers, :to, :from].map do |attr|
        "#{attr}=#{send(attr).inspect}"
      end
      "#<#{self.class}:#{id}@#{domain} #{attrs.join ', '}>"
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

    def transport
      offer.transport if offer
    end

    def merge_headers(headers)
      headers.each do |name, value|
        variables[name.to_s.downcase.gsub('-', '_')] = value
      end
    end

    def finalize
      ::Logging::Repository.instance.delete logger_id
    end

    # @private
    class CommandRegistry < Array
      def terminate
        hangup = Hangup.new
        each { |command| command.response = hangup if command.requested? }
      end
    end

  end
end
