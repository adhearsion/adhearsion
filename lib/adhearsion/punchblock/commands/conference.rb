module Adhearsion
  module Punchblock
    module Commands
      module Conference
        #
        # Join a named conference room
        #
        # @param [String] conference_id
        # @param [Hash] options
        # @option options [Announcement, Hash, Optional] :announcement to play on entry
        # @option options [Music, Hash, Optional] :music to play to the participant when no moderator is present
        # @option options [Boolean, Optional] :mute If set to true, the user will be muted in the conference
        # @option options [Boolean, Optional] :moderator Whether or not the conference should be moderated
        # @option options [Boolean, Optional] :tone_passthrough Identifies whether or not conference members can hear the tone generated when a a key on the phone is pressed.
        # @option options [String, Optional] :terminator This is the touch-tone key (also known as "DTMF digit") used to exit the conference.
        #
        def conference(conference_id, options = {}, &block)
          on_speaking = options.delete :on_speaking
          on_finished_speaking = options.delete :on_finished_speaking
          options.merge! :name => conference_id
          component = ::Punchblock::Component::Tropo::Conference.new options
          if on_speaking
            component.register_event_handler ::Punchblock::Component::Tropo::Conference::Speaking do |event|
              on_speaking.call event.speaking_call_id
              throw :pass
            end
          end
          if on_finished_speaking
            component.register_event_handler ::Punchblock::Component::Tropo::Conference::FinishedSpeaking do |event|
              on_finished_speaking.call event.speaking_call_id
              throw :pass
            end
          end
          execute_component_and_await_completion component, &block
        end
      end
    end
  end
end
