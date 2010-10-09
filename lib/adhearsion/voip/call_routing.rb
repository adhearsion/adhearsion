module Adhearsion
  module VoIP
    module CallRouting
      class Rule
        attr_reader :patterns, :providers, :options

        def initialize(*args, &block)
          @options   = args.pop
          @patterns  = Array(args)
          @providers = Array(options[:to])
        end
      end

      class RuleSet < Array
        def [](index)
          case index
          when String
            detect do |rule|
              rule.patterns.any? do |pattern|
                index =~ pattern
              end
            end
          else
            super
          end
        end
      end

      class Router
        class << self
          attr_accessor :rules

          def define(&block)
            new.tap do |router|
              router.define(&block)
              rules.concat router.rules
            end
          end

          def calculate_route_for(end_point)
            if rule = rules[end_point.to_s]
              rule.providers
            end
          end
        end

        self.rules ||= RuleSet.new

        attr_reader :rules
        def initialize
          @rules = []
        end

        def define(&block)
          instance_eval(&block)
        end

        def route(*args, &block)
          rules << Rule.new(*args, &block)
        end
      end
    end
  end
end