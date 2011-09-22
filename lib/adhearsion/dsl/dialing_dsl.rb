module Adhearsion
  module DSL
    class DialingDSL

      extend ActiveSupport::Autoload

      autoload :MonkeyPatches
      autoload :ProviderDefinition
      autoload :RouteRule

      extend  Conveniences
      include Constants

      Regexp.class_eval do
        include MonkeyPatches::RegexpMonkeyPatch
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
    end
  end
end
