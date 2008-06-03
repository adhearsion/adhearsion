module Adhearsion
  module Events
    
    class << self
      
      def framework_events_container
        # defined?(@@framework_events_container) ? @@framework_events_container : reinitialize_framework_events_container!
        @@framework_events_container ||= EventsDefinitionContainer.new
      end
      
      def load_definitions_from_files(*files)
        files.each do |file|
          framework_events_container.instance_eval File.read(file)
        end
      end
      alias load_definitions_from_file load_definitions_from_files
      
      def reinitialize_framework_events_container!
        @@framework_events_container = EventsDefinitionContainer.new
      end
      
    end
    
    class EventsDefinitionContainer

      attr_reader :root
      def initialize
        @root = RootEventNamespace.new
      end
      
      def register_namespace_path(*paths)
        inject_across_path(*paths) do |namespace, path|
          namespace.namespace_registered?(path) ? namespace[path] : namespace.register_namespace(path)
        end
      end
      
      def events
        root.capturer
      end
      
      def callbacks_at_path(*paths)
        inject_across_path(*paths) { |namespace,path| namespace[path] }.callbacks
      end
      
      private
      
      def inject_across_path(*paths, &block)
        paths.map(&:to_sym).inject(root, &block)
      end
    end
    
    class NamespaceDefinitionCapturer
      
      attr_reader :namespace
      def initialize(namespace)
        @namespace = namespace
      end
      
      def method_missing(name)
        super if name == :each
        nested_namespace = namespace[name.to_sym]
        raise UndefinedEventNamespace.new(name) unless nested_namespace
        case nested_namespace
          when EventCallbackRegistrar
            nested_namespace
          when RegisteredEventNamespace
            nested_namespace.capturer
        end
      end
    end
    
    class UndefinedEventNamespace < Exception
      def initialize(name)
        super "Undefined namespace '#{name}'"
      end
    end
    
    class AbstractEventNamespace
      
      attr_reader :children
      def initialize
        @children = {}
      end
      
      def [](namespace_name)
        raise UndefinedEventNamespace.new(namespace_name) unless namespace_registered? namespace_name
        children[namespace_name]
      end
      
      def namespace_registered?(namespace_name)
        children.has_key?(namespace_name)
      end
      
      def register_namespace(namespace)
        children[namespace] = RegisteredEventNamespace.new(self)
      end
      
      def root?
        false
      end
      
      def capturer
        @capturer ||= NamespaceDefinitionCapturer.new(self)
      end
      
    end

    class RootEventNamespace < AbstractEventNamespace
      
      def parent
        nil
      end
      
      def root?
        true
      end
    end
    
    class RegisteredEventNamespace < AbstractEventNamespace
      attr_reader :parent
      def initialize(parent)
        super()
        @parent = parent
      end
      
      def register_callback_name(name)
        children[name] = Adhearsion::Events::EventCallbackRegistrar.new(self)
      end
      
    end

    class EventCallbackRegistrar
      
      attr_reader :callbacks, :namespace
      def initialize(namespace)
        @namespace = namespace
        @callbacks = []
      end
      
      def register_callback(&block)
        returning RegisteredEventCallback.new(self, &block) do |callback|
          callbacks << callback
        end
      end
      alias each register_callback
      
      def remove_callback(callback)
        @callbacks.delete callback
      end
      
      class RegisteredEventCallback
        
        attr_reader :registrar
        def initialize(registrar)
          @registrar = registrar
        end
        
      end
      
    end

  end
end
