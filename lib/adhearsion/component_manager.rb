require "singleton"

module Adhearsion
  module Components
    
    
    class << self
      
      def extend_object_with(object, *scopes)
        ComponentManager.instance.extend_object_with(object, *scopes)
      end
      
      def load_component_code(code)
        ComponentManager.instance.load_code code
      end
      
    end
    
    class ComponentManager
      
      include Singleton
      
      SCOPE_NAMES = [:dialplan, :events, :generators, :rpc]
      
      attr_reader :scopes
      def initialize
        @scopes = SCOPE_NAMES.inject({}) do |scopes, name|
          scopes[name] = []
          scopes
        end
      end
      
      def extend_object_with(object, *scopes)
        raise ArgumentError, "Must supply at least one scope!" if scopes.empty?
        
        unrecognized_scopes = scopes - SCOPE_NAMES
        raise ArgumentError, "Unrecognized scopes #{unrecognized_scopes.map(&:inspect).to_sentence}" if unrecognized_scopes.any?
        
        scopes.each do |scope|
          Array(ComponentManager.instance.scopes[scope]).each do |methods|
            object.extend methods
          end
        end
      end
    
      def load_code(code)
        container = ComponentDefinitionContainer.load_code code
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
            returning new do |container|
              container.module_eval code
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
          raise ArgumentError if (scopes - SCOPE_NAMES).any?
          metadata = metaclass.send(:instance_variable_get, :@metadata)
          scopes.each do |scope|
            metadata[:scopes][scope] << Module.new(&block)
          end
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
    
    end
  end
end
