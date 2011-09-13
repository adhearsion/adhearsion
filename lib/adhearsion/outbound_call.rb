module Adhearsion
  class OutboundCall < Call
    attr_reader :dial_command
    attr_accessor :on_accept, :on_answer

    class << self
      def originate(to, opts = {})
        new(opts).tap do |call|
          call.on_answer = lambda { |answer| call.run_dialplan }
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
      Initializer::Punchblock.client
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

    def deliver_message(message)
      case message
      when Punchblock::Event::Ringing
        on_accept.call message if on_accept
      when Punchblock::Event::Answered
        on_answer.call message if on_answer
      end
      super
    end
    alias << deliver_message
  end
end
