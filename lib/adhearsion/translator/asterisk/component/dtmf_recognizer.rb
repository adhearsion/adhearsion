# encoding: utf-8

require 'ruby_speech'
require 'concurrent/map'
require 'adhearsion/translator/asterisk/component'

module Adhearsion
  module Translator
    class Asterisk
      module Component
        class DTMFRecognizer
          class BuiltinMatcherCache
            @@cache = Concurrent::Map.new

            class << self
              def get(uri)
                @@cache[uri] || cache(uri)
              end

              def clear!
                @@cache.clear
              end

              private

              def cache(uri)
                grammar = RubySpeech::GRXML.from_uri(uri)
                matcher = RubySpeech::GRXML::Matcher.new(grammar)
                # put_if_absent returns existing value or nil if key wasn't stored (matcher got set as the value)
                @@cache.put_if_absent(uri, matcher) || matcher
              end
            end
          end

          include Celluloid

          def initialize(responder, grammar, initial_timeout = nil, inter_digit_timeout = nil, terminator = nil)
            @responder = responder
            self.initial_timeout = initial_timeout || -1
            self.inter_digit_timeout = inter_digit_timeout || -1
            @terminator = terminator
            @finished = false

            @matcher = if grammar.url
              BuiltinMatcherCache.get(grammar.url)
            else
              RubySpeech::GRXML::Matcher.new RubySpeech::GRXML.import(grammar.value.to_s)
            end
            @buffer = ""
          end

          def <<(digit)
            cancel_initial_timer
            @buffer << digit unless terminating?(digit)
            case (match = get_match)
            when RubySpeech::GRXML::NoMatch
              finalize :nomatch
            when RubySpeech::GRXML::MaxMatch
              finalize :match, match
            when RubySpeech::GRXML::Match
              finalize :match, match if terminating?(digit)
            when RubySpeech::GRXML::PotentialMatch
              finalize :nomatch if terminating?(digit)
            end
            reset_inter_digit_timer unless @finished
          end

          def start_timers
            begin_initial_timer @initial_timeout/1000 unless @initial_timeout == -1
          end

          private

          def terminating?(digit)
            digit == @terminator
          end

          def get_match
            @matcher.match @buffer.dup
          end

          def initial_timeout=(other)
            raise OptionError, 'An initial timeout value that is negative (and not -1) is invalid.' if other < -1
            @initial_timeout = other
          end

          def inter_digit_timeout=(other)
            raise OptionError, 'An inter-digit timeout value that is negative (and not -1) is invalid.' if other < -1
            @inter_digit_timeout = other
          end

          def begin_initial_timer(timeout)
            @initial_timer = after timeout do
              finalize :noinput
            end
          end

          def cancel_initial_timer
            return unless instance_variable_defined?(:@initial_timer) && @initial_timer
            @initial_timer.cancel
            @initial_timer = nil
          end

          def reset_inter_digit_timer
            return if @inter_digit_timeout == -1
            @inter_digit_timer ||= begin
              after @inter_digit_timeout/1000 do
                case (match = get_match)
                when RubySpeech::GRXML::Match
                  finalize :match, match
                else
                  finalize :nomatch
                end
              end
            end
            @inter_digit_timer.reset
          end

          def cancel_inter_digit_timer
            return unless instance_variable_defined?(:@inter_digit_timer) && @inter_digit_timer
            @inter_digit_timer.cancel
            @inter_digit_timer = nil
          end

          def finalize(match_type, match = nil)
            cancel_initial_timer
            cancel_inter_digit_timer
            if match
              @responder.send match_type, match
            else
              @responder.send match_type
            end
            @finished = true
            terminate
          end
        end
      end
    end
  end
end
