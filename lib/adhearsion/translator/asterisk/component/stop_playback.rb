# encoding: utf-8

require 'active_support/core_ext/string/filters'

module Adhearsion
  module Translator
    class Asterisk
      module Component
        module StopPlayback
          def execute_command(command)
            return super unless command.is_a?(Adhearsion::Rayo::Component::Stop)
            if @complete
              command.response = Adhearsion::ProtocolError.new.setup 'component-already-stopped', "Component #{id} is already stopped", call_id, id
            else
              stop_playback Adhearsion::Event::Complete::Stop.new
              command.response = true
            end
          end

          def stop_playback(complete_reason)
            if Gem::Version.new(ami_client.version) >= Gem::Version.new('2.0.0')
              @call.stop_playback
              send_complete_event complete_reason
            else
              stop_by_redirect complete_reason
            end
          end

        protected

          def stop_by_redirect(complete_reason)
            call.register_handler :ami, [{name: 'AsyncAGI', [:[], 'SubEvent'] => 'Start'}, {name: 'AsyncAGIStart'}] do |event|
              send_complete_event complete_reason
            end
            call.redirect_back
          end
        end
      end
    end
  end
end
