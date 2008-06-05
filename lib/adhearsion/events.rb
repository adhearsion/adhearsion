require 'thread'
module Adhearsion
  module Events
    
    class << self
      
      def framework_events_container
        defined?(@@framework_events_container) ? @@framework_events_container : reinitialize_framework_events_container!
      end
      
      def load_definitions_from_files(*files)
        files.each do |file|
          framework_events_container.instance_eval File.read(file)
        end
      end
      alias load_definitions_from_file load_definitions_from_files
      
      def namespace_registered?(*paths)
        framework_events_container.namespace_registered?(*paths)
      end
      
      def reinitialize_framework_events_container!
        @@framework_events_container = EventsDefinitionContainer.new
      end
      
      def register_namespace_path(*paths)
        framework_events_container.register_namespace_path(*paths)
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
      
      def namespace_registered?(*paths)
        !! inject_across_path(*paths) { |namespace,path| namespace[path] }
      rescue UndefinedEventNamespace
        false
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
      
      def method_missing(name, *args)
        super if name == :each # Added to prevent confusion
        nested_namespace_or_registrar = namespace[name.to_sym]
        raise UndefinedEventNamespace.new(name) unless nested_namespace_or_registrar
        case nested_namespace_or_registrar
          when EventCallbackRegistrar
            nested_namespace_or_registrar
          when RegisteredEventNamespace
            nested_namespace_or_registrar.capturer
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
      
      def register_callback_name(name, mode=:sync, &block)
        children[name] = case mode
          when :sync  then  SynchronousEventCallbackRegistrar
          when :async then AsynchronousEventCallbackRegistrar
          else
            raise ArgumentError, "Unsupported mode #{mode.inspect} !"
        end.new(self, &block)
      end
      
    end

    class EventCallbackRegistrar
      
      attr_reader   :namespace, :callbacks
      attr_accessor :notified_on_new_callback
      
      
      def initialize(namespace, &notified_on_new_callback)
        @namespace = namespace
        @callbacks = []
        @mutex     = Mutex.new
        @notified_on_new_callback = notified_on_new_callback
      end
      
      # This is effectively called when you define a new callback with each()
      def register_callback(&block)
        returning RegisteredEventCallback.new(self, &block) do |callback|
          with_lock { callbacks << callback }
          notified_on_new_callback.call callback if notified_on_new_callback
        end
      end
      alias each register_callback
      
      def <<(message)
        raise NotImplementedError
      end
      
      def remove_callback(callback)
        with_lock { callbacks.delete callback }
      end
      
      protected
      
      def with_lock(&block)
        @mutex.synchronize(&block)
      end
      
      def threadsafe_callback_collection
        with_lock { callbacks.clone }
      end
            
    end
    
    class SynchronousEventCallbackRegistrar < EventCallbackRegistrar
      def <<(event)
        threadsafe_callback_collection.each do |callback|
          callback.run_with_event event
        end
      end
    end
    
    class AsynchronousEventCallbackRegistrar < EventCallbackRegistrar
      
      attr_reader :thread
      def initialize(namespace, &notified_on_new_callback)
        super
        @thread = AsynchronousEventCallbackRegistrar.new
      end
      
      def <<(event)
        threadsafe_callback_collection.each do |callback|
          
        end
      end
      
      protected
      
      attr_reader :queue
      
      class AsynchronousEventHandlerThread < Thread
        
        def initialize(&block)
          @queue = Queue.new
          super do
            loop { block.call @queue.pop }
          end
        end
        
        def <<(event)
          @queue << event
        end
        
      end
      
    end
    
    # A RegisteredEventCallback is stored away each time you call each() on an event namespace.
    # It keeps a copy of the namespace 
    class RegisteredEventCallback
      
      attr_reader :registrar, :args, :block
      def initialize(registrar, *args, &block)
        raise ArgumentError, "Must supply a callback in the form of a block!" unless block_given?
        @registrar, @args, @block = registrar, args, block
      end
      
      def run_with_event(event)
        begin
          block.call event
        rescue => e
          indenter = "\n" + (" " * 5)
          ahn_log.events.error e.message + indenter + e.backtrace.join(indenter)
        end
      end
      
      def namespace
        registrar.namespace
      end
      
    end
    
  end
end
