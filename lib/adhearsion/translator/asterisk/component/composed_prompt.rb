# encoding: utf-8

require 'adhearsion/translator/asterisk/component/input_component'
require 'adhearsion/translator/asterisk/component/stop_playback'

module Adhearsion
  module Translator
    class Asterisk
      module Component
        class ComposedPrompt < Component
          include InputComponent
          include StopPlayback

          def execute
            validate
            output_command.request!
            setup_dtmf_recognizer

            @output_incomplete = true

            @output_component = Output.new(output_command, @call)
            call.register_component @output_component
            fut = Celluloid::Future.new { @output_component.execute }

            case @output_command.response
            when Adhearsion::Rayo::Ref
              send_ref
            else
              set_node_response @output_command.response
            end

            if @component_node.barge_in
              @barged = false
              register_dtmf_event_handler
              fut.value # Block until output is complete before starting timers
              @output_incomplete = false
              start_timers unless @barged
            else
              fut.value # Block until output is complete before allowing input
              register_dtmf_event_handler
              start_timers
            end
          end

          def process_dtmf(digit)
            if @component_node.barge_in && @output_incomplete
              @output_component.stop_playback Adhearsion::Event::Complete::Stop.new
              @barged = true
            end
            super
          end

          def output_command
            @output_command ||= @component_node.output
          end

          private

          def input_node
            @input_node ||= @component_node.input
          end

          def register_dtmf_event_handler
            @dtmf_handler_id = call.register_handler :ami, [{:name => 'DTMF', [:[], 'End'] => 'Yes'}, {:name => 'DTMFEnd'}] do |event|
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
