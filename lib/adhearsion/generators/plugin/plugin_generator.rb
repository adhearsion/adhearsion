# encoding: utf-8

module Adhearsion
  module Generators
    class PluginGenerator < Generator

      argument :plugin_name, :type => :string

      def self.short_desc
        "A plugin template. 'plugin_name' should be the disired plugin module name, either CamelCase or under_scored."
      end

      def create_plugin
        @plugin_file = @plugin_name.underscore
        @plugin_name = @plugin_name.camelize
        self.destination_root = @plugin_file

        empty_directory "lib"
        empty_directory "lib/#{@plugin_file}"
        empty_directory "spec"


        template 'plugin-template.gemspec.tt', "#{@plugin_file}.gemspec"
        template 'Rakefile.tt', "Rakefile"
        template 'README.md.tt', "README.md"
        template 'Gemfile.tt', "Gemfile"

        template 'lib/plugin-template.rb.tt', "lib/#{@plugin_file}.rb"
        template 'lib/plugin-template/version.rb.tt', "lib/#{@plugin_file}/version.rb"
        template 'lib/plugin-template/plugin.rb.tt', "lib/#{@plugin_file}/plugin.rb"
        template 'lib/plugin-template/controller_methods.rb.tt', "lib/#{@plugin_file}/controller_methods.rb"

        template 'spec/spec_helper.rb.tt', "spec/spec_helper.rb"
        template 'spec/plugin-template/controller_methods_spec.rb.tt', "spec/#{@plugin_file}/controller_methods_spec.rb"
      end

    end
  end
end
