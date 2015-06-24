# encoding: utf-8

require 'has_guarded_handlers'
require 'adhearsion/translator/asterisk/ami_error_converter'

module Adhearsion
  module Translator
    class Asterisk
      class Call
        include HasGuardedHandlers

        InvalidCommandError = Class.new Error

        OUTBOUND_CHANNEL_MATCH = /.* <(?<channel>.*)>/.freeze

        attr_reader :id, :channel, :translator, :agi_env, :direction, :pending_joins

        HANGUP_CAUSE_TO_END_REASON = Hash.new { :error }
        HANGUP_CAUSE_TO_END_REASON[0] = :hungup
        HANGUP_CAUSE_TO_END_REASON[16] = :hungup
        HANGUP_CAUSE_TO_END_REASON[17] = :busy
        HANGUP_CAUSE_TO_END_REASON[18] = :timeout
        HANGUP_CAUSE_TO_END_REASON[19] = :reject
        HANGUP_CAUSE_TO_END_REASON[21] = :reject
        HANGUP_CAUSE_TO_END_REASON[22] = :reject
        HANGUP_CAUSE_TO_END_REASON[102] = :timeout

        def initialize(channel, translator, ami_client, connection, agi_env = nil, id = nil)
          @channel, @translator, @ami_client, @connection = channel, translator, ami_client, connection
          @agi_env = agi_env || {}
          @id = id || Adhearsion.new_uuid
          @components = {}
          @answered = false
          @pending_joins = {}
          @progress_sent = false
          @block_commands = false
          @channel_variables = {}
          @hangup_cause = nil
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

        def send_offer
          @direction = :inbound
          send_pb_event offer_event
        end

        def channel_var(variable)
          @channel_variables[variable] || fetch_channel_var(variable)
        end

        def to_s
          "#<#{self.class}:#{id} Channel: #{channel.inspect}>"
        end
        alias :inspect :to_s

        def dial(dial_command)
          @direction = :outbound
          channel = dial_command.to || ''
          channel.match(OUTBOUND_CHANNEL_MATCH) { |m| channel = m[:channel] }
          params = { :async       => true,
                     :context     => REDIRECT_CONTEXT,
                     :exten       => REDIRECT_EXTENSION,
                     :priority    => REDIRECT_PRIORITY,
                     :channel     => channel,
                     :callerid    => dial_command.from
                   }
          params[:variable] = variable_for_headers dial_command.headers
          params[:timeout] = dial_command.timeout unless dial_command.timeout.nil?

          originate_action = Adhearsion::Rayo::Component::Asterisk::AMI::Action.new :name => 'Originate',
                                                                              :params => params
          originate_action.request!
          translator.async.execute_global_command originate_action
          dial_command.response = Adhearsion::Rayo::Ref.new uri: id
        end

        def outbound?
          direction == :outbound
        end

        def inbound?
          direction == :inbound
        end

        def answered?
          @answered
        end

        def send_progress
          return if answered? || outbound? || @progress_sent
          @progress_sent = true
          execute_agi_command "EXEC Progress"
        end

        def channel=(other)
          @channel = other
        end

        def process_ami_event(ami_event)
          if Asterisk.event_passes_filter?(ami_event)
            send_pb_event Adhearsion::Event::Asterisk::AMI.new(name: ami_event.name, headers: ami_event.headers)
          end

          case ami_event.name
          when 'Hangup'
            handle_hangup_event ami_event['Cause'].to_i, ami_event.best_time
          when 'AsyncAGI'
            component_for_command_id_handle ami_event

            if @answered == false && ami_event['SubEvent'] == 'Start'
              @answered = true
              send_pb_event Adhearsion::Event::Answered.new(timestamp: ami_event.best_time)
            end
          when 'AsyncAGIStart'
            component_for_command_id_handle ami_event

            if @answered == false
              @answered = true
              send_pb_event Adhearsion::Event::Answered.new(timestamp: ami_event.best_time)
            end
          when 'AsyncAGIExec', 'AsyncAGIEnd'
            component_for_command_id_handle ami_event
          when 'Newstate'
            case ami_event['ChannelState']
            when '5'
              send_pb_event Adhearsion::Event::Ringing.new(timestamp: ami_event.best_time)
            end
          when 'BridgeEnter'
            if other_call_channel = translator.bridges.delete(ami_event['BridgeUniqueid'])
              if other_call = translator.call_for_channel(other_call_channel)
                join_command  = other_call.pending_joins.delete channel
                join_command.response = true if join_command

                event = Adhearsion::Event::Joined.new call_uri: other_call.id, timestamp: ami_event.best_time
                send_pb_event event

                other_call_event = Adhearsion::Event::Joined.new call_uri: id, timestamp: ami_event.best_time
                other_call_event.target_call_id = other_call.id
                translator.handle_pb_event other_call_event
              end
            else
              translator.bridges[ami_event['BridgeUniqueid']] = ami_event['Channel']
            end
           when 'BridgeLeave'
            if other_call_channel = translator.bridges.delete(ami_event['BridgeUniqueid'] + '_leave')
              if other_call = translator.call_for_channel(other_call_channel)
                event = Adhearsion::Event::Unjoined.new call_uri: other_call.id, timestamp: ami_event.best_time
                send_pb_event event

                other_call_event = Adhearsion::Event::Unjoined.new call_uri: id, timestamp: ami_event.best_time
                other_call_event.target_call_id = other_call.id
                translator.handle_pb_event other_call_event
              end
            else
              translator.bridges[ami_event['BridgeUniqueid'] + '_leave'] = ami_event['Channel']
            end
          when 'OriginateResponse'
            if ami_event['Response'] == 'Failure' && ami_event['Uniqueid'] == '<null>'
              send_end_event :error, nil, ami_event.best_time
            end
          when 'BridgeExec'
            join_command   = @pending_joins.delete ami_event['Channel1']
            join_command ||= @pending_joins.delete ami_event['Channel2']
            join_command.response = true if join_command
          when 'Bridge'
            other_call_channel = ([ami_event['Channel1'], ami_event['Channel2']] - [channel]).first
            if other_call = translator.call_for_channel(other_call_channel)
              event = case ami_event['Bridgestate']
              when 'Link'
                Adhearsion::Event::Joined.new call_uri: other_call.id, timestamp: ami_event.best_time
              when 'Unlink'
                Adhearsion::Event::Unjoined.new call_uri: other_call.id, timestamp: ami_event.best_time
              end
              send_pb_event event
            end
          when 'Unlink'
            other_call_channel = ([ami_event['Channel1'], ami_event['Channel2']] - [channel]).first
            if other_call = translator.call_for_channel(other_call_channel)
              send_pb_event Adhearsion::Event::Unjoined.new(call_uri: other_call.id, timestamp: ami_event.best_time)
            end
          when 'VarSet'
            @channel_variables[ami_event['Variable']] = ami_event['Value']
          end
          trigger_handler :ami, ami_event
        end

        def send_message(body)
          execute_agi_command 'EXEC SendText', body
        rescue
        end

        def execute_command(command)
          if @block_commands
            command.response = Adhearsion::ProtocolError.new.setup :item_not_found, "Could not find a call with ID #{id}", id
            return
          end
          if command.component_id
            if component = component_with_id(command.component_id)
              component.execute_command command
            else
              command.response = Adhearsion::ProtocolError.new.setup :item_not_found, "Could not find a component with ID #{command.component_id} for call #{id}", id, command.component_id
            end
          end
          case command
          when Adhearsion::Rayo::Command::Accept
            if outbound?
              command.response = true
            else
              execute_agi_command 'EXEC RINGING'
              command.response = true
            end
          when Adhearsion::Rayo::Command::Answer
            execute_agi_command 'ANSWER'
            @answered = true
            command.response = true
          when Adhearsion::Rayo::Command::Hangup
            send_hangup_command
            @hangup_cause = :hangup_command
            command.response = true
          when Adhearsion::Rayo::Command::Join
            other_call = translator.call_with_id command.call_uri
            if other_call
              @pending_joins[other_call.channel] = command
              execute_agi_command 'EXEC Bridge', "#{other_call.channel},F(#{REDIRECT_CONTEXT},#{REDIRECT_EXTENSION},#{REDIRECT_PRIORITY})"
            else
              command.response = Adhearsion::ProtocolError.new.setup :service_unavailable, "Could not find join party with address #{command.call_uri}", id
            end
          when Adhearsion::Rayo::Command::Unjoin
            other_call = translator.call_with_id command.call_uri
            redirect_back other_call
            command.response = true
          when Adhearsion::Rayo::Command::Reject
            case command.reason
            when :busy
              execute_agi_command 'EXEC Busy'
            when :decline
              send_hangup_command 21
            when :error
              execute_agi_command 'EXEC Congestion'
            else
              execute_agi_command 'EXEC Congestion'
            end
            command.response = true
          when Adhearsion::Rayo::Command::Redirect
            execute_agi_command 'EXEC Transfer', command.to
            status = channel_var 'TRANSFERSTATUS'
            command.response = case status
            when 'SUCCESS'
              true
            else
              Adhearsion::ProtocolError.new.setup 'error', "TRANSFERSTATUS was #{status}", id
            end
          when Adhearsion::Rayo::Component::Asterisk::AGI::Command
            execute_component Component::Asterisk::AGICommand, command
          when Adhearsion::Rayo::Component::Output
            execute_component Component::Output, command
          when Adhearsion::Rayo::Component::Input
            execute_component Component::Input, command
          when Adhearsion::Rayo::Component::Prompt
            component_class = case command.input.recognizer
            when 'unimrcp'
              case command.output.renderer
              when 'unimrcp'
                Component::MRCPPrompt
              when 'asterisk'
                Component::MRCPNativePrompt
              else
                raise InvalidCommandError, 'Invalid recognizer/renderer combination'
              end
            else
              Component::ComposedPrompt
            end
            execute_component component_class, command
          when Adhearsion::Rayo::Component::Record
            execute_component Component::Record, command
          else
            command.response = Adhearsion::ProtocolError.new.setup 'command-not-acceptable', "Did not understand command for call #{id}", id
          end
        rescue InvalidCommandError => e
          command.response = Adhearsion::ProtocolError.new.setup :invalid_command, e.message, id
        rescue ChannelGoneError
          command.response = Adhearsion::ProtocolError.new.setup :item_not_found, "Could not find a call with ID #{id}", id
        rescue RubyAMI::Error => e
          command.response = Adhearsion::ProtocolError.new.setup 'error', e.message, id
        rescue Celluloid::DeadActorError
          command.response = Adhearsion::ProtocolError.new.setup :item_not_found, "Could not find a component with ID #{command.component_id} for call #{id}", id, command.component_id
        end

        #
        # @return [Hash] AGI result
        #
        # @raises RubyAMI::Error, ChannelGoneError
        def execute_agi_command(command, *params)
          agi = AGICommand.new Adhearsion.new_uuid, channel, command, *params
          response = Celluloid::Future.new
          register_tmp_handler :ami, [{name: 'AsyncAGI', [:[], 'SubEvent'] => 'Exec'}, {name: 'AsyncAGIExec'}], [{[:[], 'CommandID'] => agi.id}, {[:[], 'CommandId'] => agi.id}] do |event|
            response.signal Celluloid::SuccessResponse.new(nil, event)
          end
          agi.execute @ami_client
          event = response.value
          return unless event
          agi.parse_result event
        end

        def logger_id
          "#{self.class}: #{id}"
        end

        def redirect_back(other_call = nil)
          redirect_options = {
            'Channel'   => channel,
            'Exten'     => Asterisk::REDIRECT_EXTENSION,
            'Priority'  => Asterisk::REDIRECT_PRIORITY,
            'Context'   => Asterisk::REDIRECT_CONTEXT
          }
          redirect_options.merge!({
            'ExtraChannel' => other_call.channel,
            'ExtraExten'     => Asterisk::REDIRECT_EXTENSION,
            'ExtraPriority'  => Asterisk::REDIRECT_PRIORITY,
            'ExtraContext'   => Asterisk::REDIRECT_CONTEXT
          }) if other_call
          send_ami_action 'Redirect', redirect_options
        end

        def handle_hangup_event(code = nil, timestamp = nil)
          code ||= 16
          reason = @hangup_cause || HANGUP_CAUSE_TO_END_REASON[code]
          @block_commands = true
          @components.each_pair do |id, component|
            component.call_ended
          end
          send_end_event reason, code, timestamp
        end

        def after(*args, &block)
          translator.after(*args, &block)
        end

        private

        def fetch_channel_var(variable)
          result = @ami_client.send_action 'GetVar', 'Channel' => channel, 'Variable' => variable
          result['Value'] == '(null)' ? nil : result['Value']
        end

        def send_hangup_command(cause_code = 16)
          send_ami_action 'Hangup', 'Channel' => channel, 'Cause' => cause_code
        end

        def send_ami_action(name, headers = {})
          AMIErrorConverter.convert { @ami_client.send_action name, headers }
        end

        def send_end_event(reason, code = nil, timestamp = nil)
          end_event = Adhearsion::Event::End.new(reason: reason, platform_code: code, timestamp: timestamp)
          send_pb_event end_event
          translator.deregister_call id, channel
        end

        def execute_component(type, command, options = {})
          type.new(command, self).tap do |component|
            register_component component
            component.execute
          end
        end

        def send_pb_event(event)
          event.target_call_id = id
          translator.handle_pb_event event
        end

        def offer_event
          Adhearsion::Event::Offer.new :to      => agi_env.values_at(:agi_dnid, :agi_extension).detect { |e| e && e != 'unknown' },
                           :from    => "#{agi_env[:agi_calleridname]} <#{[agi_env[:agi_type], agi_env[:agi_callerid]].join('/')}>",
                           :headers => sip_headers
        end

        def sip_headers
          agi_env.to_a.inject({}) do |accumulator, element|
            accumulator['X-' + element[0].to_s] = element[1] || ''
            accumulator
          end
        end

        def component_for_command_id_handle(ami_event)
          if component = component_with_id(ami_event['CommandID'] || ami_event['CommandId'])
            component.handle_ami_event ami_event
          end
        end

        def variable_for_headers(headers)
          variables = { :adhearsion_call_id => id }
          header_counter = 51
          headers.each do |name, value|
            variables["SIPADDHEADER#{header_counter}"] = "\"#{name}: #{value}\""
            header_counter += 1
          end
          variables.inject([]) do |a, (k, v)|
            a << "#{k}=#{v}"
          end.join(',')
        end
      end
    end
  end
end
