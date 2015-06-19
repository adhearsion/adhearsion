# encoding: utf-8

module Adhearsion
  module Translator
    class Asterisk
      module Component
        module Asterisk
          class AMIAction < Component
            attr_reader :translator

            def initialize(component_node, translator, ami_client)
              super component_node, nil
              @translator, @ami_client = translator, ami_client
            end

            def execute
              send_ref
              response = send_action
              final_event = send_events response
              send_complete_event success_reason(response, final_event)
            rescue RubyAMI::Error => e
              send_complete_event error_reason(e)
            end

            private

            def send_action
              @ami_client.send_action @component_node.name, action_headers
            end

            def error_reason(response)
              Adhearsion::Event::Complete::Error.new details: response.message
            end

            def success_reason(response, final_event = nil)
              headers = response.headers
              headers.merge! final_event.headers if final_event
              headers.delete 'ActionID'
              Adhearsion::Rayo::Component::Asterisk::AMI::Action::Complete::Success.new message: headers.delete('Message'), text_body: response.text_body, headers: headers
            end

            def send_events(response)
              final_event = response.events.pop
              response.events.each do |e|
                send_event pb_event_from_ami_event(e)
              end
              final_event
            end

            def pb_event_from_ami_event(ami_event)
              headers = ami_event.headers
              headers.delete 'ActionID'
              Adhearsion::Event::Asterisk::AMI.new name: ami_event.name, headers: headers
            end

            def action_headers
              headers = {}
              @component_node.params.each_pair do |key, value|
                headers[key.to_s.capitalize] = value
              end
              headers
            end
          end
        end
      end
    end
  end
end
