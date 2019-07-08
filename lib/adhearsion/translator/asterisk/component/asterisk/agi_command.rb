# encoding: utf-8

module Adhearsion
  module Translator
    class Asterisk
      module Component
        module Asterisk
          class AGICommand < Component
            def setup
              @agi = Translator::Asterisk::AGICommand.new id, @call.channel, @component_node.name, *@component_node.params
            end

            def execute
              send_ref
              @agi.execute ami_client
            rescue RubyAMI::Error
              set_node_response false
            rescue ChannelGoneError
              set_node_response Adhearsion::ProtocolError.new.setup(:item_not_found, "Could not find a call with ID #{call_id}", call_id)
            end

            def handle_ami_event(event)
              if (event.name == 'AsyncAGI' && event['SubEvent'] == 'Exec') || event.name == 'AsyncAGIExec'
                send_complete_event success_reason(event)
                if @component_node.name == 'ASYNCAGI BREAK' && @call.channel_var('ADHEARSION_END_ON_ASYNCAGI_BREAK')
                  @call.handle_hangup_event nil, event.best_time
                end
              end
            end

            private

            def success_reason(event)
              result = @agi.parse_result event
              Adhearsion::Rayo::Component::Asterisk::AGI::Command::Complete::Success.new result
            end
          end
        end
      end
    end
  end
end
