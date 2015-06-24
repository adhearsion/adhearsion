# encoding: utf-8

require 'adhearsion/call_controller/input/prompt_builder'

module Adhearsion
  class CallController
    module Input
      class MenuBuilder
        def initialize(options, &block)
          @options = options
          @matchers = []
          @callbacks = {}
          build(&block)
        end

        def match(*args, &block)
          payload = block || args.pop

          @matchers << Matcher.new(payload, args)
        end

        def invalid(&block)
          register_user_supplied_callback :nomatch, &block
        end

        def timeout(&block)
          register_user_supplied_callback :noinput, &block
        end

        def failure(&block)
          register_user_supplied_callback :failure, &block
        end

        def execute(output_document, controller)
          catch :match do
            (@options[:tries] || 1).times do
              result = PromptBuilder.new(output_document, grammars, @options).execute(controller)
              process_result result
            end
            execute_hook :failure
          end
        end

      private

        def grammars
          @grammar ||= [{value: build_grammar}]
        end

        def process_result(result)
          if result.status == :match
            handle_match result
          else
            execute_hook result.status
          end
        end

        def register_user_supplied_callback(name, &block)
          @callbacks[name] = block
        end

        def execute_hook(hook_name)
          callback = @callbacks[hook_name]
          return unless callback
          @context.instance_exec(&callback)
        end

        def handle_match(result)
          match = @matchers[result.interpretation.to_i]
          match.dispatch @context, result.utterance
          throw :match
        end

        def build(&block)
          @context = eval "self", block.binding
          instance_eval(&block)
        end

        def method_missing(method_name, *args, &block)
          if @context
            @context.send method_name, *args, &block
          else
            super
          end
        end

        def build_grammar
          raise ArgumentError, "You must specify one or more matches." if @matchers.count < 1
          matchers = @matchers

          RubySpeech::GRXML.draw mode: (@options[:mode] || :dtmf), root: 'options', tag_format: 'semantics/1.0-literals' do
            rule id: 'options', scope: 'public' do
              item do
                one_of do
                  matchers.each_with_index do |matcher, index|
                    item do
                      tag { index.to_s }
                      matcher.apply_to_grammar self
                    end
                  end
                end
              end
            end
          end
        end

        Matcher = Struct.new(:payload, :keys) do
          def dispatch(controller, utterance)
            if payload.is_a?(Proc)
              controller.instance_exec utterance, &payload
            else
              controller.invoke payload, extension: utterance
            end
          end

          def apply_to_grammar(grammar)
            possible_options = calculate_possible_options
            if possible_options.count > 1
              grammar.one_of do
                possible_options.each do |key|
                  item { key.to_s }
                end
              end
            else
              keys.first.to_s
            end
          end

          def calculate_possible_options
            keys.map { |key| key.respond_to?(:to_a) ? key.to_a : key }.flatten
          end
        end
      end
    end
  end
end
