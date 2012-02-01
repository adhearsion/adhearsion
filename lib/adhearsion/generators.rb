module Adhearsion
  module Generators
    extend ActiveSupport::Autoload

    autoload :Generator

    class << self
      ##
      # Return a ordered list of task with their class
      #
      def mappings
        @_mappings ||= ActiveSupport::OrderedHash.new
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
      # Adhearsion::Generators.add_generator(:myplugin, MyPlugin)
      #
      def add_generator(name, klass)
        mappings[name] = klass
      end


      
    end#class << self
  end#module
end#module
