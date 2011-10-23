
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

      def load(klass = self)
        klass.subclasses.each do |plugin|
          logger.debug "Initialing plugin #{plugin.plugin_name}"
          
          # load plugin code based on init method
          Adhearsion::Components.component_manager.load_code plugin.init

          # load plugin code based on dialplan_methods method
          if plugin.respond_to?(:dialplan_methods) && plugin.dialplan_methods.respond_to?(:length) && plugin.dialplan_methods.length > 0
            str = "methods_for :dialplan do\n"
            plugin.dialplan_methods.uniq.each do |dialplan_method|
              str.concat "def #{dialplan_method}\n"
              str.concat " #{plugin}.#{dialplan_method}\n"
              str.concat "end\n"
            end
            str.concat "end\n"
            Adhearsion::Components.component_manager.load_code str
          end
          
          # load plugin code based on dialplan method 
          unless dialplan_methods.empty?
            dialplan_methods.each_pair do |method, block|
              dialplan_module.send(:define_method, method) do
                block.call
              end
            end
          end
          
          # load plugin childs
          load(plugin)
        end
      end
      
      def dialplan_module
        Adhearsion::Components.component_manager.instance_variable_get("@scopes")[:dialplan]
      end

      
      ##
      # Method to be use when defining dialplan methods
      #
      # class AhnPluginDemo < Adhearsion::Plugin
      #   dialplan :adh_plugin_demo_3 do |call|
      #    call.say "hello world"
      #   end
      # end
      def dialplan(method_name)
        logger.debug "Adding method #{method_name} to scope dialplan"
        dialplan_methods.store(method_name, Proc.new)
      end


      # method to be implemented by subclasses
      def init
        logger.warn "#{self.name} should overwrite the init method"
      end

      def count
        subclasses.length
      end

      def add(klass)
        klass.ancestors.include?(self) and subclasses << klass
      end

      def delete(plugin_name)
        plugin_name.ancestors.include?(self) and plugin_name = plugin_name.plugin_name
        subclasses.delete_if{ |plugin| plugin.plugin_name.eql?(plugin_name)}
      end

      def delete_all
        self.subclasses = nil
      end

      private

      def subclasses=(value)
        @subclasses = value
      end

      def dialplan_methods
        @@dialplan_methods ||= {}
      end

    end

    [:plugin_name, :plugin_name=].each do |method|
      delegate method, :to => "self.class"
    end

  end

end