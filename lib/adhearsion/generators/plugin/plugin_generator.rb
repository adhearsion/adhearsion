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
        self.destination_root = '.'

        empty_directory @plugin_file
        empty_directory "#{@plugin_file}/lib"
        empty_directory "#{@plugin_file}/lib/#{@plugin_file}"
        empty_directory "#{@plugin_file}/spec"

        template 'plugin-template.gemspec.tt', "#{@plugin_file}/#{@plugin_file}.gemspec"
        template 'Rakefile.tt', "#{@plugin_file}/Rakefile"
        template 'README.md.tt', "#{@plugin_file}/README.md"
        template 'Gemfile.tt', "#{@plugin_file}/Gemfile"

        template 'lib/plugin-template.rb.tt', "#{@plugin_file}/lib/#{@plugin_file}.rb"
        template 'lib/plugin-template/version.rb.tt', "#{@plugin_file}/lib/#{@plugin_file}/version.rb"
        template 'lib/plugin-template/plugin.rb.tt', "#{@plugin_file}/lib/#{@plugin_file}/plugin.rb"
        template 'lib/plugin-template/controller_methods.rb.tt', "#{@plugin_file}/lib/#{@plugin_file}/controller_methods.rb"

        template 'spec/spec_helper.rb.tt', "#{@plugin_file}/spec/spec_helper.rb"
        template 'spec/plugin-template/controller_methods_spec.rb.tt', "#{@plugin_file}/spec/#{@plugin_file}/controller_methods_spec.rb"
      end

    end
  end
end
