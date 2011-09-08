module Adhearsion
  module Rayo
    module Commands
      module Record

        def record(options = {}, &block)
          execute_component_and_await_completion Punchblock::Component::Record.new(options), &block
        end# record(text, options = {}, &block)

      end
    end
  end
end
