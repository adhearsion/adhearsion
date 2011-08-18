module Adhearsion
  module DSL
    class Dialplan
      module ThreadMixin
        def call
          @thread_call_struct ||= OpenStruct.new
        end
      end
    end
  end
end
