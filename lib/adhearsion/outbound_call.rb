# encoding: utf-8

module Adhearsion
  class OutboundCall < Call
    attr_reader :dial_command

    delegate :to, :from, :to => :dial_command, :allow_nil => true

    class << self
      def originate(to, opts = {})
        new.tap do |call|
          call.run_router_on_answer
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
      options.merge! :to => to
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
      register_event_handler :class => Punchblock::Event::Answered do |event|
        run_router
        throw :pass
      end
    end

    def on_answer(&block)
      register_event_handler :class => Punchblock::Event::Answered do |event|
        block.call event
        throw :pass
      end
    end
  end
end
