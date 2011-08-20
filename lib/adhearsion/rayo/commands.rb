module Adhearsion
  module Rayo
    module Commands
      extend ActiveSupport::Autoload

      include Punchblock::Rayo::Command

      def accept
        write_and_await_response Accept.new
      end

      def answer
        write_and_await_response Answer.new
      end

      def hangup
        write_and_await_response Punchblock::Rayo::Command::Hangup.new
      end

      def write(command)
        call.write_command command
      end

      def write_and_await_response(command, timeout = 60.seconds)
        write command
        # command.response(timeout).tap { |result| raise result if result.is_a? Exception }
      end
    end
  end
end
