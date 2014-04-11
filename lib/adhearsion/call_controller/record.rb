# encoding: utf-8

module Adhearsion
  class CallController
    module Record
      RecordError = Class.new StandardError # Represents failure to record such as when a file cannot be written.

      #
      # Handle a recording
      #
      class Recorder
        attr_accessor :record_component, :stopper_component

        #
        # @param [Adhearsion::CallController] controller on which to execute the recording
        # @param [Hash] options
        # @option options [Boolean, Optional] :async Execute asynchronously. Defaults to false
        # @option options [Boolean, Optional] :start_beep Indicates whether subsequent record will be preceded with a beep. Default is false.
        # @option options [Boolean, Optional] :start_paused Whether subsequent record will start in PAUSE mode. Default is false.
        # @option options [String, Optional] :max_duration Indicates the maximum duration (seconds) for a recording.
        # @option options [String, Optional] :format File format used during recording.
        # @option options [String, Optional] :initial_timeout Controls how long (seconds) the recognizer should wait after the end of the prompt for the caller to speak before sending a Recorder event.
        # @option options [String, Optional] :final_timeout Controls the length (seconds) of a period of silence after callers have spoken to conclude they finished.
        # @option options [Boolean, Optional] :interruptible Allows the recording to be terminated by any single DTMF key, default is false
        #
        def initialize(controller, options = {})
          @controller = controller

          options = prep_options options

          @async = options.delete :async

          interruptible = options.delete :interruptible
          @stopper_component  = interruptible ? setup_stopper(interruptible) : nil
          @record_component   = Punchblock::Component::Record.new options
        end

        #
        # Execute the recorder
        #
        # @return nil
        #
        def run
          execute_stopper
          execute_recording
          terminate_stopper
          nil
        end

        #
        # Set a callback to be executed when recording completes
        #
        # @yield [Punchblock::Event::Complete] the complete Event for the recording
        #
        def handle_record_completion(&block)
          @record_component.register_event_handler Punchblock::Event::Complete, &block
        end

        private

        def setup_stopper(interrupt_digits)
          interrupt_digits = interrupt_digits == true ? '0123456789#*' : interrupt_digits.to_s
          @stopper_component = Punchblock::Component::Input.new :mode => :dtmf,
            :grammar => {
              :value => @controller.grammar_accept(interrupt_digits)
            }
          @stopper_component.register_event_handler Punchblock::Event::Complete do |event|
            @record_component.stop! unless @record_component.complete?
          end
          @stopper_component
        end

        def execute_stopper
          @controller.write_and_await_response @stopper_component if @stopper_component
        end

        def execute_recording
          if @async
            @controller.write_and_await_response @record_component
          else
            @controller.execute_component_and_await_completion @record_component
          end
        end

        def terminate_stopper
          @stopper_component.stop! if @stopper_component && !@stopper_component.complete?
        end

        def prep_options(opts)
          opts.dup.tap do |options|
            [:max_duration, :initial_timeout, :final_timeout].each do |k|
              options[k] = options[k] * 1000 if options[k]
            end
          end
        end
      end

      #
      # Start a recording
      #
      # @example Record in a blocking way and use result
      #   record_result = record :start_beep => true, :max_duration => 60
      #   logger.info "Recording saved to #{record_result.complete_event.recording.uri}"
      # @example Asynchronous recording, execution of the controller will continue
      #   record :async => true do |event|
      #     logger.info "Async recording saved to #{event.recording.uri}"
      #   end
      #
      # @param [Hash] options
      # @option options [Boolean, Optional] :async Execute asynchronously. Defaults to false
      # @option options [Boolean, Optional] :start_beep Indicates whether subsequent record will be preceded with a beep. Default is false.
      # @option options [Boolean, Optional] :start_paused Whether subsequent record will start in PAUSE mode. Default is false.
      # @option options [String, Optional] :max_duration Indicates the maximum duration (seconds) for a recording.
      # @option options [String, Optional] :format File format used during recording.
      # @option options [String, Optional] :initial_timeout Controls how long (seconds) the recognizer should wait after the end of the prompt for the caller to speak before sending a Recorder event.
      # @option options [String, Optional] :final_timeout Controls the length (seconds) of a period of silence after callers have spoken to conclude they finished.
      # @option options [Boolean, String, Optional] :interruptible Allows the recording to be terminated by any single DTMF key, default is false
      #
      # @yield [event] Handle the recording completion event asyncronously.
      # @yieldparam [Punchblock::Event::Complete] event the complete event for the recording
      #
      # @return Punchblock::Component::Record
      #
      def record(options = {})
        recorder = Recorder.new self, options

        recorder.handle_record_completion do |event|
          catching_standard_errors { yield event if block_given? }
        end

        recorder.run
        recorder.record_component
      end
    end
  end
end
