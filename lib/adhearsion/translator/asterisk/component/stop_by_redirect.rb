# encoding: utf-8

require 'active_support/core_ext/string/filters'

module Adhearsion
  module Translator
    class Asterisk
      module Component
        module StopByRedirect
          def execute_command(command)
            return super unless command.is_a?(Adhearsion::Rayo::Component::Stop)
            if @complete
              command.response = Adhearsion::ProtocolError.new.setup 'component-already-stopped', "Component #{id} is already stopped", call_id, id
            else
              command.response = stop_by_redirect Adhearsion::Event::Complete::Stop.new
            end
          end

          def stop_by_redirect(complete_reason)
            call.register_handler :ami, [{name: 'AsyncAGI', [:[], 'SubEvent'] => 'Start'}, {name: 'AsyncAGIStart'}] do |event|
              send_complete_event complete_reason
            end
            call.redirect_back
            true
          rescue ChannelGoneError
            ProtocolError.new.setup :item_not_found, "Could not find a call with ID #{call_id}", call_id
          end
        end
      end
    end
  end
end
