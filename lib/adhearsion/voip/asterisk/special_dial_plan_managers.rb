module Adhearsion
  class DialPlan
    class ConfirmationManager

      class << self

        def encode_hash_for_dial_macro_argument(options)
          options    = options.clone
          macro_name = options.delete :macro
          options[:play] &&= options[:play].kind_of?(Array) ? options[:play].join('++') : options[:play]
          encoded_options = URI.escape options.map { |key,value| "#{key}:#{value}" }.join('!')
          "M(#{macro_name}^#{encoded_options})".tap do |str|
            if str.rindex('^') != str.index('^')
              raise ArgumentError, "You seem to have supplied a :confirm option with a caret (^) in it!" +
                                   " Please remove it. This will blow Asterisk up."
            end
          end
        end

        def handle(call)
          new(call).handle
        end

        def confirmation_call?(call)
          call.variables.has_key?(:network_script) && call.variables[:network_script].starts_with?('confirm!')
        end

        def decode_hash(encoded_hash)
          encoded_hash = encoded_hash =~ /^M\((.+)\)$/ ? $1 : encoded_hash
          encoded_hash = encoded_hash =~ /^([^:]+\^)?(.+)$/ ? $2 : encoded_hash # Remove the macro name if it's there
          unencoded = URI.unescape(encoded_hash).split('!')
          unencoded.shift unless unencoded.first.include?(':')
          unencoded = unencoded.map { |pair| key, value = pair.split(':'); [key.to_sym ,value] }.flatten
          Hash[*unencoded].tap do |hash|
            hash[:timeout]    &&= hash[:timeout].to_i
            hash[:play]       &&= hash[:play].split('++')
          end
        end

      end

      attr_reader :call
      def initialize(call)
        @call = call
        extend Adhearsion::VoIP::Commands.for(call.originating_voip_platform)
      end

      def handle
        variables = self.class.decode_hash call.variables[:network_script]

        answer
        loop do
          response = interruptible_play(*variables[:play])
          if response && response.to_s == variables[:key].to_s
            # Don't set a variable to pass through to dial()
            break
          elsif response && response.to_s != variables[:key].to_s
            next
          else
            response = wait_for_digit variables[:timeout]
            if response
              if response.to_s == variables[:key].to_s
                # Don't set a variable to pass through to dial()
                break
              else
                next
              end
            else
              # By setting MACRO_RESULT to CONTINUE, we cancel the dial.
              variable 'MACRO_RESULT' => "CONTINUE"
              break
            end
          end
        end

      end

    end
  end
end