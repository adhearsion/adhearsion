# encoding: utf-8

module Adhearsion
  module Translator
    class Asterisk
      module Component
        class Component
          attr_reader :id, :call, :call_id

          def initialize(component_node, call = nil)
            @component_node, @call = component_node, call
            @call_id = call.id if call
            @id = Adhearsion.new_uuid
            @complete = false
            setup
          end

          def setup
          end

          def execute_command(command)
            command.response = Adhearsion::ProtocolError.new.setup 'command-not-acceptable', "Did not understand command for component #{id}", call_id, id
          end

          def send_complete_event(reason, recording = nil)
            return if @complete
            @complete = true
            event = Adhearsion::Event::Complete.new reason: reason, recording: recording
            send_event event
            call.deregister_component id if call
            translator.deregister_component id
          end

          def send_event(event)
            event.component_id    = id
            event.target_call_id  = call_id
            event.source_uri      = id
            translator.handle_pb_event event
          end

          def logger_id
            "#{self.class}: #{call_id ? "Call ID: #{call_id}, Component ID: #{id}" : id}"
          end

          def call_ended
            send_complete_event Adhearsion::Event::Complete::Hangup.new
          end

          private

          def translator
            @translator ||= call.translator
          end

          def ami_client
            translator.ami_client
          end

          def set_node_response(value)
            @component_node.response = value
          end

          def send_ref
            set_node_response Adhearsion::Rayo::Ref.new uri: id
          end

          def with_error(name, text)
            set_node_response Adhearsion::ProtocolError.new.setup(name, text)
          end

          def complete_with_error(error)
            send_complete_event Adhearsion::Event::Complete::Error.new(details: error)
          end
        end
      end
    end
  end
end

%w{
  asterisk
  composed_prompt
  input
  output
  mrcp_prompt
  mrcp_native_prompt
  record
  stop_by_redirect
}.each { |component| require "adhearsion/translator/asterisk/component/#{component}" }
