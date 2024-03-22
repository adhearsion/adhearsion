# encoding: utf-8

require 'celluloid'
require 'ruby_ami'

require 'adhearsion/translator/asterisk/agi_command'
require 'adhearsion/translator/asterisk/call'
require 'adhearsion/translator/asterisk/channel'
require 'adhearsion/translator/asterisk/component'

module Adhearsion
  module Translator
    class Asterisk
      include Celluloid

      # Indicates that a command was executed against a channel which no longer exists
      ChannelGoneError = Class.new Error

      attr_reader :ami_client, :connection, :calls, :bridges

      REDIRECT_CONTEXT = 'adhearsion-redirect'
      REDIRECT_EXTENSION = '1'
      REDIRECT_PRIORITY = '1'

      EVENTS_ALLOWED_BRIDGED = %w{AGIExec AsyncAGI}

      trap_exit :actor_died

      # Set the AMI event filter to be applied to incoming AMI events. A truthy return value will send the event via Rayo to the client (Adhearsion).
      #
      # @param [#[<RubyAMI::Event>]] filter
      #
      # @example A lambda
      #   Translator::Asterisk.event_filter = ->(event) { event.name == 'AsyncAGI' }
      #
      def self.event_filter=(filter)
        @event_filter = filter
      end

      def self.event_passes_filter?(event)
        @event_filter ? !!@event_filter[event] : true
      end

      self.event_filter = nil

      def initialize(ami_client, connection)
        @ami_client, @connection = ami_client, connection
        @calls, @components, @channel_to_call_id, @bridges = {}, {}, {}, {}
      end

      def register_call(call)
        @channel_to_call_id[call.channel] = call.id
        @calls[call.id] ||= call
      end

      def deregister_call(id, channel)
        @channel_to_call_id.delete channel
        @calls.delete id
      end

      def call_with_id(call_id)
        @calls[call_id]
      end

      def call_for_channel(channel)
        call_with_id @channel_to_call_id[Channel.new(channel).name]
      end

      def register_component(component)
        @components[component.id] ||= component
      end

      def deregister_component(id)
        @components.delete id
      end

      def component_with_id(component_id)
        @components[component_id]
      end

      def handle_ami_event(event)
        return unless event.is_a? RubyAMI::Event

        if event.name == 'FullyBooted'
          handle_pb_event Adhearsion::Rayo::Connection::Connected.new
          run_at_fully_booted
          return
        end

        handle_varset_ami_event event

        ami_dispatch_to_or_create_call event
        if !ami_event_known_call?(event) && self.class.event_passes_filter?(event)
          handle_pb_event Adhearsion::Event::Asterisk::AMI.new(name: event.name, headers: event.headers)
        end
      end

      def handle_pb_event(event)
        connection.handle_event event
      end

      def send_message(call_id, domain, body, options = {})
        call = call_with_id call_id
        call.send_message body if call
      end

      def execute_command(command, options = {})
        command.request!

        command.target_call_id ||= options[:call_id]
        command.component_id ||= options[:component_id]

        if command.target_call_id
          execute_call_command command
        elsif command.component_id
          execute_component_command command
        else
          execute_global_command command
        end
      end

      def execute_call_command(command)
        if call = call_with_id(command.target_call_id)
          begin
            call.execute_command command
          rescue => e
            Adhearsion::Events.trigger :exception, [e, logger]
            deregister_call call.id, call.channel
            command.response = Adhearsion::ProtocolError.new.setup :error, "Unknown error executing command on call #{command.target_call_id}", command.target_call_id
          end
        else
          command.response = Adhearsion::ProtocolError.new.setup :item_not_found, "Could not find a call with ID #{command.target_call_id}", command.target_call_id
        end
      end

      def execute_component_command(command)
        if (component = component_with_id(command.component_id))
          component.execute_command command
        else
          command.response = Adhearsion::ProtocolError.new.setup :item_not_found, "Could not find a component with ID #{command.component_id}", command.target_call_id, command.component_id
        end
      end

      def execute_global_command(command)
        case command
        when Adhearsion::Rayo::Component::Asterisk::AMI::Action
          component = Component::Asterisk::AMIAction.new command, current_actor, ami_client
          register_component component
          component.execute
        when Adhearsion::Rayo::Command::Dial
          if call = call_with_id(command.uri)
            command.response = Adhearsion::ProtocolError.new.setup(:conflict, 'Call ID already in use')
          else
            call = Call.new command.to, self, ami_client, connection, nil, command.uri
            register_call call
            call.dial command
          end
        else
          command.response = Adhearsion::ProtocolError.new.setup 'command-not-acceptable', "Did not understand command"
        end
      end

      def run_at_fully_booted
        send_ami_action 'Command', 'Command' => "dialplan add extension #{REDIRECT_EXTENSION},#{REDIRECT_PRIORITY},AGI,agi:async into #{REDIRECT_CONTEXT}"

        result = send_ami_action 'Command', 'Command' => "dialplan show #{REDIRECT_CONTEXT}"
        if result.text_body =~ /failed/
          logger.error "Adhearsion failed to add the #{REDIRECT_EXTENSION} extension to the #{REDIRECT_CONTEXT} context. Please add a [#{REDIRECT_CONTEXT}] entry to your dialplan."
        end

        check_recording_directory
      end

      def check_recording_directory
        logger.warn "Recordings directory #{Component::Record::RECORDING_BASE_PATH} does not exist. Recording might not work. This warning can be ignored if Adhearsion is running on a separate machine than Asterisk. See http://adhearsion.com/docs/call-controllers#recording" unless File.exist?(Component::Record::RECORDING_BASE_PATH)
      end

      def actor_died(actor, reason)
        return unless reason
        if id = @calls.key(actor)
          @calls.delete id
          end_event = Adhearsion::Event::End.new :target_call_id  => id,
                                                 :reason          => :error
          handle_pb_event end_event
        end
      end

      private

      def send_ami_action(name, headers = {})
        ami_client.send_action(name, headers)
      end

      def handle_varset_ami_event(event)
        return unless event.name == 'VarSet' && event['Variable'] == 'adhearsion_call_id' && (call = call_with_id event['Value'])

        @channel_to_call_id.delete call.channel
        call.channel = event['Channel']
        register_call call
      end

      def ami_dispatch_to_or_create_call(event)
        calls_for_event = channels_for_ami_event(event).inject({}) do |h, channel|
          call = call_for_channel channel
          h[channel] = call if call
          h
        end

        if !calls_for_event.empty?
          calls_for_event.each_pair do |channel, call|
            next if channel.bridged? && !EVENTS_ALLOWED_BRIDGED.include?(event.name)
            call.process_ami_event event
          end
        elsif event.name == "AsyncAGIStart" || (event.name == "AsyncAGI" && event['SubEvent'] == "Start")
          handle_async_agi_start_event event
        end
      end

      def channels_for_ami_event(event)
        [event['Channel'], event['Channel1'], event['Channel2']].compact.map { |channel| Channel.new(channel) }
      end

      def ami_event_known_call?(event)
        (event['Channel'] && call_for_channel(event['Channel'])) ||
          (event['Channel1'] && call_for_channel(event['Channel1'])) ||
          (event['Channel2'] && call_for_channel(event['Channel2']))
      end

      def handle_async_agi_start_event(event)
        env = RubyAMI::AsyncAGIEnvironmentParser.new(event['Env']).to_hash

        return if env[:agi_extension] == 'h' || env[:agi_type] == 'Kill'

        call = Call.new event['Channel'], self, ami_client, connection, env
        register_call call
        call.send_offer
      end
    end
  end
end
