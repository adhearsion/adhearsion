# encoding: utf-8

module Adhearsion
  class OutboundCall < Call
    execute_block_on_receiver :register_handler, :register_tmp_handler, :register_handler_with_priority, :register_event_handler, :on_joined, :on_unjoined, :on_end, :execute_controller, :on_answer, :execute_controller_or_router_on_answer

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
          call.execute_controller_or_router_on_answer opts.delete(:controller), opts.delete(:controller_metadata), &controller_block
          call.dial to, opts
        end
      end
    end

    def id
      dial_command.target_call_id if dial_command
    end

    def client
      PunchblockPlugin::Initializer.client
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

      write_and_await_response(Punchblock::Command::Dial.new(options), wait_timeout).tap do |dial_command|
        @dial_command = dial_command
        Adhearsion.active_calls << current_actor
        Adhearsion::Events.trigger_immediately :call_dialed, current_actor
      end
    end

    def run_router
      catching_standard_errors do
        Adhearsion.router.handle current_actor
      end
    end

    def run_router_on_answer
      register_event_handler Punchblock::Event::Answered do |event|
        run_router
        throw :pass
      end
    end

    def on_answer(&block)
      register_event_handler Punchblock::Event::Answered do |event|
        block.call event
        throw :pass
      end
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
  end
end
