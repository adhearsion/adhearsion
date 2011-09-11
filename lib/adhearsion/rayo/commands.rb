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
      include Punchblock::Component
      include Conference
      include Dial
      include Input
      include Output
      include Record

      def accept(headers = nil)
        call.accept headers
      end

      def answer(headers = nil)
        call.answer headers
      end

      def reject(reason = :busy, headers = nil)
        call.reject reason, headers
      end

      def hangup(headers = nil)
        call.hangup! headers
      end

      def mute
        write_and_await_response Punchblock::Command::Mute.new
      end

      def unmute
        write_and_await_response Punchblock::Command::Unmute.new
      end

      def write_and_await_response(command, timeout = nil)
        call.write_and_await_response command, timeout
      end
      alias :execute_component :write_and_await_response

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
