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

        def play_ssml_for(*args)
          play_ssml Formatter.ssml_for(args)
        end
      end
    end
  end
end
