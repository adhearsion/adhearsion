# encoding: utf-8

module Adhearsion
  class CallController
    module Output
      class AsyncPlayer < AbstractPlayer

        #
        # @yield The output component before executing it
        # @raise [PlaybackError] if (one of) the given argument(s) could not be played
        #
        def output(content, options = {})
          options.merge! :ssml => content
          component = new_output options
          component.register_event_handler Adhearsion::Event::Complete do |event|
            controller.logger.error event if event.reason.is_a?(Adhearsion::Event::Complete::Error)
            throw :pass
          end
          controller.write_and_await_response component
          component
        rescue Adhearsion::ProtocolError => e
          raise PlaybackError, "Async output failed due to #{e.inspect}"
        end
      end
    end
  end
end
