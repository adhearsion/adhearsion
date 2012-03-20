# encoding: utf-8

module Adhearsion
  class CallController
    module Utility

      # Utility method for DTMF GRXML grammars
      #
      # @param [Integer] Number of digits to accept in the grammar.
      # @return [RubySpeech::GRXML::Grammar] A grammar suitable for use in SSML prompts
      #
      def grammar_digits(digits = 1) # :nodoc:
        RubySpeech::GRXML.draw :mode => 'dtmf', :root => 'inputdigits' do
          rule id: 'inputdigits', scope: 'public' do
            item repeat: digits.to_s do
              one_of do
                0.upto(9) { |d| item { d.to_s } }
              end
            end
          end
        end
      end # grammar_digits

      # Utility method to create a single-digit grammar to accept only some digits
      #
      # @param [String] String representing the digits to accept
      # @return [RubySpeech::GRXML::Grammar] A grammar suitable for use in SSML prompts
      #
      def grammar_accept(digits = '0123456789#*') # :nodoc:
        allowed_digits = '0123456789#*'
        gram_digits = digits.chars.select { |x| allowed_digits.include? x }

        RubySpeech::GRXML.draw :mode => 'dtmf', :root => 'inputdigits' do
          rule id: 'inputdigits', scope: 'public' do
            one_of do
              gram_digits.each { |d| item { d.to_s } }
            end
          end
        end
      end

      #
      # Parses a single DTMF tone in the format dtmf-*
      #
      # @param [String] the tone string to be parsed
      # @return [String] the digit in case input was 0-9, * or # if star or pound respectively
      #
      def parse_single_dtmf(result) # :nodoc:
        return if result.nil?
        case tone = result.split('-')[1]
        when 'star'
          '*'
        when 'pound'
          '#'
        else
          tone
        end
      end

    end#module
  end
end
