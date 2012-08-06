# encoding: utf-8

module Adhearsion
  class OutboundCall < Call
    attr_reader :dial_command

    delegate :to, :from, :to => :dial_command, :allow_nil => true

    class << self
      def originate(to, opts = {}, &controller_block)
        new.tap do |call|
          call.execute_controller_or_router_on_answer opts.delete(:controller), &controller_block
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
      end
    end

    def run_router
      catching_standard_errors do
        dispatcher = Adhearsion.router.handle current_actor
        dispatcher.call current_actor
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

    def execute_controller_or_router_on_answer(controller, &controller_block)
      if controller || controller_block
        route = Router::Route.new 'inbound', controller, &controller_block
        on_answer { route.dispatch current_actor }
      else
        run_router_on_answer
      end
    end
  end
end
