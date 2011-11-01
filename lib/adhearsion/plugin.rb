
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

    extend ActiveSupport::Autoload

    DIALPLAN_OPTIONS = {:load => true, :scope => false}

    autoload :Configuration
    autoload :Collection   
    autoload :Initializer

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

      def load
        init_plugin

        # load plugins dialplan methods
        unless dialplan_methods.empty?
          logger.debug "Loading #{dialplan_methods.length} dialplan methods"
          dialplan_methods.each_pair do |class_method, block|
            klass, method = class_method[:class], class_method[:method]
            if block.nil?
              if klass.respond_to?(method)
                block = klass.method(method)
              elsif klass.instance_methods.include?(method)
                block = klass.instance_method(method).bind(klass.new)
              else
                logger.warn("Unable to load dialplan method #{method} from plugin class #{klass}")
              end
            end
            logger.debug "Defining method #{method}"
            dialplan_module.send(:define_method, method) do |*args|
              block.nil? and raise NoMethodError.new "Invalid dialplan method: <#{method}>"
              block.call(args)
            end
          end
        end          
      end

      ##
      # Recursively initialization of all the loaded plugins
      # @param klass working class: Plugin or Plugin child
      #
      def init_plugin(*args)
        initializers.tsort.each do |initializer|
          initializer.run(*args)
        end
      end
      
      def dialplan_module
        Adhearsion::Components.component_manager.instance_variable_get("@scopes")[:dialplan]
      end

      
      ##
      # Method to be use when defining dialplan methods
      #
      # class AhnPluginDemo < Adhearsion::Plugin
      #   dialplan :adh_plugin_demo do |call|
      #    call.say "hello world"
      #   end
      # end
      def dialplan(method_name, args = nil)
        method_name.is_a?(Array) and method_name.each { |method| dialplan(method, args)} and return

        options = args.nil? ? DIALPLAN_OPTIONS : DIALPLAN_OPTIONS.merge(args)

        options[:load] or return

        logger.debug "Adding method #{method_name} to scope dialplan"
        if block_given?
          dialplan_methods.store({:class => self, :method => method_name}, Proc.new)
        else
          dialplan_methods.store({:class => self, :method => method_name}, nil)
        end
      end

      def initializers
        @initializers ||= Collection.new
      end

      def init(name, opts = {})
        block_given? or raise ArgumentError, "A block must be passed while defining the Plugin initialization process"
        opts[:after] ||= initializers.last.name unless initializers.empty? || initializers.find { |i| i.name == opts[:before] }
        Adhearsion::Plugin.initializers << Initializer.new(name, nil, opts, &Proc.new)
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

      def dialplan_methods=(value)
        @@dialplan_methods = value
      end

    end

    [:plugin_name, :plugin_name=].each do |method|
      delegate method, :to => "self.class"
    end

  end

end