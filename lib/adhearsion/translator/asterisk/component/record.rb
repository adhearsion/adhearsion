# encoding: utf-8

module Adhearsion
  module Translator
    class Asterisk
      module Component
        class Record < Component
          RECORDING_BASE_PATH = '/var/adhearsion/record'

          def setup
            @complete_reason = nil
          end

          def execute
            max_duration = @component_node.max_duration || -1

            raise OptionError, 'Record cannot be used on a call that is not answered.' unless @call.answered?
            raise OptionError, 'A start-paused value of true is unsupported.' if @component_node.start_paused
            raise OptionError, 'An initial-timeout value is unsupported.' if @component_node.initial_timeout && @component_node.initial_timeout != -1
            raise OptionError, 'A final-timeout value is unsupported.' if @component_node.final_timeout && @component_node.final_timeout != -1
            raise OptionError, 'A max-duration value that is negative (and not -1) is invalid.' unless max_duration >= -1

            @format = @component_node.format || 'wav'

            call.register_tmp_handler :ami, :name => 'MonitorStop' do |event|
              finished
            end

            if @component_node.start_beep
              @call.execute_agi_command 'STREAM FILE', 'beep', '""'
            end

            ami_client.send_action 'Monitor', 'Channel' => call.channel, 'File' => filename, 'Format' => @format, 'Mix' => true
            unless max_duration == -1
              call.after max_duration/1000 do
                stop
              end
            end

            send_ref
          rescue ChannelGoneError
            set_node_response Adhearsion::ProtocolError.new.setup(:item_not_found, "Could not find a call with ID #{call_id}", call_id)
          rescue RubyAMI::Error => e
            with_error :platform_error, "Terminated due to AMI error '#{e.message}'"
          rescue OptionError => e
            with_error 'option error', e.message
          end

          def execute_command(command)
            case command
            when Adhearsion::Rayo::Component::Stop
              command.response = true
              ami_client.send_action 'StopMonitor', 'Channel' => call.channel
              @complete_reason = stop_reason
            when Adhearsion::Rayo::Component::Record::Pause
              ami_client.send_action 'PauseMonitor', 'Channel' => call.channel
              command.response = true
            when Adhearsion::Rayo::Component::Record::Resume
              ami_client.send_action 'ResumeMonitor', 'Channel' => call.channel
              command.response = true
            else
              super
            end
          end

          def finished
            send_complete_event(@complete_reason || max_duration_reason)
          end

          private

          def stop
            AMIErrorConverter.convert(nil) do
              ami_client.send_action 'StopMonitor', 'Channel' => call.channel
            end
          end

          def filename
            File.join RECORDING_BASE_PATH, id
          end

          def recording
            ext = @format.gsub('wav49', 'WAV')
            Adhearsion::Rayo::Component::Record::Recording.new :uri => "file://#{filename}.#{ext}"
          end

          def stop_reason
            Adhearsion::Event::Complete::Stop.new
          end

          def max_duration_reason
            Adhearsion::Rayo::Component::Record::Complete::MaxDuration.new
          end

          def send_complete_event(reason)
            super reason, recording
          end
        end
      end
    end
  end
end
