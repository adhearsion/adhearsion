module Adhearsion
  class Events

    include HasGuardedHandlers

    Message = Struct.new :type, :object

    class << self
      def method_missing(method_name, *args, &block)
        instance.send method_name, *args, &block
      end

      def respond_to?(method_name)
        instance.respond_to?(method_name) || super
      end

      def instance
        @@instance || refresh!
      end

      def refresh!
        @@instance = new
      end
    end

    refresh!

    def queue
      @queue || reinitialize_queue!
    end

    def trigger(type, object = nil)
      queue.push_async Message.new(type, object)
    end

    def trigger_immediately(type, object = nil)
      queue.push_immediately Message.new(type, object)
    end

    def reinitialize_queue!
      GirlFriday.shutdown! if @queue
      # TODO: Extract number of threads to use from Adhearsion.config
      @queue = GirlFriday::WorkQueue.new 'main_queue', :error_handler => ErrorHandler do |message|
        begin
          handle_message message
        rescue Exception => e
          ErrorHandler.new.handle e
        end
      end
    end

    def handle_message(message)
      trigger_handler message.type, message.object
    end

    def draw(&block)
      instance_exec &block
    end

    def method_missing(method_name, *args, &block)
      register_handler method_name, *args, &block
    end

    def respond_to?(method_name)
      return true if @handlers && @handlers.has_key?(method_name)
      super
    end

    alias :register_callback :register_handler

    private

    def call_handler(handler, guards, event)
      super && throw(:pass)
    end

    class ErrorHandler
      def handle(exception)
        Events.trigger :exception, exception
      end
    end

  end
end
