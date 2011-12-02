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
  # * add dialplan, rpc, console and events methods
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
  # == How to add a new dialplan method
  #
  #   module MyPlugin
  #     class Plugin < Adhearsion::Plugin
  #       dialplan :my_new_dialplan_method do
  #         logger.info "this dialplan method is really awesome #{call.inspect}. It says 'hello world'"
  #         speak "hello world"
  #       end
  #     end
  #   end
  #
  # Create a new rpc, console or events methods is as ease just following this approach
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
  # during the initilization process
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

    extend ActiveSupport::Autoload

    METHODS_OPTIONS = {:load => true, :scope => false}

    SCOPE_NAMES = [:dialplan, :rpc, :events, :console]

    autoload :Configuration
    autoload :Collection
    autoload :Initializer
    autoload :MethodsContainer

    class << self
      # Metaprogramming to create the class methods that can be used in user defined plugins to
      # create specific scope methods
      SCOPE_NAMES.each do |name|

        # This block will create the relevant methods to handle how to add new methods
        # to Adhearsion scopes via an Adhearsion Plugin.
        # The scope method should have a name and a lambda block that will be executed in the
        # call ExecutionEnvironment context.
        #
        # class AhnPluginDemo < Adhearsion::Plugin
        #   dialplan :adh_plugin_demo do
        #     speak "hello world"
        #   end
        # end
        #
        # You could also defined a dialplan or other scope method as above, but you cannot access
        # the ExecutionEnvironment methods from your specific method due to ruby restrictions
        # when defining methods (the above lambda version should fit any requirement)
        #
        # class AhnPluginDemo < Adhearsion::Plugin
        #   dialplan :adh_plugin_demo
        #
        #   def self.adh_plugin_demo
        #     logger.debug "I can do fun stuff here, but I cannot access methods as speak"
        #     logger.debug "I can make an HTTP request"
        #     logger.debug "I can log to a specific logging system"
        #     logger.debug "I can access database..."
        #     logger.debug "but I cannot access call control methods"
        #   end
        #
        # end
        #
        define_method name do |method_name, &block|
          case method_name
          when Array
            method_name.each do |method|
              send name, method
            end
            return
          when Hash
            args = method_name
            method_name = method_name[:name]
          end

          options = args.nil? ? METHODS_OPTIONS : METHODS_OPTIONS.merge(args)
          options[:load] or return
          logger.debug "Adding method #{method_name} to scope #{name}"
          @@methods_container[name].store({:class => self, :method => method_name}, block.nil? ? nil : block)
        end

        # This method is a helper to retrieve the specific module that holds the user
        # defined scope methods
        define_method "#{name.to_s}_module" do
          Adhearsion::Plugin.methods_scope[name]
        end

        # Helper to add scope methods to any class/instance
        define_method "add_#{name.to_s}_methods" do |object|
          if object.kind_of?(Module)
            object.send :include, Adhearsion::Plugin.methods_scope[name]
          else
            object.extend Adhearsion::Plugin.methods_scope[name]
          end
          object
        end
      end

      ##
      # Class method that allows any subclass (any Adhearsion plugin) to register rake tasks.
      #
      # * Example 1:
      #
      #    FooBar = Class.new Adhearsion::Plugin do
      #      tasks do
      #        namespace :foo_bar do
      #        desc "Prints the FooBar plugin version"
      #        task :version do
      #          STDOUT.puts "FooBar plugin v0.1"
      #        end
      #      end
      #    end
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
      #    namespace :foo_bar do
      #       desc "Prints the FooBar plugin version"
      #       task :version do
      #         STDOUT.puts "FooBar plugin v0.1"
      #       end
      #    end
      #
      def tasks
        @@rake_tasks ||= []
        @@rake_tasks << Proc.new if block_given?
        @@rake_tasks
      end

      def load_tasks
        o = Object.new.tap { |o| o.extend Rake::DSL if defined? Rake::DSL }
        tasks.each do |block|
          o.instance_eval &block
        end
      end

      def methods_scope
        @methods_scope ||= Hash.new { |hash, key| hash[key] = Module.new }
      end

      # Keep methods to be added
      @@methods_container = Hash.new { |hash, key| hash[key] = MethodsContainer.new }

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
          self.plugin_name = name
        end
      end

      def plugin_name=(name)
        @plugin_name = name
      end

      def config name = nil
        if block_given?
          if name.nil?
            name = self.plugin_name
          else
            self.plugin_name = name
          end
          ::Loquacious::Configuration.defaults_for(name, &Proc.new)
        end

        ::Loquacious.configuration_for plugin_name
      end

      def show_description
        ::Loquacious::Configuration.help_for(plugin_name)
      end

      def load_plugins
        load_methods
        init_plugins
      end

      # Load plugins scope methods (scope = dialplan, console, etc)
      def load_methods
        unless @@methods_container.empty?

          @@methods_container.each_pair do |scope, methods|

            logger.debug "Loading #{methods.length} #{scope} methods"

            methods.each_pair do |class_method, block|
              klass, method = class_method[:class], class_method[:method]
              if block.nil?
                if klass.respond_to?(method)
                  block = klass.method(method).to_proc
                elsif klass.instance_methods.include?(method)
                  block = klass.instance_method(method).bind(klass.new)
                else
                  logger.warn "Unable to load #{scope} method #{method} from plugin class #{klass}"
                end
              end

              logger.debug "Defining method #{method}"
              block.nil? and raise NoMethodError.new "Invalid #{scope} method: <#{method}>"
              self.send("#{scope}_module").send(:define_method, method, &block)
            end
          end

          # We need to extend Console class with the plugin defined methods
          Adhearsion::Console.extend(self.console_module) unless self.console_module.instance_methods.empty?
        end
      end

      # Recursively initialization of all the loaded plugins
      def init_plugins *args
        initializers.tsort.each do |initializer|
          initializer.run *args
        end
      end

      def initializers
        @initializers ||= Collection.new
      end

      # Class method that will be used by subclasses to initialize the plugin
      # @param name Symbol plugin initializer name
      # @param opts Hash
      #     * :before specify the plugin to be loaded before another plugin
      #     * :after  specify the plugin to be loaded after another plugin
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
        subclasses.delete_if { |plugin| plugin.plugin_name.eql? plugin_name }
      end

      def delete_all
        @subclasses = nil
      end
    end

    [:plugin_name, :plugin_name=].each do |method|
      delegate method, :to => "self.class"
    end
  end
end
