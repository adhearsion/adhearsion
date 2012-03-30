# encoding: utf-8

module Adhearsion
  class CallController
    extend ActiveSupport::Autoload

    autoload :Dial
    autoload :Input
    autoload :Output
    autoload :Record
    autoload :Utility

    include Dial
    include Input
    include Output
    include Record
    include Utility

    class_attribute :callbacks

    self.callbacks = {:before_call => [], :after_call => []}

    self.callbacks.keys.each do |name|
      class_eval <<-STOP
        def self.#{name}(method_name = nil, &block)
          callback = if method_name
            lambda { send method_name }
          elsif block
            block
          end
          self.callbacks = self.callbacks.dup.tap { |cb| cb[:#{name}] += Array(callback) }
        end
      STOP
    end

    class << self
      def exec(controller)
        new_controller = catch :pass_controller do
          controller.execute!
          nil
        end

        exec new_controller if new_controller
      end

      ##
      # Include another module into all CallController classes
      def mixin(mod)
        include mod
      end
    end

    attr_reader :call, :metadata, :block

    delegate :[], :[]=, :to => :@metadata
    delegate :variables, :logger, :to => :call

    def initialize(call, metadata = nil, &block)
      @call, @metadata, @block = call, metadata || {}, block
    end

    def execute!(*options) # :nodoc:
      call.register_controller! self
      execute_callbacks :before_call
      run
    rescue Call::Hangup
      logger.info "Call was hung up"
    rescue SyntaxError, StandardError => e
      Events.trigger :exception, [e, logger]
    ensure
      after_call
      logger.debug "Finished executing controller #{self.inspect}"
    end

    def run
      instance_exec(&block) if block
    end

    def invoke(controller_class, metadata = nil)
      controller = controller_class.new call, metadata
      controller.run
    end

    def pass(controller_class, metadata = nil)
      throw :pass_controller, controller_class.new(call, metadata)
    end

    def execute_callbacks(type) # :nodoc:
      self.class.callbacks[type].each do |callback|
        catching_standard_errors do
          instance_exec(&callback)
        end
      end
    end

    def after_call # :nodoc:
      @after_call ||= execute_callbacks :after_call
    end

    def hangup(headers = nil)
      block_until_resumed
      hangup_response = call.hangup headers
      after_call unless hangup_response == false
    end

    def write_and_await_response(command)
      block_until_resumed
      call.write_and_await_response command
    end

    def execute_component_and_await_completion(component)
      write_and_await_response component

      yield component if block_given?

      complete_event = component.complete_event
      raise Adhearsion::Error, [complete_event.reason.details, component.inspect].join(": ") if complete_event.reason.is_a? Punchblock::Event::Complete::Error
      component
    end

    def answer(*args)
      block_until_resumed
      call.answer(*args)
    end

    def reject(*args)
      block_until_resumed
      call.reject(*args)
    end

    def mute(*args)
      block_until_resumed
      call.mute(*args)
    end

    def unmute(*args)
      block_until_resumed
      call.unmute(*args)
    end

    def join(target, options = {})
      async = if target.is_a?(Hash)
        target.delete :async
      else
        options.delete :async
      end
      block_until_resumed
      join_command = call.join target, options
      waiter = join_command.call_id || join_command.mixer_name
      if async
        call.wait_for_joined waiter
      else
        call.wait_for_unjoined waiter
      end
    end

    def block_until_resumed # :nodoc:
      instance_variable_defined?(:@pause_latch) && @pause_latch.wait
    end

    def pause! # :nodoc:
      @pause_latch = CountDownLatch.new 1
    end

    def resume! # :nodoc:
      return unless @pause_latch
      @pause_latch.countdown!
      @pause_latch = nil
    end

    def inspect
      "#<#{self.class} call=#{call.id}, metadata=#{metadata.inspect}>"
    end
  end#class
end
