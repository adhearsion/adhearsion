module Adhearsion
  module Components
    
    mattr_accessor :component_manager
    
    class ComponentManager
      
      class << self
        
        def scopes_valid?(*scopes)
          unrecognized_scopes = (scopes.flatten - SCOPE_NAMES).map(&:inspect)
          raise ArgumentError, "Unrecognized scopes #{unrecognized_scopes.to_sentence}" if unrecognized_scopes.any?
          true
        end
        
      end
      
      SCOPE_NAMES = [:dialplan, :events, :generators, :rpc, :global]
      DEFAULT_CONFIG_NAME = "config.yml"
      
      attr_reader :scopes, :lazy_config_loader
      def initialize(path_to_container_directory)
        @path_to_container_directory = path_to_container_directory
        @scopes = SCOPE_NAMES.inject({}) do |scopes, name|
          scopes[name] = Module.new
          scopes
        end
        @lazy_config_loader = LazyConfigLoader.new(self)
      end
      
      ##
      # Includes the anonymous Module created for the :global scope in Object, making its methods globally accessible.
      #
      def globalize_global_scope!
        Object.send :include, @scopes[:global]
      end
      
      def load_components
        components = Dir.glob(File.join(@path_to_container_directory + "/*")).select do |path|
          File.directory?(path)
        end
        components.map! { |path| File.basename path }
        components.each do |component|
          next if component == "disabled"
          component_file = File.join(@path_to_container_directory, component, component + ".rb")
          if File.exists? component_file
            load_file component_file
          else
            ahn_log.warn "Component directory does not contain a matching .rb file! Was expecting #{component_file.inspect}"
          end
        end
        
      end
      
      ##
      # Loads the configuration file for a given component name.
      #
      # @return [Hash] The loaded YAML for the given component name. An empty Hash if no YAML file exists.
      #
      def configuration_for_component_named(component_name)
        component_dir = File.join(@path_to_container_directory, component_name)
        config_file = File.join component_dir, DEFAULT_CONFIG_NAME
        if File.exists?(config_file)
          YAML.load_file config_file
        else
          return {}
        end
      end
      
      def extend_object_with(object, *scopes)
        raise ArgumentError, "Must supply at least one scope!" if scopes.empty?
        
        self.class.scopes_valid? scopes
        
        scopes.each do |scope|
          methods = @scopes[scope]
          if object.kind_of?(Module)
            object.send :include, methods
          else
            object.extend methods
          end
        end
        object
      end
    
      def load_code(code)
        load_container ComponentDefinitionContainer.load_code(code)
      end

      def load_file(filename)
        load_container ComponentDefinitionContainer.load_file(filename)
      end
      
      protected
      
      def load_container(container)
        container.constants.each do |constant_name|
          constant_value = container.const_get(constant_name)
          Object.const_set(constant_name, constant_value)
        end
        metadata = container.metaclass.send(:instance_variable_get, :@metadata)
        metadata[:initialization_block].call if metadata[:initialization_block]
        
        self.class.scopes_valid? metadata[:scopes].keys
        
        metadata[:scopes].each_pair do |scope, method_definition_blocks|
          method_definition_blocks.each do |method_definition_block|
            @scopes[scope].module_eval(&method_definition_block)
          end
        end
        container
      end

      class ComponentDefinitionContainer < Module
        
        class << self
          def load_code(code)
            returning(new) do |instance|
              instance.module_eval code
            end
          end
          
          def load_file(filename)
            returning(new) do |instance|
              instance.module_eval File.read(filename), filename
            end
          end
        end
        
        def initialize(&block)
          # Hide our instance variables in the singleton class
          metadata = {}
          metaclass.send(:instance_variable_set, :@metadata, metadata)
          
          metadata[:scopes] = ComponentManager::SCOPE_NAMES.inject({}) do |scopes, name|
            scopes[name] = []
            scopes
          end
          
          super
          
          meta_def(:initialize) { raise "This object has already been instantiated. Are you sure you didn't mean initialization()?" }
        end
        
        def methods_for(*scopes, &block)
          raise ArgumentError if scopes.empty?
          
          ComponentManager.scopes_valid? scopes
          
          metadata = metaclass.send(:instance_variable_get, :@metadata)
          scopes.each { |scope| metadata[:scopes][scope] << block }
        end
        
        def initialization(&block)
          # Raise an exception if the initialization block has already been set
          metadata = metaclass.send(:instance_variable_get, :@metadata)
          if metadata[:initialization_block]
            raise "You should only have one initialization() block!"
          else
            metadata[:initialization_block] = block
          end
        end
        alias initialisation initialization
        
        protected
        
        class << self
          def self.method_added(method_name)
            @methods ||= []
            @methods << method_name
          end
        end
        
      end
    
      class ComponentMethodDefinitionContainer < Module
        class << self
          def method_added(method_name)
            @methods ||= []
            @methods << method_name
          end
        end
        
        attr_reader :scopes
        def initialize(*scopes, &block)
          @scopes = []
          super(&block)
        end
        
      end
    
      class LazyConfigLoader
        def initialize(component_manager)
          @component_manager = component_manager
        end
        
        def method_missing(component_name)
          config = @component_manager.configuration_for_component_named(component_name.to_s)
          meta_def(component_name) { config }
        end
      end
    
    end
  end
end
