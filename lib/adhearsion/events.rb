require 'theatre'

module Adhearsion
  module Events

    extend HasGuardedHandlers

    Message = Struct.new :type, :object

    class << self

      def queue
        defined?(@@queue) ? @@queue : reinitialize_queue!
      end

      def trigger(type, object = nil)
        queue.push_async Message.new(type, object)
      end

      def trigger_immediately(type, object = nil)
        queue.push_immediately Message.new(type, object)
      end

      def reinitialize_queue!
        GirlFriday.shutdown! if defined? @@queue
        # TODO: Extract number of threads to use from AHN_CONFIG
        @@queue = GirlFriday::WorkQueue.new 'main_queue', :error_handler => ErrorHandler do |message|
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
    end

    class ErrorHandler
      def handle(exception)
        Events.trigger :exception, exception
      end
    end

  end
end
