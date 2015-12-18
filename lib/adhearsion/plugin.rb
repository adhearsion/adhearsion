# encoding: utf-8

require 'loquacious'
require 'active_support/inflector'
require 'adhearsion/foundation/object'
require 'adhearsion/configuration'
%w(
  collection
  initializer
).each { |r| require "adhearsion/plugin/#{r}" }

module Adhearsion

  # Plugin is the core of extension of Adhearsion framework and provides the easiest
  # path to add new functionality, configuration or modify the initialization process.
  #
  # Its behavior is based on Rails::Railtie, so if you are familiar with Rails
  # this will be easier for you to start using Adhearsion::Plugin, but of course
  # no previous knowledge is required.
  #
  # With an Adhearsion Plugin you can:
  #
  # * create initializers
  # * add rake tasks to Adhearsion
  # * add/modify configuration files
  #
  # == How to create your Adhearsion Plugin
  #
  # Create a class that inherits from Adhearsion::Plugin within your plugin namespace.
  # This class shall be loaded during your awesome Adhearsion application boot process.
  #
  #   # lib/my_plugin/plugin.rb
  #   module MyPlugin
  #     class Plugin < Adhearsion::Plugin
  #     end
  #   end
  #
  # == Execute a specific code while initializing Adhearison
  #
  #   module MyPlugin
  #     class Plugin < Adhearsion::Plugin
  #       init :my_plugin do
  #         logger.warn "I want to ensure my plugin is being loaded!!!"
  #       end
  #     end
  #   end
  #
  # As Rails::Railtie does, you can define the exact point when you want to load your plugin
  # during the initialization process.
  #
  #   module MyPlugin
  #     class Plugin < Adhearsion::Plugin
  #       init :my_plugin, :after => :my_other_plugin do
  #         logger.warn "My Plugin depends on My Other Plugin, so it must be loaded after"
  #       end
  #     end
  #   end
  #
  class Plugin

    METHODS_OPTIONS = {:load => true, :scope => false}

    class << self
      ##
      # Class method that allows any subclass (any Adhearsion plugin) to register rake tasks.
      #
      # * Example 1:
      #
      #     FooBar = Class.new Adhearsion::Plugin do
      #       tasks do
      #         namespace :foo_bar do
      #           desc "Prints the FooBar plugin version"
      #           task :version do
      #             STDOUT.puts "FooBar plugin v0.1"
      #           end
      #         end
      #       end
      #     end
      #
      # * Example 2:
      #
      #    FooBar = Class.new Adhearsion::Plugin do
      #      tasks do
      #        load "tasks/foo_bar.rake"
      #      end
      #    end
      #
      #    = tasks/foo_bar.rake
      #
      #     namespace :foo_bar do
      #       desc "Prints the FooBar plugin version"
      #       task :version do
      #         STDOUT.puts "FooBar plugin v0.1"
      #       end
      #     end
      #
      def tasks
        @@rake_tasks << Proc.new if block_given?
        @@rake_tasks
      end

      def reset_rake_tasks
        @@rake_tasks = []
      end

      def load_tasks
        container = Object.new.tap { |o| o.extend Rake::DSL if defined? Rake::DSL }
        tasks.each do |block|
          container.instance_eval(&block)
        end
      end

      ##
      # Register generator classes
      #
      # @example
      #     FooBar = Class.new Adhearsion::Plugin do
      #       generators :'my_plugin:foo_generator' => FooGenerator
      #     end
      #
      def generators(mapping)
        mapping.each_pair do |name, klass|
          Generators.add_generator name, klass
        end
      end

      def subclasses
        @subclasses ||= []
      end

      def inherited(base)
        logger.info "Detected new plugin: #{base.name}"
        subclasses << base
      end

      def plugin_name(name = nil)
        if name.nil?
          @plugin_name ||= ActiveSupport::Inflector.underscore(self.name)
        else
          self.plugin_name = name
        end
      end
      alias :app_name :plugin_name

      def plugin_name=(name)
        @plugin_name = name
      end
      alias :app_name= :plugin_name=

      # Class method that will be used by subclasses to configure the plugin
      # @param name Symbol plugin config name
      def config(name = nil, &block)
        if name.nil?
          name = self.plugin_name
        else
          self.plugin_name = name
        end

        if block_given?
          opts = {}
          opts[:after] ||= configs.last.name unless configs.empty?
          ::Loquacious::Configuration.defaults_for plugin_name, &Proc.new
          initializer = Initializer.new(plugin_name, self, opts) do
            ::Loquacious.configuration_for plugin_name, &block
          end
          Adhearsion::Plugin.configs << initializer
        else
          ::Loquacious.configuration_for plugin_name
        end
      end

      def show_description
        ::Loquacious::Configuration.help_for plugin_name
      end

      def configure_plugins(*args)
        configs.tsort.each do |config|
          config.run(*args)
        end
      end

      # Recursively initialization of all the loaded plugins
      def init_plugins(*args)
        initializers.tsort.each do |initializer|
          initializer.run(*args)
        end
      end

      def run_plugins(*args)
        runners.tsort.each do |runner|
          runner.run(*args)
        end
      end

      def configs
        @configs ||= Collection.new
      end

      def initializers
        @initializers ||= Collection.new
      end

      def runners
        @runners ||= Collection.new
      end

      # Class method that will be used by subclasses to initialize the plugin
      # @param name Symbol plugin initializer name
      # @param opts Hash
      #     * :before specify the plugin to be loaded before another plugin
      #     * :after  specify the plugin to be loaded after another plugin
      def init(name = nil, opts = {}, &block)
        name = plugin_name unless name
        block_given? or raise ArgumentError, "A block must be passed while defining the Plugin initialization process"
        opts[:after] ||= initializers.last.name unless initializers.empty? || initializers.find { |i| i.name == opts[:before] }
        Adhearsion::Plugin.initializers << Initializer.new(name, self, opts, &block)
      end

      # Class method that will be used by subclasses to run the plugin
      # @param name Symbol plugin initializer name
      # @param opts Hash
      #     * :before specify the plugin to be loaded before another plugin
      #     * :after  specify the plugin to be loaded after another plugin
      def run(name = nil, opts = {}, &block)
        name = plugin_name unless name
        block_given? or raise ArgumentError, "A block must be passed while defining the Plugin run process"
        opts[:after] ||= runners.last.name unless runners.empty? || runners.find { |i| i.name == opts[:before] }
        Adhearsion::Plugin.runners << Initializer.new(name, self, opts, &block)
      end

      def count
        subclasses.length
      end

      def add(klass)
        klass.ancestors.include?(self) and subclasses << klass
      end

      def delete(plugin_name)
        plugin_name.ancestors.include?(self) and plugin_name = plugin_name.plugin_name
        subclasses.delete_if { |plugin| plugin.plugin_name.eql? plugin_name }
      end

      def delete_all
        @subclasses = nil
      end
    end

    reset_rake_tasks

    [:plugin_name, :plugin_name=].each do |method|
      delegate method, :to => "self.class"
    end
  end
end
