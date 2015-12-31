# encoding: utf-8

require 'adhearsion/translator/asterisk/component/stop_playback'
require 'adhearsion/translator/asterisk/component/mrcp_recog_prompt'

module Adhearsion
  module Translator
    class Asterisk
      module Component
        class MRCPNativePrompt < Component
          include StopPlayback
          include MRCPRecogPrompt

          private

          def validate
            raise OptionError, "The renderer #{renderer} is unsupported." unless renderer == 'asterisk'
            raise OptionError, "The recognizer #{recognizer} is unsupported." unless recognizer == 'unimrcp'

            raise OptionError, 'A document is required.' unless output_node.render_documents.count > 0
            raise OptionError, 'Only one document is allowed.' if output_node.render_documents.count > 1
            raise OptionError, 'Only inline documents are allowed.' if first_doc.url
            raise OptionError, 'Only one audio file is allowed.' if first_doc.size > 1

            raise OptionError, 'A grammar is required.' unless input_node.grammars.count > 0

            super
          end

          def renderer
            (output_node.renderer || :asterisk).to_s
          end

          def recognizer
            (input_node.recognizer || :unimrcp).to_s
          end

          def execute_unimrcp_app
            execute_app 'MRCPRecog', grammars
          end

          def first_doc
            output_node.render_documents.first
          end

          def audio_filename
            path = if first_doc.ssml?
              first_doc.value.children.first.src
            else
              first_doc.value.first
            end.sub('file://', '')

            dir = File.dirname(path)
            basename = File.basename(path, '.*')
            if dir == '.'
              basename
            else
              File.join(dir, basename)
            end
          end

          def unimrcp_app_options
            super do |opts|
              opts[:f] = audio_filename
            end
          end
        end
      end
    end
  end
end
