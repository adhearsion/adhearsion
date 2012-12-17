# encoding: utf-8

module Adhearsion
  class CallController
    module Output
      class AbstractPlayer

        attr_accessor :controller

        def initialize(controller)
          @controller = controller
        end

        def play_ssml(ssml, options = {})
          if [RubySpeech::SSML::Speak, Nokogiri::XML::Document].include? ssml.class
            output ssml, options
          end
        end

        def new_output(options)
          defaults = {}
          default_voice = Adhearsion.config.punchblock[:default_voice]
          defaults[:voice] = default_voice if default_voice

          Punchblock::Component::Output.new defaults.merge(options)
        end
      end
    end
  end
end
