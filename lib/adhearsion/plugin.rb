
module Adhearsion

  # Plugin is the core of extension of Adhearsion framework and provides the path
  # to add new functionality, configuration or modify the initialization process.
  #
  # Its behavior is based on Rails::Railtie, so if you are familiar with Rails 
  # this will be easier for you to start using Adhearsion::Plugin, but of course
  # it is not required any previous knowledge.
  #
  # With an Adhearsion Plugin you can:
  #
  # * create initializers
  # * add rake tasks to Adhearsion
  # * add/modify configuration files
  # * add dialplan methods
  #
  # == How to create your Adhearsion Plugin
  #
  # Create a class that inherits from Adhearsion::Plugin within your extension's namespace.
  # This class must be loaded during the Adhearsion boot process.
  #
  #   # lib/my_plugin/plugin.rb
  #   module MyPlugin
  #     class Plugin < Adhearsion::Plugin
  #     end
  #   end
  #

  class Plugin

    autoload :Configuration, 'adhearsion/plugin/configuration'

    class << self

      def subclasses
        @subclasses ||= []
      end

      def inherited(base)
        logger.trace "Detected new plugin: #{base.name}"
        subclasses << base
      end

      def plugin_name(name = nil)
        if name.nil?
          @plugin_name ||= ActiveSupport::Inflector.underscore(self.name)
        else
          self.plugin_name=name
        end
      end

      def plugin_name=(name)
        @plugin_name = name
      end

      def config
        @config ||= Configuration.new
      end

    end

    delegate :plugin_name, :to => "self.class"
    delegate :plugin_name=, :to => "self.class"

  end

end