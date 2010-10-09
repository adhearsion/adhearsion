module Adhearsion
  module VoIP
    module DSL
      class DialingDSL
        module MonkeyPatches
          module RegexpMonkeyPatch

            def |(other)
              case other
                when RouteRule
                  other.unshift_pattern self
                  other
                when Regexp
                  RouteRule.new :patterns => [self, other]
                else
                  raise ArgumentError, "Unsupported pattern type #{other.inspect}"
              end
            end

            def >>(other)
              case other
                when ProviderDefinition
                  RouteRule.new :patterns => self, :providers => other
                when RouteRule
                  other.tap do |route|
                    route.unshift_pattern self
                  end
                else raise ArgumentError, "Unsupported route definition #{other.inspect}"
              end
            end

          end
        end
      end
    end
  end
end