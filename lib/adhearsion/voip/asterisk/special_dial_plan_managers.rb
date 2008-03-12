module Adhearsion
  class DialPlan
    class ConfirmationManager
      
      class << self
          
        def encode_hash_for_dial_macro_argument(options)
          options = options.clone
          macro_name = options.delete :macro
          encoded_options = URI.escape options.map { |key,value| "#{key}:#{value}" }.join('!')
          returning "M(#{macro_name}^#{encoded_options})" do |str|
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
          unencoded = URI.unescape(encoded_hash)[/^([^!]+)?!(.+)$/,2]
          returning Hash[*unencoded.split('!').map { |pair| pair.split(':') }.map { |(key,value)| [key.to_sym, value]}.flatten] do |hash|
            hash[:timeout]    &&= hash[:timeout].to_i
            hash[:play]       &&= hash[:play].split('++')
            hash[:fails_with] &&= hash[:fails_with].to_sym
          end
        end

      end
      
      attr_reader :call
      def initialize(call)
        @call = call
        extend Adhearsion::VoIP::Commands.for(call.originating_voip_platform)
      end
      
      def handle
        puts 'WORKS I THINK'
        answer
        play 'hello-world'
      end
      
    end
  end
end