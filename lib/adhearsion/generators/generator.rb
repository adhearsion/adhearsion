# encoding: utf-8

begin
  require 'thor/group'
rescue LoadError
  puts "Thor is not available.\nIf you ran this command from a git checkout " \
       "of Adhearsion, please make sure thor is installed,\nand run this command " \
       "as `ruby #{$0} #{(ARGV | ['--dev']).join(" ")}`"
  exit
end

module Adhearsion
  module Generators

    class Generator < Thor::Group
      include Thor::Actions

      argument :generate_command, :type => :string
      argument :generator_name, :type => :string

      # Returns the source root for this generator using default_source_root as default.
      def self.source_root(path = nil)
        @_source_root = path if path
        @_source_root ||= default_source_root
      end

      # Tries to get the description from a USAGE file one folder above the source
      # root otherwise uses a default description.
      def self.desc(description = nil)
        return super if description
        usage = source_root && File.expand_path("../USAGE", source_root)

        @desc ||= if usage && File.exist?(usage)
          ERB.new(File.read(usage)).result(binding)
        else
          "#{generator_name} [#{arguments.drop(2).map(&:name).join(', ')}]: #{short_desc}."
        end
      end

      def self.short_desc
        nil
      end

      # Convenience method to get the namespace from the class name. It's the
      # same as Thor default except that the Generator at the end of the class
      # is removed.
      def self.namespace(name = nil)
        return super if name
        @namespace ||= super.sub(/_generator$/, '').sub(/:generators:/, ':')
      end

      # Returns the default source root for a given generator. This is used internally
      # by adhearsion to set its generators source root. If you want to customize your source
      # root, you should use source_root.
      def self.default_source_root
        return unless generator_name
        path = File.expand_path File.join(generator_name, 'templates'), base_root
        path if File.exists?(path)
      end

      # Returns the base root for a common set of generators. This is used to dynamically
      # guess the default source root.
      def self.base_root
        File.dirname __FILE__
      end

      protected

      # Removes the namespaces and get the generator name. For example,
      # Adhearsion::Generators::ModelGenerator will return "model" as generator name.
      #
      def self.generator_name
        @generator_name ||= begin
          if generator = name.to_s.split('::').last
            generator.sub!(/Generator$/, '')
            generator.underscore
          end
        end
      end

    end
  end
end
