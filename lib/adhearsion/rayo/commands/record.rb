module Adhearsion
  module Rayo
    module Commands
      module Record
        #
        # Start a recording
        #
        # @param [Hash] options
        # @param [Block] &block to process result of the record method
        # @option options [Boolean, Optional] :async Execute asynchronously. Defaults to false
        # @option options [Proc, Optional] :on_complete Block to be executed on completion when this method is invoked asynchronously
        # @option options [Boolean, Optional] :start_beep Indicates whether subsequent record will be preceded with a beep. Default is true.
        # @option options [Boolean, Optional] :start_paused Whether subsequent record will start in PAUSE mode. Default is false.
        # @option options [String, Optional] :max_duration Indicates the maximum duration (milliseconds) for a recording.
        # @option options [String, Optional] :format File format used during recording.
        # @option options [String, Optional] :format File format used during recording.
        # @option options [String, Optional] :initial_timeout Controls how long (milliseconds) the recognizer should wait after the end of the prompt for the caller to speak before sending a Recorder event.
        # @option options [String, Optional] :final_timeout Controls the length (milliseconds) of a period of silence after callers have spoken to conclude they finished.
        #
        # @return recording object

        def record(options = {}, &block)
          async = options.delete(:async) ? true : false
          on_complete = options.delete :on_complete

          callback = async ? on_complete : block

          if async
            result = execute_component Punchblock::Component::Record.new(options)
            result.event_callback = lambda { |event| callback.call event if event.is_a? Punchblock::Event::Complete }
          else
            result = execute_component_and_await_completion Punchblock::Component::Record.new(options)
            yield result.complete_event.resource if block_given?
          end
          result
        end
      end
    end
  end
end
