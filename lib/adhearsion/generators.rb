# encoding: utf-8

module Adhearsion
  module Generators
    extend ActiveSupport::Autoload

    autoload :Generator

    class << self

      # Show help message with available generators.
      def help(command = 'generate')
        "".tap do |h|
          h << "Available generators:\n"

          mappings.each_pair do |name, klass|
            h << "* " << klass.desc << "\n"
          end
        end
      end

      def invoke(generator_name, args = ARGV)
        klass = Generators.mappings[generator_name.to_sym]
        raise UnknownGeneratorError, generator_name unless klass

        args << "--help" if args.empty? && klass.arguments.any?(&:required?)

        klass.start args
      end

      ##
      # Return a ordered list of task with their class
      #
      def mappings
        @_mappings ||= Hash.new
      end

      ##
      # Globally add a new generator class to +ahn generate+
      #
      # @param [Symbol] name
      # key name for generator mapping
      # @param [Class] klass
      # class of generator
      #
      # @return [Hash] generator mappings
      #
      # @example
      # Adhearsion::Generators.add_generator :myplugin, MyPluginGenerator
      #
      def add_generator(name, klass)
        mappings[name] = klass
      end

    end#class << self
  end#module
end#module
