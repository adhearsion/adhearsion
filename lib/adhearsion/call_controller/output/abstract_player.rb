# encoding: utf-8

require 'ruby_speech'

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
            output [{ value: ssml }], options
          end
        end

        def play_ssml_collection(collection, options = {})
          output collection.map { |doc| { value: doc } }, options
        end

        def new_output(options)
          defaults = {}

          default_voice = Adhearsion.config.platform.media.default_voice || Adhearsion.config.punchblock[:default_voice]
          defaults[:voice] = default_voice if default_voice

          renderer = Adhearsion.config.platform.media.default_renderer || Adhearsion.config.punchblock[:media_engine]
          defaults[:renderer] = renderer if renderer

          Punchblock::Component::Output.new defaults.merge(options)
        end
      end
    end
  end
end
