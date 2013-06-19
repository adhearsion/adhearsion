# encoding: utf-8

module Adhearsion
  class CallController
    module Output
      class Player < AbstractPlayer

        #
        # @yields The output component before executing it
        # @raises [PlaybackError] if (one of) the given argument(s) could not be played
        #
        def output(content, options = {}, &block)
          options.merge! :ssml => content
          component = new_output options
          if block
            controller.execute_component_and_await_completion component, &block
          else
            controller.execute_component_and_await_completion component
          end
        rescue Call::Hangup
          raise
        rescue Adhearsion::Error, Punchblock::ProtocolError => e
          raise PlaybackError, "Output failed due to #{e.inspect}"
        end
      end
    end
  end
end
