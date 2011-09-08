module Adhearsion
  module Rayo
    module Commands
      module Record

        def record(options = {}, &block)
          execute_component_and_await_completion Punchblock::Component::Record.new(options), &block
        end# record(text, options = {}, &block)

        def stop_recording(terminator = nil)
          if terminator?
            options.merge! :terminator => terminator
            execute_component_and_await_completion Punchblock::Component::Record.new(options), &block
          end
        end# stop_recording(terminator = nil)

      end
    end
  end
end
