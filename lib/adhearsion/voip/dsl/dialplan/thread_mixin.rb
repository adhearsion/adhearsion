require 'ostruct'
module Adhearsion
  module VoIP
    module DSL
      module Dialplan
        module ThreadMixin

          def call
            @thread_call_struct ||= OpenStruct.new
          end

        end
      end
    end
  end
end