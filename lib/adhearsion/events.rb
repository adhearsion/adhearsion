# encoding: utf-8

require 'has_guarded_handlers'
require 'singleton'
require 'concurrent/executor/thread_pool_executor'

module Adhearsion
  module Events

    class Handler
      include HasGuardedHandlers
      include Singleton

      def call_handler(handler, guards, event)
        super
        throw :pass
      end

      alias :register_callback :register_handler

      def method_missing(method_name, *args, &block)
        register_handler method_name, *args, &block
      end

      def respond_to_missing?(method_name, include_private = false)
        true
      end
    end

    def self.__handle(type, object)
      Handler.instance.trigger_handler type, object
    rescue => ex
      raise(ex) if type == :exception
      trigger :exception, ex
    end

    class << self
      def method_missing(method_name, *args, &block)
        Handler.instance.send method_name, *args, &block
      end

      def respond_to_missing?(method_name, include_private = false)
        Handler.instance.respond_to? method_name, include_private
      end

      def draw(&block)
        Handler.instance.instance_exec(&block)
      end

      def trigger(type, object = nil)
        executor.post { __handle(type, object) }
      end

      def trigger_immediately(type, object = nil)
        __handle type, object
      end

      def executor
        @_executor ||= init
      end
      private :executor

      def init
        size = Adhearsion.config.core.event_threads
        logger.debug "Initializing event worker pool of size #{size}"
        Concurrent::ThreadPoolExecutor.new(min_threads: size, max_threads: size, auto_terminate: false)
      end

      def refresh!
        clear
        init
      end

      def clear
        @_executor.kill if @_executor
        @_executor = nil
        Handler.instance.clear_handlers
      end

    end

  end
end
