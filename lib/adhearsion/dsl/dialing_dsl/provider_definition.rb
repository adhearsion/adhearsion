module Adhearsion
  module DSL
    class DialingDSL
      class ProviderDefinition < OpenStruct

        def initialize(name)
          super()
          self.name = name.to_s.to_sym
        end

        def >>(other)
          RouteRule.new :providers => [self, other]
        end

        def format_number_for_platform(number, platform=:asterisk)
          case platform
            when :asterisk
              [protocol || "SIP", name || "default", number].join '/'
            else
              raise "Unsupported platform #{platform}!"
          end
        end

        def format_number_for_platform(number, platform=:asterisk)
          case platform
            when :asterisk
              [protocol || "SIP", name || "default", number].join '/'
            else
              raise "Unsupported platform #{platform}!"
          end
        end

        def defined_properties_without_name
          @table.clone.tap do |copy|
            copy.delete :name
          end
        end

      end
    end
  end
end
