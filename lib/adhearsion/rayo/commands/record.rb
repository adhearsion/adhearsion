module Adhearsion
  module Rayo
    module Commands
      module Record

        def record(options = {})
          async = options[:async]? true : false
          on_complete = options[:on_complete]
          options.delete :async
          options.delete :on_complete

          options.merge! :event_callback => lambda { |event| on_complete.call(event.recording) }
          execute_component_and_await_completion Punchblock::Component::Record.new(options)
        end# record(async, options = {}, &block)

      end
    end
  end
end
