# encoding: utf-8

module Adhearsion
  class Plugin
    class Initializer
      attr_reader :name, :block

      def initialize(name, context, options, &block)
        options[:group] ||= :default
        @name, @context, @options, @block = name, context, options, block
      end

      def before
        @options[:before]
      end

      def after
        @options[:after]
      end

      def belongs_to?(group)
        @options[:group] == group || @options[:group] == :all
      end

      def run(*args)
        @context.instance_exec(*args, &block)
      end

      def bind(context)
        return self if @context
        Initializer.new @name, context, @options, &block
      end

      def to_s
        "#{self.name}: #{@options}"
      end
    end
  end
end
