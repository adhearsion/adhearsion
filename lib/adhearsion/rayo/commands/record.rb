module Adhearsion
  module Rayo
    module Commands
      module Record

        def record(options = {}, &block)
          async = options[:async]? true : false
          on_complete = options[:on_complete]
          options.delete :async
          options.delete :on_complete

          # record :async => true
          # Provides recording case for voicemail system
          if async
            options.merge! :event_callback => lambda { |event| on_complete.call(event.recording) if event.is_a? Punchblock::Event::Complete }
            execute_component_and_await_completion Punchblock::Component::Record.new(options)
          else
            evented = execute_component_and_await_completion Punchblock::Component::Record.new(options)
            block.call(evented.complete_event.resource.recording)
          end
        end# record(async, options = {}, &block)

      end
    end
  end
end
