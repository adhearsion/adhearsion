require 'thread'
require 'rubygems'

$: << File.expand_path(File.dirname(__FILE__))

require 'theatre/version'
require 'theatre/namespace_manager'
require 'theatre/invocation'
require 'theatre/callback_definition_loader'

module Theatre

  class Theatre

    attr_reader :namespace_manager

    ##
    # Creates a new stopped Theatre. You must call start!() after you instantiate this for it to begin processing events.
    #
    # @param [Fixnum] thread_count Number of Threads to spawn when started.
    #
    def initialize(thread_count=6)
      @thread_count      = thread_count
      @started           = false
      @namespace_manager = ActorNamespaceManager.new
      @thread_group      = ThreadGroup.new
      @master_queue      = Queue.new
      @loader_mixins     = []
    end

    ##
    # Send a message to this Theatre for asynchronous processing.
    #
    # @param [String] namespace The namespace to which the payload should be sent
    # @param [Object] payload The actual content to be sent to the callback. Optional.
    # @return [Array<Theatre::Invocation>] An Array of Invocation objects
    # @raise Theatre::NamespaceNotFound Raised when told to enqueue an unrecognized namespace
    #
    def trigger(namespace, payload=:argument_undefined)
      @namespace_manager.callbacks_for_namespaces(namespace).map do |callback|
        invocation = if payload.equal?(:argument_undefined)
          Invocation.new(namespace, callback)
        else
          Invocation.new(namespace, callback, payload)
        end
        invocation.queued
        @master_queue << invocation
        invocation
      end
    end

    ##
    # Send a message to this Theatre for synchronous processing. The execution of this will not go through this Theatre's
    # Thread pool. If an error occurred in any of callbacks, the Exception object will be placed in the returned Array
    # instead for you to act upon.
    #
    # @param [String] namespace The namespace to which the payload should be sent
    # @param [Object] payload The actual content to be sent to the callback. Optional.
    # @return [Array] An Array containing each callback's return value (or Exception raised, if any) when given the payload
    # @raise Theatre::NamespaceNotFound Raised when told to enqueue an unrecognized namespace
    #
    def trigger_immediately(namespace, payload=:argument_undefined)
      @namespace_manager.callbacks_for_namespaces(namespace).map do |callback|
        begin
          invocation = if payload.equal?(:argument_undefined)
            callback.call
          else
            callback.call payload
          end
        rescue => captured_error_to_be_returned
          captured_error_to_be_returned
        end
      end
    end

    def load_events_code(code, *args)
      loader = CallbackDefinitionLoader.new(self, *args)
      loader.load_events_code code
    end

    def load_events_file(file, *args)
      loader = CallbackDefinitionLoader.new(self, *args)
      loader.load_events_file file
    end

    def register_namespace_name(*args)
      @namespace_manager.register_namespace_name(*args)
    end

    def register_callback_at_namespace(*args)
      @namespace_manager.register_callback_at_namespace(*args)
    end

    def register_loader_mixin(mod)
      @loader_mixins << mod
    end

    def join
      @thread_group.list.each do |thread|
        begin
          thread.join
        rescue
          # Ignore any exceptions
        end
      end
    end

    ##
    # Starts this Theatre.
    #
    # When this method is called, the Threads are spawned and begin pulling messages off this Theatre's master queue.
    #
    def start!
      return false if @thread_group.list.any? # Already started
      @started_time = Time.now
      @thread_count.times do
        @thread_group.add Thread.new(&method(:thread_loop))
      end
    end

    ##
    # Notifies all Threads for this Theatre to stop by sending them special messages. Any messages which were queued and
    # untriggered when this method is received will still be processed. Note: you may start this Theatre again later once it
    # has been stopped.
    #
    def graceful_stop!
      @thread_count.times { @master_queue << :THEATRE_SHUTDOWN! }
      @started_time = nil
    end

    protected

    def thread_loop
      loop do
        begin
          next_invocation = @master_queue.pop
          return :stopped if next_invocation.equal? :THEATRE_SHUTDOWN!
          next_invocation.start
        rescue Exception => error
          Adhearsion::Events.trigger(['exception'], error)
        end
      end
    end

  end
end
