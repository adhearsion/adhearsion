module Adhearsion
  module Rayo
    module Commands
      extend ActiveSupport::Autoload

      include Punchblock::Command

      def accept
        write_and_await_response Accept.new
      end

      def answer
        write_and_await_response Answer.new
      end

      def hangup
        write_and_await_response Punchblock::Command::Hangup.new
      end

      def write(command)
        call.write_command command
      end

      def write_and_await_response(command, timeout = 60.seconds)
        write command
        response = command.response timeout
        if response.is_a? Exception
          raise response
        else
          command
        end
      end
    end
  end
end
