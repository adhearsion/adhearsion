# encoding: utf-8

module Adhearsion
  class CallController
    module Output
      class Player < AbstractPlayer

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

        #
        # @yields The output component before executing it
        # @raises [PlaybackError] if (one of) the given argument(s) could not be played
        #
        def output(content, options = {})
          options.merge! :ssml => content.to_s
          component = new_output options
          yield component if block_given?
          controller.execute_component_and_await_completion component
        rescue Adhearsion::Error, Punchblock::ProtocolError => e
          raise PlaybackError, "Output failed due to #{e.inspect}"
        end
      end
    end
  end
end
