module Adhearsion
  module Rayo
    module Commands
      module Record
        #
        # Start docs here
        #
        def record(format, options = [], &block)
          options.merge! :format => format
          execute_component_and_await_completion Punchblock::Component::Record.new(options), &block
        end# record(text, options = [], &block)
      end
    end
  end
end
