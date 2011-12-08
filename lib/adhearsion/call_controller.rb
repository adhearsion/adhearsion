module Adhearsion
  class CallController
    extend ActiveSupport::Autoload

    autoload :Conference
    autoload :Dial
    autoload :Input
    autoload :Output
    autoload :Record

    include Punchblock::Command
    include Punchblock::Component
    include Conference
    include Dial
    include Input
    include Output
    include Record

    attr_reader :call

    def initialize(call)
      @call = call
    end

    def accept(headers = nil)
      call.accept headers
    end

    def answer(headers = nil)
      call.answer headers
    end

    def reject(reason = :busy, headers = nil)
      call.reject reason, headers
    end

    def hangup(headers = nil)
      call.hangup! headers
    end

    def mute
      write_and_await_response ::Punchblock::Command::Mute.new
    end

    def unmute
      write_and_await_response ::Punchblock::Command::Unmute.new
    end

    def write_and_await_response(command, timeout = nil)
      call.write_and_await_response command, timeout
    end
    alias :execute_component :write_and_await_response

    def execute_component_and_await_completion(component)
      write_and_await_response component

      yield component if block_given?

      complete_event = component.complete_event
      raise StandardError, complete_event.reason.details if complete_event.reason.is_a? Punchblock::Event::Complete::Error
      component
    end

    #
    # Utility method for DTMF GRXML grammars
    #
    # @param [Integer] Number of digits to accept in the grammar.
    # @return [RubySpeech::GRXML::Grammar] A grammar suitable for use in SSML prompts
    #
    def grammar_digits(digits = 1)
      grammar = RubySpeech::GRXML.draw do
        self.mode = 'dtmf'
        self.root = 'inputdigits'
        rule id: 'digits' do
          one_of do
            0.upto(9) { |d| item { d.to_s } }
          end
        end

        rule id: 'inputdigits', scope: 'public' do
          item repeat: digits.to_s do
            ruleref uri: '#digits'
          end
        end
      end
    end # grammar_digits

    #
    # Utility method to create a single-digit grammar to accept only some digits
    #
    # @param [String] String representing the digits to accept
    # @return [RubySpeech::GRXML::Grammar] A grammar suitable for use in SSML prompts
    #
    def grammar_accept(digits = '0123456789#*')
      allowed_digits = '0123456789#*'
      gram_digits = digits.chars.select { |x| allowed_digits.include? x }

      grammar = RubySpeech::GRXML.draw do
        self.mode = 'dtmf'
        self.root = 'inputdigits'
        rule id: 'acceptdigits' do
          one_of do
            gram_digits.each { |d| item { d.to_s } }
          end
        end

        rule id: 'inputdigits', scope: 'public' do
          item repeat: '1' do
            ruleref uri: '#acceptdigits'
          end
        end
      end
      grammar
    end

    #
    # Parses a single DTMF tone in the format dtmf-*
    #
    # @param [String] the tone string to be parsed
    # @return [String] the digit in case input was 0-9, * or # if star or pound respectively
    #
    def parse_single_dtmf(result)
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
  end
end
