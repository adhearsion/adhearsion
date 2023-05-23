# encoding: utf-8

module Adhearsion
  class OutboundCall < Call
    execute_block_on_receiver :on_answer, :execute_controller_or_router_on_answer, *execute_block_on_receiver

    attr_reader :dial_command

    delegate :to, :from, :to => :dial_command, :allow_nil => true

    class << self
      #
      # Create a new outbound call
      #
      # By default, the call will enter the router when it is answered, similar to incoming calls. Alternatively, a controller may be specified.
      #
      # @param [String] to the URI of the party to dial
      # @param [Hash] opts modifier options
      # @option opts [Class] :controller the controller to execute when the call is answered
      # @option opts [Hash] :controller_metadata key-value pairs of metadata to set on the controller
      # @yield Call controller routine in block form
      #
      # @return [OutboundCall] the ringing call
      #
      # @see #dial for more possible options
      #
      def originate(to, opts = {}, &controller_block)
        new.tap do |call|
          call.execute_controller_or_router_on_answer(opts.delete(:controller), opts.delete(:controller_metadata), &controller_block)
          call.dial(to, **opts)
        end
      end
    end

    def id
      if dial_command
        dial_command.target_call_id || @id
      else
        @id
      end
    end

    def domain
      if dial_command
        dial_command.domain || @domain
      else
        @domain
      end
    end

    def client
      Adhearsion::Rayo::Initializer.client
    end

    def accept(*args)
    end

    def answer(*args)
    end

    def reject(*args)
    end

    #
    # Dial out an existing outbound call
    #
    # @param [String] to the URI of the party to dial
    # @param [Hash] options modifier options
    # @option options [String, Optional] :from what to set the Caller ID to
    # @option options [Integer, Optional] :timeout in seconds
    # @option options [Hash, Optional] :headers SIP headers to attach to
    #   the new call.
    #
    def dial(to, options = {})
      options = options.dup
      options[:to] = to
      if options[:timeout]
        wait_timeout = options[:timeout]
        options[:timeout] = options[:timeout] * 1000
      else
        wait_timeout = 60
      end

      uri = client.new_call_uri
      options[:uri] = uri

      @dial_command = Adhearsion::Rayo::Command::Dial.new(options)

      ref = Adhearsion::Rayo::Ref.new uri: uri
      @transport = ref.scheme
      @id = ref.call_id
      @domain = ref.domain

      Adhearsion.active_calls << current_actor

      write_and_await_response(@dial_command, wait_timeout, true).tap do |dial_command|
        @start_time = dial_command.timestamp.to_time
        if @dial_command.uri != self.uri
          logger.warn "Requested call URI (#{uri}) was not respected. Tracking by new URI #{self.uri}. This might cause a race in event handling, please upgrade your Rayo server."
          Adhearsion.active_calls << current_actor
          Adhearsion.active_calls.delete(@id)
        end
        Adhearsion::Events.trigger :call_dialed, current_actor
      end
    rescue
      clear_from_active_calls
      raise
    end

    # @private
    def register_initial_handlers
      super
      on_answer { |event| @answer_time = event.timestamp.to_time }
    end

    def run_router
      catching_standard_errors do
        Adhearsion.router.handle current_actor
      end
    end

    def run_router_on_answer
      register_event_handler Adhearsion::Event::Answered do |event|
        run_router
      end
    end

    def on_answer(&block)
      register_event_handler Adhearsion::Event::Answered, &block
    end

    def execute_controller_or_router_on_answer(controller, metadata = {}, &controller_block)
      if controller || controller_block
        route = Router::Route.new 'inbound', controller, &controller_block
        route.controller_metadata = metadata
        on_answer { route.dispatch current_actor }
      else
        run_router_on_answer
      end
    end

    private

    def transport
      if dial_command
        dial_command.transport || @transport
      else
        @transport
      end
    end
  end
end
