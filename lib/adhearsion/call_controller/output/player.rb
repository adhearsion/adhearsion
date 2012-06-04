# encoding: utf-8

module Adhearsion
  class CallController
    module Output
      class Player < AbstractPlayer

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
