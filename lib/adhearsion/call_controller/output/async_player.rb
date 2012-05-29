# encoding: utf-8

module Adhearsion
  class CallController
    module Output
      class AsyncPlayer < AbstractPlayer

        #
        # @yields The output component before executing it
        # @raises [PlaybackError] if (one of) the given argument(s) could not be played
        #
        def output(content, options = {})
          options.merge! :ssml => content.to_s
          component = Punchblock::Component::Output.new options
          controller.write_and_await_response component
          component
        rescue Punchblock::ProtocolError => e
          raise PlaybackError, "Async output failed due to #{e.inspect}"
        end
      end
    end
  end
end
