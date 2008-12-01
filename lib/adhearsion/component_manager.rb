module Adhearsion
  module Components
    
    class ComponentManager
      
      SCOPE_NAMES = [:dialplan, :events, :generators, :rpc, :global]
      DEFAULT_CONFIG_NAME = "config.yml"
      
      attr_reader :scopes, :lazy_config_loader
      def initialize(path_to_container_directory)
        @path_to_container_directory = path_to_container_directory
        @scopes = SCOPE_NAMES.inject({}) do |scopes, name|
          scopes[name] = []
          scopes
        end
        @lazy_config_loader = LazyConfigLoader.new(self)
      end
      
      def load_components
        components = Dir.glob(File.join(@path_to_container_directory + "/*")).select do |path|
          File.directory?(path)
        end
        components.map! { |path| File.basename path }
        components.each do |component|
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
        
        unrecognized_scopes = scopes - SCOPE_NAMES
        raise ArgumentError, "Unrecognized scopes #{unrecognized_scopes.map(&:inspect).to_sentence}" if unrecognized_scopes.any?
        
        scopes.each do |scope|
          Array(@scopes[scope]).each do |methods|
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
        if metadata[:initialization_block]
          metadata[:initialization_block].call
        end
        metadata[:scopes].each_pair do |scope, blocks|
          @scopes[scope].concat blocks
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
          raise ArgumentError, "Do not recognize scope: #{scopes.to_sentence}" if (scopes - SCOPE_NAMES).any?
          metadata = metaclass.send(:instance_variable_get, :@metadata)
          scopes.each do |scope|
            anonymous_component_module = Module.new(&block)
            metadata[:scopes][scope] << anonymous_component_module
            if scope.equal? :global
              Object.send(:include, anonymous_component_module)
            end
          end
        end
        
        # def delegate(*method_names_to_delegate)
        #   options = method_names_to_delegate.pop if method_names_to_delegate.last.kind_of?(Hash)
        #   recipient = options[:to]
        #   if recipient
        #     method_names_to_delegate.each do |method_name|
        #       metaclass.instance_eval(<<-RUBY, __FILE__, __LINE__)
        #         def #{method_name}(*args, &block)
        #           
        #         end
        #       RUBY
        #     end
        #   else
        #     raise ArgumentError, "Delegation needs a target. Supply an options hash with a :to key as the last argument (e.g. delegate :hello, :world, :to => :greeter)."
        #   end
        # end
        # 
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
