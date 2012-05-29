# encoding: utf-8

module Adhearsion
  class CallController
    module Output
      class Player

        attr_accessor :controller

        def initialize(controller)
          @controller = controller
        end

        #
        # Plays a single output, not only files, accepting interruption by one of the digits specified
        # Currently still stops execution, will be fixed soon in Punchblock
        #
        # @param [Object] String or Hash specifying output and options
        # @param [String] String with the digits that are allowed to interrupt output
        #
        # @return [String, nil] The pressed digit, or nil if nothing was pressed
        #
        def stream_file(argument, digits = '0123456789#*')
          result = nil
          stopper = Punchblock::Component::Input.new :mode => :dtmf,
            :grammar => {
              :value => controller.grammar_accept(digits)
            }

          output Formatter.ssml_for(argument) do |output_component|
            stopper.register_event_handler Punchblock::Event::Complete do |event|
              output_component.stop! unless output_component.complete?
            end
            controller.write_and_await_response stopper
          end

          stopper.stop! if stopper.executing?
          reason = stopper.complete_event.reason
          result = reason.interpretation if reason.respond_to? :interpretation
          return controller.parse_single_dtmf result unless result.nil?
          result
        end

        def play_ssml(ssml, options = {})
          if [RubySpeech::SSML::Speak, Nokogiri::XML::Document].include? ssml.class
            output ssml, options
          end
        end

        #
        # @yields The output component before executing it
        # @raises [PlaybackError] if (one of) the given argument(s) could not be played
        #
        def output(content, options = {})
          options.merge! :ssml => content.to_s
          component = Punchblock::Component::Output.new options
          yield component if block_given?
          controller.execute_component_and_await_completion component
        rescue Adhearsion::Error, Punchblock::ProtocolError => e
          raise PlaybackError, "Output failed due to #{e.inspect}"
        end

        #
        # @yields The output component before executing it
        # @raises [PlaybackError] if (one of) the given argument(s) could not be played
        #
        def output_async(content, options = {})
          options.merge! :ssml => content.to_s
          component = Punchblock::Component::Output.new options
          controller.write_and_await_response component
          component
        rescue Punchblock::ProtocolError => e
          raise PlaybackError, "Async output failed due to #{e.inspect}"
        end

        def play_ssml_for(*args)
          play_ssml Formatter.ssml_for(args)
        end
      end
    end
  end
end
