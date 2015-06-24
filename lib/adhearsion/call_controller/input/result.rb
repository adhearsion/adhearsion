# encoding: utf-8

module Adhearsion
  class CallController
    module Input
      Result = Struct.new(:status, :mode, :confidence, :utterance, :interpretation, :nlsml) do
        def to_s
          utterance
        end

        def inspect
          "#<#{self.class} status=#{status.inspect}, confidence=#{confidence.inspect}, utterance=#{utterance.inspect}, interpretation=#{interpretation.inspect}, nlsml=#{nlsml.inspect}>"
        end

        def utterance=(other)
          self[:utterance] = mode == :dtmf ? parse_dtmf(other) : other
        end

        def match?
          status == :match
        end

      private

        def parse_dtmf(dtmf)
          return if dtmf.nil? || dtmf.empty?
          dtmf.split(' ').inject '' do |final, digit|
            final << parse_dtmf_digit(digit)
          end
        end

        # @private
        def parse_dtmf_digit(digit)
          case tone = digit.split('-').last
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
  end
end
