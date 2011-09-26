module Adhearsion
  module Punchblock
    module Commands
      module Input
        # Utility method for DTMF GRXML grammars
        #
        # @param [Integer] Number of digits to accept in the grammar.
        # @return [RubySpeech::GRXML::Grammar] A grammar suitable for use in SSML prompts.
        def grammar_digits(digits = 1)
          grammar = RubySpeech::GRXML.draw do
            self.mode = 'dtmf'
            self.root = 'inputdigits'
            rule id: 'digits' do
              one_of do
                0.upto(9) {|d| item { d.to_s } }
              end
            end

            rule id: 'inputdigits', scope: 'public' do
              item repeat: digits.to_s do
                ruleref uri: '#digits'
              end
            end
          end
        end#grammar_digits
      end
    end
  end
end
