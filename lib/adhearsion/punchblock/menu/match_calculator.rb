module Adhearsion
  module Punchblock
    module Menu

      class MatchCalculator

        class << self
          def build_with_pattern(pattern, match_payload, &block)
            class_for_pattern_type(pattern.class.name).new(pattern, match_payload, &block)
          end

          def inherited(klass)
            subclasses << klass
          end

          private

          def class_for_pattern_type(pattern_type)
            sought_class_name = "Adhearsion::Punchblock::Menu::#{pattern_type.camelize}MatchCalculator"
            subclasses.find { |klass| klass.name == sought_class_name }
          end

          def subclasses
            @@subclasses ||= []
          end
        end

        attr_reader :pattern, :match_payload

        def initialize(pattern, match_payload)
          @pattern, @match_payload = pattern, match_payload
        end

        protected

        def new_calculated_match(options)
          CalculatedMatch.new({:pattern => pattern, :match_payload => match_payload}.merge(options))
        end

        def coerce_to_numeric(victim)
          victim.kind_of?(Numeric) ? victim : (victim.to_s =~ /^\d+$/ ? victim.to_s.to_i : nil )
        end

      end # class MatchCalculator

    end
  end
end
