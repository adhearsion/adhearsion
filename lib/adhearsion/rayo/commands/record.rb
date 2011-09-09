module Adhearsion
  module Rayo
    module Commands
      module Record

        def record(options = {})
          async = options[:async]? true : false
          on_complete = options[:on_complete]
          options.delete :async
          options.delete :on_complete

          if async
            # Executes the dialplan with the given parameters most commonly used for voicemail applications
            # Accepts a :terminator digit to end the recording
            options.merge! :event_callback => lambda { |recording| on_complete }
            execute_component_and_await_completion Punchblock::Component::Record.new(options), &on_complete
          else
            # Executes the dialplan with the given parameters most commonly used for supervision mode.
            # Accepts keypress/DTMF to pause/unpause the recording
            execute_component_and_await_completion Punchblock::Component::Record.new(options)
          end
        end# record(async, options = {}, &block)

      end
    end
  end
end
