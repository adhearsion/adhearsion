require 'adhearsion/foundation/metaprogramming'
require 'adhearsion/conveniences'
require 'adhearsion/constants'
require 'adhearsion/dsl/dialing_dsl/dialing_dsl_monkey_patches'

module Adhearsion
  module DSL
    class DialingDSL

      extend  Conveniences
      include Constants

      Regexp.class_eval do
        include Adhearsion::DSL::DialingDSL::MonkeyPatches::RegexpMonkeyPatch
      end

      def self.inherited(klass)
        klass.class_eval do
          [:@@providers, :@@routes].each do |var|
            class_variable_set(var, [])
            cattr_reader var.to_s.gsub('@@', '')
          end
        end
      end

      def self.calculate_routes_for(destination)
        destination = destination.to_s
        routes.select { |defined_route| defined_route === destination }.map &:providers
      end

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

      protected

      def self.provider(name, &block)
        raise ArgumentError, "no block given" unless block_given?

        options = ProviderDefinition.new name
        yield options

        providers << options
        meta_def(name) { options }
      end

      def self.route(route)
        routes << route
      end

      class RouteRule

        attr_reader :patterns, :providers

        def initialize(hash={})
          @patterns  = Array hash[:patterns]
          @providers = Array hash[:providers]
        end

        def merge!(other)
          providers.concat other.providers
          patterns.concat  other.patterns
          self
        end

        def >>(other)
          case other
            when RouteRule then merge! other
            when ProviderDefinition then providers << other
            else raise RouteException, "Unrecognized object in route definition: #{other.inspect}"
          end
          self
        end

        def |(other)
          case other
            when RouteRule then merge! other
            when Regexp
              patterns << other
              self
            else raise other.inspect
          end
        end

        def ===(other)
          patterns.each { |pattern| return true if pattern === other }
          false
        end

        def unshift_pattern(pattern)
          patterns.unshift pattern
        end

        class RouteException < StandardError; end

      end
    end
  end
end
