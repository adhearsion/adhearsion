# encoding: utf-8

module Adhearsion
  class CallController
    module Input
      class AskGrammarBuilder
        def initialize(options)
          @options = options
        end

        def grammars
          @grammars ||= build_grammars
        end

      private

        def build_grammars
          grammars = []

          grammars.concat [@options[:grammar]].flatten.compact.map { |val| {value: val} } if @options[:grammar]
          grammars.concat [@options[:grammar_url]].flatten.compact.map { |val| {url: val} } if @options[:grammar_url]

          if grammars.empty?
            limit = @options[:limit]
            grammar = RubySpeech::GRXML.draw mode: :dtmf, root: 'digits' do
              rule id: 'digits', scope: 'public' do
                item repeat: "0-#{limit}" do
                  one_of do
                    0.upto(9) { |d| item { d.to_s } }
                    item { "#" }
                    item { "*" }
                  end
                end
              end
            end
            grammars << {value: grammar}
          end

          grammars
        end
      end
    end
  end
end
