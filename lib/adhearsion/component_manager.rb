module Adhearsion

  module Components
    class Manager
      attr_reader :active_components, :host_information, :started_components, :components_with_call_context
      def initialize
        @active_components            = {}
        @started_components           = []
        @components_with_call_context = {}
      end

      def [](component_name)
        active_components[component_name].component_class.instance
      end
    
      def component(component_name)
        active_components[component_name]
      end
    
      def has_component?(component_name)
        active_components.has_key?(component_name)
      end
      
      def component_gems
        @repository ||= RubygemsRepository.new
        @repository.adhearsion_gems
      end
    
      def load
        return unless File.exist?(AHN_ROOT.component_path)
        component_directories = Dir.glob(File.join(AHN_ROOT.component_path, "*"))
        component_directories.each do |component_directory|
          component_name = File.basename(component_directory).intern
          @active_components[component_name] = Component.new(self, component_name, component_directory)
        end
      end
    
      def start
        @active_components.keys.each do |name|
          @active_components[name].start
        end
      end

      def stop
        @started_components.reverse.each do |name|
          @active_components[name].stop
        end
      end

      class RubygemsRepository
        def initialize
          require 'rubygems'
          Gem.manage_gems
        end

        def adhearsion_gems
          gems = {}
          Gem.source_index.each {|name, spec| gems[spec.name] = spec.full_gem_path if spec.requirements.include?("adhearsion")}
          gems
        end
      end
    end
    
    ClassToGetCallContext = Struct.new(:component_class, :instance_variable)
    class ClassToGetCallContext
      def instantiate_with_call_context(call_context, *args, &block)
        component = component_class.allocate
        component.instance_variable_set(("@"+instance_variable.to_s).intern, call_context)
        component.send(:initialize, *args, &block)
        component
      end
    end
    
    
    #component behavior is shared across components
    module Behavior
      def self.included(component_class)
        component_class.extend(ClassMethods)
      end
      
      def component_name
        Component.name
      end

      def component_description
        Configuration.description || Component.name
      end
      
      module ClassMethods
        def add_call_context(params = {:as => :call_context})
          attr_reader params[:as]
          ComponentManager.components_with_call_context[name] = ClassToGetCallContext.new(self, params[:as])
        end
      end
    end
    
    class Component
      class << self
        def prepare_component_class(component_module, name)
          component_class_name = name.to_s.camelize
          component_module.module_eval(<<-EVAL, __FILE__, __LINE__)
            class #{component_class_name}
              def self.name
                '#{component_class_name}'
              end
              include Adhearsion::Components::Behavior
            end
          EVAL
        end
      end
        
      attr_reader :manager, :name, :path, :component_module, :component_class
      def initialize(manager, name, path)
        @manager = manager
        @name = name
        @path = path
        unless File.exist?(main_file_name)
          gem_path = @manager.component_gems[@name.to_s]
          raise "The component '#{@name}' does not have the main file: #{main_file_name}" unless gem_path
          @path = gem_path
        end
        @started = false
      end
      
      def start
        return if @started
        manager.started_components << @name
        @started = true
        @component_module = ComponentModule.new(self) do |component_module|
          Component.prepare_component_class(component_module, @name)
          component_module.load_configuration_file
        end
        @component_module.require(File.join("lib", @name.to_s))
      end
      
      def configuration
        @component_module.const_get(:Configuration)
      end
      
      def stop
        #@component_class.unload if @component_class && @component_class.respond_to?(:unload)
      end
      
      def configuration_file
         File.join(path, configuration_file_name)
      end
      
      private
      
        def main_file_name
          File.join(@path, "lib", @name.to_s+".rb")
        end
      
        def configuration_file_name
          "configuration.rb"
        end
    end

    class ComponentModule < Module
      # The file with which the Script was instantiated.
      attr_reader :main_file

      # The directory in which main_file is located, and relative to which
      # #load searches for files before falling back to Kernel#load.
      attr_reader :dir

      # A hash that maps <tt>filename=>true</tt> for each file that has been
      # required locally by the script. This has the same semantics as <tt>$"</tt>,
      # alias <tt>$LOADED_FEATURES</tt>, except that it is local to this script.
      attr_reader :loaded_features

      class << self
        alias load new
      end

      # Creates new Script, and loads _main_file_ in the scope of the Script. If a
      # block is given, the script is passed to it before loading from the file, and
      # constants can be defined as inputs to the script.
      attr_reader :component
      def initialize(component)   # :yields: self
        extend ComponentModuleMethods
        @component       = component        
        @loaded_features = {}

        const_set :Component, component
        const_set :Configuration, OpenStruct.new(:description => nil)

        yield self if block_given?
      end
      
      def load_configuration_file
        load_in_module(component.configuration_file)
      end

      # Loads _file_ into this Script. Searches relative to the local dir, that is,
      # the dir of the file given in the original call to
      # <tt>Script.load(file)</tt>, loads the file, if found, into this Script's
      # scope, and returns true. If the file is not found, falls back to
      # <tt>Kernel.load</tt>, which searches on <tt>$LOAD_PATH</tt>, loads the file,
      # if found, into global scope, and returns true. Otherwise, raises
      # <tt>LoadError</tt>.
      #
      # The _wrap_ argument is passed to <tt>Kernel.load</tt> in the fallback case,
      # when the file is not found locally.
      #
      # Typically called from within the main file to load additional sub files, or
      # from those sub files.

      def load(file, wrap = false)
        load_in_module(File.join(component.path, file))
        true
      rescue MissingFile
        super
      end

      # Analogous to <tt>Kernel#require</tt>. First tries the local dir, then falls
      # back to <tt>Kernel#require</tt>. Will load a given _feature_ only once.
      #
      # Note that extensions (*.so, *.dll) can be required in the global scope, as
      # usual, but not in the local scope. (This is not much of a limitation in
      # practice--you wouldn't want to load an extension more than once.) This
      # implementation falls back to <tt>Kernel#require</tt> when the argument is an
      # extension or is not found locally.

      def require(feature)
        unless @loaded_features[feature]
          @loaded_features[feature] = true
          file = feature
          file += ".rb" unless /\.rb$/ =~ file
          load_in_module(File.join(component.path, file))
        end
      rescue MissingFile
        @loaded_features[feature] = false
        super
      end

      # Raised by #load_in_module, caught by #load and #require.
      class MissingFile < LoadError; end

      # Loads _file_ in this module's context. Note that <tt>\_\_FILE\_\_</tt> and
      # <tt>\_\_LINE\_\_</tt> work correctly in _file_.
      # Called by #load and #require; not normally called directly.

      def load_in_module(file)
        module_eval(File.read(file), File.expand_path(file))
      rescue Errno::ENOENT => e
        if /#{file}$/ =~ e.message
          raise MissingFile, e.message
        else
          raise
        end
      end

      def to_s
        "#<#{self.class}:#{File.basename(component.path)}>"
      end

      module ComponentModuleMethods
        # This is so that <tt>def meth...</tt> behaves like in Ruby's top-level
        # context. The implementation simply calls
        # <tt>Module#module_function(name)</tt>.
        def method_added(name) # :nodoc:
          module_function(name)
        end

        def start_component_after(*others)
          others.each do |component_name|
            component.manager.active_components[component_name].start
          end
        end

      end
    end
  end
  
  ComponentManager = Components::Manager.new unless defined? ComponentManager
end