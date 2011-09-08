module Adhearsion
  class OutboundCall < Call
    attr_reader :dial_command

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
  end
end
