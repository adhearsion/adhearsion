# encoding: utf-8

module Adhearsion
  class CallController
    module Record
      RecordError = Class.new StandardError # Represents failure to record such as when a file cannot be written.

      #
      # Start a recording
      #
      # @example Record in a blocking way and use result
      #   record_result = record :start_beep => true, :max_duration => 60_000
      #   logger.info "Recording saved to #{record_result.complete_event.recording.uri}"
      # @example Asynchronous recording, execution of the controller will continue
      #   record :async => true do |event|
      #     logger.info "Async recording saved to #{event.recording.uri}"
      #   end
      #
      # @param [Hash] options
      # @param [Block] block to process result of the record method, it will receive the complete Event for the method.
      # @option options [Boolean, Optional] :async Execute asynchronously. Defaults to false
      # @option options [Boolean, Optional] :start_beep Indicates whether subsequent record will be preceded with a beep. Default is true.
      # @option options [Boolean, Optional] :start_paused Whether subsequent record will start in PAUSE mode. Default is false.
      # @option options [String, Optional] :max_duration Indicates the maximum duration (milliseconds) for a recording.
      # @option options [String, Optional] :format File format used during recording.
      # @option options [String, Optional] :format File format used during recording.
      # @option options [String, Optional] :initial_timeout Controls how long (milliseconds) the recognizer should wait after the end of the prompt for the caller to speak before sending a Recorder event.
      # @option options [String, Optional] :final_timeout Controls the length (milliseconds) of a period of silence after callers have spoken to conclude they finished.
      #
      # @return Punchblock::Component::Record
      #
      def record(options = {})
        async = options.delete :async

        component = ::Punchblock::Component::Record.new options
        component.register_event_handler ::Punchblock::Event::Complete do |event|
          catching_standard_errors { yield event if block_given? }
        end

        if async
          write_and_await_response component
        else
          execute_component_and_await_completion component
        end
      end
    end
  end
end
