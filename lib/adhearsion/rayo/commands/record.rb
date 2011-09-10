module Adhearsion
  module Rayo
    module Commands
      module Record
        #
        # Start a recording
        #
        # @param [Hash] options
        # @param [Block] &block to process result of the record method
        # @option options [Boolean, Optional] :async is default to false if not defined
        # @option options [Lambda, Optional] :on_complete if :async is set to true this will replace the &block parameter
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
          async = options[:async]? true : false
          on_complete = options[:on_complete]
          options.delete :async
          options.delete :on_complete

          if async
            options.merge! :event_callback => lambda { |event| on_complete.call(event.recording) if event.is_a? Punchblock::Event::Complete }
            execute_component_and_await_completion Punchblock::Component::Record.new(options)
          else
            evented = execute_component_and_await_completion Punchblock::Component::Record.new(options)
            block.call(evented.complete_event.resource.recording)
          end
        end# record(options = {}, &block)

      end
    end
  end
end
