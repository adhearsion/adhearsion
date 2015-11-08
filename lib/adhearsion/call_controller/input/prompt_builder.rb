# encoding: utf-8

require 'adhearsion/call_controller/input/result'

module Adhearsion
  class CallController
    module Input
      class PromptBuilder
        def initialize(output_document, grammars, options)
          input_options = {
            mode: options[:mode] || :dtmf,
            initial_timeout: timeout(options[:timeout] || Adhearsion.config.core.media.timeout),
            inter_digit_timeout: timeout(options[:inter_digit_timeout] || Adhearsion.config.core.media.inter_digit_timeout),
            max_silence: timeout(options[:timeout] || Adhearsion.config.core.media.timeout),
            min_confidence: Adhearsion.config.core.media.min_confidence,
            grammars: grammars,
            recognizer: Adhearsion.config.core.media.recognizer,
            language: Adhearsion.config.core.media.input_language,
            terminator: options[:terminator]
          }.merge(options[:input_options] || {})

          @prompt = if output_document || options[:render_document]
            output_options = {
              render_document: options[:render_document] || {value: output_document},
              renderer: Adhearsion.config.core.media.default_renderer,
              voice: Adhearsion.config.core.media.default_voice
            }.merge(options[:output_options] || {})

            Adhearsion::Rayo::Component::Prompt.new output_options, input_options, barge_in: options.has_key?(:interruptible) ? options[:interruptible] : true
          else
            Adhearsion::Rayo::Component::Input.new input_options
          end
        end

        def execute(controller)
          controller.execute_component_and_await_completion @prompt

          result @prompt.complete_event.reason
        rescue Adhearsion::Call::ExpiredError
          raise Adhearsion::Call::Hangup
        end

      private

        def result(reason)
          Result.new.tap do |result|
            case reason
            when proc { |r| r.respond_to? :nlsml }
              result.status         = :match
              result.mode           = reason.mode
              result.confidence     = reason.confidence
              result.utterance      = reason.utterance
              result.interpretation = reason.interpretation
              result.nlsml          = reason.nlsml
            when Adhearsion::Event::Complete::Error
              raise InputError, reason.details
            when Adhearsion::Rayo::Component::Input::Complete::NoMatch
              result.status = :nomatch
            when Adhearsion::Rayo::Component::Input::Complete::NoInput
              result.status = :noinput
            when Adhearsion::Event::Complete::Hangup
              result.status = :hangup
            when Adhearsion::Event::Complete::Stop
              result.status = :stop
            else
              raise "Unknown completion reason received: #{reason}"
            end
            logger.debug { "Ask completed with result #{result.inspect}" }
          end
        end

        def timeout(value)
          value > 0 ? value * 1000 : value
        end
      end
    end
  end
end
