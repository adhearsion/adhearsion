module Adhearsion
  class OutboundCall < Call
    attr_reader :dial_command

    class << self
      def originate(to, opts = {})
        new(opts).tap do |call|
          call.run_dialplan_on_answer
          call.dial to, opts
        end
      end
    end

    def initialize(opts = {})
      super()
      @context = opts.delete(:context) if opts.has_key?(:context)
    end

    def id
      dial_command.call_id if dial_command
    end

    def variables
      {}
    end

    def connection
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
      write_and_await_response(Punchblock::Command::Dial.new(options)).tap do |dial_command|
        @dial_command = dial_command
        Adhearsion.active_calls << self
      end
    end

    def run_dialplan
      catching_standard_errors do
        DialPlan::Manager.handle self
      end
    end

    def run_dialplan_on_answer
      register_event_handler :class => Punchblock::Event::Answered do |event|
        run_dialplan
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
