# encoding: utf-8

require 'ruby_speech'
require 'adhearsion/translator/asterisk/unimrcp_app'

module Adhearsion
  module Translator
    class Asterisk
      module Component
        module MRCPRecogPrompt
          UniMRCPError = Class.new Error

          MRCP_ERRORS = {
            '004' => 'RECOGNIZE failed due to grammar load failure.',
            '005' => 'RECOGNIZE failed due to grammar compilation failure.',
            '006' => 'RECOGNIZE request terminated prematurely due to a recognizer error.',
            '007' => 'RECOGNIZE request terminated because speech was too early.',
            '009' => 'Failure accessing a URI.',
            '010' => 'Language not supported.',
            '016' => 'Any DEFINE-GRAMMAR error other than grammar-load-failure and grammar-compilation-failure.',
          }

          def execute
            setup_defaults
            validate
            send_ref
            execute_unimrcp_app
            complete
          rescue ChannelGoneError
            call_ended
          rescue UniMRCPError => e
            complete_with_error e.message
          rescue RubyAMI::Error => e
            complete_with_error "Terminated due to AMI error '#{e.message}'"
          rescue OptionError => e
            with_error 'option error', e.message
          end

          private

          def validate
            [:interrupt_on, :start_offset, :start_paused, :repeat_interval, :repeat_times, :max_time].each do |opt|
              raise OptionError, "A #{opt} value is unsupported on Asterisk." if output_node.send opt
            end

            raise OptionError, "An initial-timeout value must be -1 or a positive integer." if @initial_timeout < -1
            raise OptionError, "An inter-digit-timeout value must be -1 or a positive integer." if @inter_digit_timeout < -1
            raise OptionError, "A recognition-timeout value must be -1, 0, or a positive integer." if @recognition_timeout < -1
            raise OptionError, "A max-silence value must be -1, 0, or a positive integer." if @max_silence < -1
            raise OptionError, "A speech-complete-timeout value must be -1, 0, or a positive integer." if @speech_complete_timeout < -1
            raise OptionError, "A hotword-max-duration value must be -1, 0, or a positive integer." if @hotword_max_duration < -1
            raise OptionError, "A hotword-min-duration value must be -1, 0, or a positive integer." if @hotword_min_duration < -1
            raise OptionError, "A dtmf-terminate-timeout value must be -1, 0, or a positive integer." if @dtmf_terminate_timeout < -1
            raise OptionError, "An n-best-list-length value must be a positive integer." if @n_best_list_length && @n_best_list_length < 1
            raise OptionError, "A speed-vs-accuracy value must be a positive integer." if @speed_vs_accuracy && @speed_vs_accuracy < 0

            begin
              grammars
            rescue => e
              logger.error e
              raise OptionError, 'The requested grammars could not be parsed.'
            end
          end

          def execute_app(app, *args)
            UniMRCPApp.new(app, *args, unimrcp_app_options).execute @call
          end

          def unimrcp_app_options
            {uer: 1, b: (@component_node.barge_in == false ? 0 : 1)}.tap do |opts|
              opts[:nit] = @initial_timeout if @initial_timeout > -1
              opts[:dit] = @inter_digit_timeout if @inter_digit_timeout > -1
              opts[:dttc] = input_node.terminator if input_node.terminator
              opts[:spl] = input_node.language if input_node.language
              opts[:ct] = input_node.min_confidence if input_node.min_confidence
              opts[:sl] = input_node.sensitivity if input_node.sensitivity
              opts[:t]  = input_node.recognition_timeout if @recognition_timeout > -1
              opts[:sint]  = input_node.max_silence if @max_silence > -1
              opts[:sct]  = @speech_complete_timeout if @speech_complete_timeout > -1

              opts[:sva] = @speed_vs_accuracy if @speed_vs_accuracy
              opts[:nb] = @n_best_list_length if @n_best_list_length
              opts[:sit] = @start_input_timers unless @start_input_timers.nil?
              opts[:dtt] = @dtmf_terminate_timeout if @dtmf_terminate_timeout > -1
              opts[:sw] = @save_waveform unless @save_waveform.nil?
              opts[:nac] = @new_audio_channel unless @new_audio_channel.nil?
              opts[:rm] = @recognition_mode if @recognition_mode
              opts[:hmaxd] = @hotword_max_duration if @hotword_max_duration > -1
              opts[:hmind] = @hotword_min_duration if @hotword_min_duration > -1
              opts[:cdb] = @clear_dtmf_buffer unless @clear_dtmf_buffer.nil?
              opts[:enm] = @early_no_match unless @early_no_match.nil?
              opts[:iwu] = @input_waveform_uri if @input_waveform_uri
              opts[:mt] = @media_type if @media_type

              yield opts
            end
          end

          def setup_defaults
            @initial_timeout = input_node.initial_timeout || -1
            @inter_digit_timeout = input_node.inter_digit_timeout || -1
            @recognition_timeout = input_node.recognition_timeout || -1
            @max_silence = input_node.max_silence || -1
            @speech_complete_timeout = input_node.headers['Speech-Complete-Timeout'] || -1
            @speed_vs_accuracy = input_node.headers['Speed-Vs-Accuracy']
            @n_best_list_length = input_node.headers['N-Best-List-Length']
            @start_input_timers = input_node.headers['Start-Input-Timers']
            @dtmf_terminate_timeout = input_node.headers['DTMF-Terminate-Timeout'] || -1
            @save_waveform = input_node.headers['Save-Waveform']
            @new_audio_channel = input_node.headers['New-Audio-Channel']
            @recognition_mode = input_node.headers['Recognition-Mode']
            @hotword_max_duration = input_node.headers['Hotword-Max-Duration'] || -1
            @hotword_min_duration = input_node.headers['Hotword-Min-Duration'] || -1
            @clear_dtmf_buffer = input_node.headers['Clear-DTMF-Buffer']
            @early_no_match = input_node.headers['Early-No-Match']
            @input_waveform_uri = input_node.headers['Input-Waveform-URI']
            @media_type = input_node.headers['Media-Type']
          end

          def grammars
            @grammars ||= input_node.grammars.map do |d|
              if d.content_type
                d.value.to_doc.to_s
              else
                d.url
              end
            end.join ','
          end

          def first_doc
            output_node.render_documents.first
          end

          def audio_filename
            first_doc.value.first
          end

          def output_node
            @component_node.output
          end

          def input_node
            @component_node.input
          end

          def complete
            case @call.channel_var('RECOG_STATUS')
            when 'INTERRUPTED'
              send_complete_event Adhearsion::Rayo::Component::Input::Complete::NoMatch.new
            when 'ERROR'
              raise UniMRCPError
            else
              send_complete_event case cause = @call.channel_var('RECOG_COMPLETION_CAUSE')
              when '000', '008', '012'
                nlsml = RubySpeech.parse CGI.unescape(@call.channel_var('RECOG_RESULT'))
                Adhearsion::Rayo::Component::Input::Complete::Match.new nlsml: nlsml
              when '001', '003', '013', '014', '015'
                Adhearsion::Rayo::Component::Input::Complete::NoMatch.new
              when '002', '011'
                Adhearsion::Rayo::Component::Input::Complete::NoInput.new
              when *MRCP_ERRORS.keys
                raise UniMRCPError, MRCP_ERRORS[cause]
              else
                raise UniMRCPError
              end
            end
          end
        end
      end
    end
  end
end
