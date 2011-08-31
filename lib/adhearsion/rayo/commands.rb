module Adhearsion
  module Rayo
    module Commands
      extend ActiveSupport::Autoload

      autoload :Conference
      autoload :Dial
      autoload :Input
      autoload :Output
      autoload :Record

      include Punchblock::Command
      include Conference
      include Dial
      include Input
      include Output
      include Record

      def accept(headers = nil)
        write_and_await_response Accept.new(:headers => headers)
      end

      def answer(headers = nil)
        write_and_await_response Answer.new(:headers => headers)
      end

      def reject(reason = :busy, headers = nil)
        write_and_await_response Reject.new(:reason => reason, :headers => headers)
      end

      def hangup(headers = nil)
        write_and_await_response Punchblock::Command::Hangup.new(:headers => headers)
      end

      def mute
        write_and_await_response Punchblock::Command::Mute.new
      end

      def unmute
        write_and_await_response Punchblock::Command::Unmute.new
      end

      def write(command)
        call.write_command command
      end

      def write_and_await_response(command, timeout = 60.seconds)
        write command
        response = command.response timeout
        raise response if response.is_a? Exception
        command
      end

      def execute_component_and_await_completion(component)
        write_and_await_response component

        yield component if block_given?

        complete_event = component.complete_event.resource
        raise StandardError, complete_event.reason.details if complete_event.reason.is_a? Punchblock::Event::Complete::Error
        component
      end
    end
  end
end
