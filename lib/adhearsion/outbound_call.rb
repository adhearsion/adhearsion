module Adhearsion
  class OutboundCall < Call
    attr_reader :dial_command
    attr_accessor :on_accept, :on_answer

    def id
      dial_command.call_id if dial_command
    end

    def connection
      Initializer::Punchblock.client
    end

    def dial(to, options)
      options.merge! :to => to
      write_and_await_response(Punchblock::Command::Dial.new(options)).tap do |dial_command|
        @dial_command = dial_command
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
