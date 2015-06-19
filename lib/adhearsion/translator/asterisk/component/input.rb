# encoding: utf-8

require 'adhearsion/translator/asterisk/component/input_component'

module Adhearsion
  module Translator
    class Asterisk
      module Component
        class Input < Component

          include InputComponent

          def execute
            @call.send_progress
            super
            @dtmf_handler_id = register_dtmf_event_handler
          end

          private

          def register_dtmf_event_handler
            call.register_handler :ami, [{:name => 'DTMF', [:[], 'End'] => 'Yes'}, {:name => 'DTMFEnd'}] do |event|
              process_dtmf event['Digit']
            end
          end

          def unregister_dtmf_event_handler
            call.unregister_handler :ami, @dtmf_handler_id if instance_variable_defined?(:@dtmf_handler_id)
          end
        end
      end
    end
  end
end
