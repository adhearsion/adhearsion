# encoding: utf-8

require 'adhearsion/translator/asterisk/component/mrcp_recog_prompt'

module Adhearsion
  module Translator
    class Asterisk
      module Component
        class MRCPPrompt < Component
          include StopByRedirect
          include MRCPRecogPrompt

          private

          def validate
            raise OptionError, "The renderer #{renderer} is unsupported." unless renderer == 'unimrcp'
            raise OptionError, "The recognizer #{recognizer} is unsupported." unless recognizer == 'unimrcp'
            raise OptionError, 'An SSML document is required.' unless output_node.render_documents.count > 0
            raise OptionError, 'Only one document is allowed.' if output_node.render_documents.count > 1
            raise OptionError, 'A grammar is required.' unless input_node.grammars.count > 0

            begin
              render_doc
            rescue => e
              logger.error e
              raise OptionError, 'The requested render document could not be parsed.'
            end

            super
          end

          def renderer
            (output_node.renderer || :unimrcp).to_s
          end

          def recognizer
            (input_node.recognizer || :unimrcp).to_s
          end

          def execute_unimrcp_app
            execute_app 'SynthAndRecog', render_doc, grammars
          end

          def render_doc
            @render_doc ||= begin
              d = output_node.render_documents.first
              if d.content_type
                d.value.to_doc.to_s
              else
                d.url
              end
            end
          end

          def unimrcp_app_options
            super do |opts|
              opts[:vn] = output_node.voice if output_node.voice
            end
          end
        end
      end
    end
  end
end
