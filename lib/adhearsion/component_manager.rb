require "singleton"

module Adhearsion
  module Components
    
    
    class << self
      
      def extend_object_with(object, *scopes)
        raise ArgumentError, "Must supply at least one scope!" if scopes.empty?
        
        raise NotImplementedError
      end
      
      def load_component_code(code)
        ComponentManager.instance.load_code code
      end
      
    end
    
    class ComponentManager
      
      include Singleton
      
      SCOPE_NAMES = [:dialplan, :events, :generators, :rpc]
      
      def initialize
        @component_blocks = []
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
        container
      end
    
      class ComponentDefinitionContainer < Module
        
        class << self
          def load_code(code)
            returning new do |container|
              container.module_eval code
            end
          end
          
          def extract_metadata_from(container)
            container.metaclass.send(:instance_variable_get, :@metadata)
          end
          
        end
        
        def initialize(&block)
          # Hide our instance variables in the singleton class
          metaclass.send(:instance_variable_set, :@metadata, {})
          
          super
          
          meta_def(:initialize) { raise "This object has already been instantiated. Are you sure you didn't mean initialization()?" }
        end
        
        def methods_for(*scopes, &block)
          raise ArgumentError if scopes.empty?
          raise ArgumentError if (scopes - SCOPE_NAMES).any?
          
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
