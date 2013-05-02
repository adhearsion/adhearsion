# encoding: utf-8

require 'countdownlatch'

module Adhearsion
  class CallController
    extend ActiveSupport::Autoload

    autoload :Dial
    autoload :Input
    autoload :MenuDSL
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
      #
      # Execute a call controller, allowing passing control to another controller
      #
      # @param [CallController] controller
      #
      def exec(controller)
        controller.exec
      end

      #
      # Include another module into all CallController classes
      #
      def mixin(mod)
        include mod
      end
    end

    attr_reader :call, :metadata

    # @private
    attr_reader :block

    delegate :[], :[]=, :to => :@metadata
    delegate :variables, :to => :call

    #
    # Create a new instance
    #
    # @param [Call] call the call to operate the controller on
    # @param [Hash] metadata generic key-value storage applicable to the controller
    # @param block to execute on the call
    #
    def initialize(call, metadata = nil, &block)
      @call, @metadata, @block = call, metadata || {}, block
    end

    #
    # Execute the controller, allowing passing control to another controller
    #
    def exec(controller = self)
      new_controller = catch :pass_controller do
        controller.execute!
        nil
      end

      exec new_controller if new_controller
    end

    def bg_exec(completion_callback = nil)
      Thread.new do
        catching_standard_errors do
          exec_with_callback completion_callback
        end
      end
    end

    def exec_with_callback(completion_callback = nil)
      exec
    ensure
      completion_callback.call call if completion_callback
    end

    # @private
    def execute!(*options)
      call.async.register_controller self
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

    #
    # Invoke the block supplied when creating the controller
    #
    def run
      instance_exec(&block) if block
    end

    #
    # Invoke another controller class within this controller, returning to this context on completion.
    #
    # @param [Class] controller_class The class of controller to execute
    # @param [Hash] metadata generic key-value storage applicable to the controller
    # @return The return value of the controller's run method
    #
    def invoke(controller_class, metadata = nil)
      controller = controller_class.new call, metadata
      controller.run
    end

    #
    # Cease execution of this controller, and pass to another.
    #
    # @param [Class] controller_class The class of controller to pass to
    # @param [Hash] metadata generic key-value storage applicable to the controller
    #
    def pass(controller_class, metadata = nil)
      throw :pass_controller, controller_class.new(call, metadata)
    end

    # @private
    def execute_callbacks(type)
      self.class.callbacks[type].each do |callback|
        catching_standard_errors do
          instance_exec(&callback)
        end
      end
    end

    # @private
    def after_call
      @after_call ||= execute_callbacks :after_call
    end

    #
    # Hangup the call, and execute after_call callbacks
    #
    # @param [Hash] headers
    #
    def hangup(headers = nil)
      block_until_resumed
      call.hangup headers
      after_call
      raise Call::Hangup
    end

    # @private
    def write_and_await_response(command)
      block_until_resumed
      call.write_and_await_response command
    end

    # @private
    def execute_component_and_await_completion(component)
      write_and_await_response component

      yield component if block_given?

      complete_event = component.complete_event
      raise Adhearsion::Error, [complete_event.reason.details, component.inspect].join(": ") if complete_event.reason.is_a? Punchblock::Event::Complete::Error
      component
    end

    #
    # Answer the call
    #
    # @see Call#answer
    #
    def answer(*args)
      block_until_resumed
      call.answer(*args)
    end

    #
    # Reject the call
    #
    # @see Call#reject
    #
    def reject(*args)
      block_until_resumed
      call.reject(*args)
    end

    #
    # Mute the call
    #
    # @see Call#mute
    #
    def mute(*args)
      block_until_resumed
      call.mute(*args)
    end

    #
    # Unmute the call
    #
    # @see Call#unmute
    #
    def unmute(*args)
      block_until_resumed
      call.unmute(*args)
    end

    #
    # Join the call to another call or a mixer, and block until the call is unjoined (by hangup or otherwise).
    #
    # @param [Object] target See Call#join for details
    # @param [Hash] options
    # @option options [Boolean] :async Return immediately, without waiting for the calls to unjoin. Defaults to false.
    #
    # @see Call#join
    #
    def join(target, options = {})
      block_until_resumed
      async = (target.is_a?(Hash) ? target : options).delete :async
      join_command = call.join target, options
      waiter = join_command.call_id || join_command.mixer_name
      if async
        call.wait_for_joined waiter
      else
        call.wait_for_unjoined waiter
      end
    end

    alias :safely :catching_standard_errors

    # @private
    def block_until_resumed
      instance_variable_defined?(:@pause_latch) && @pause_latch.wait
    end

    # @private
    def pause!
      @pause_latch = CountDownLatch.new 1
    end

    # @private
    def resume!
      return unless @pause_latch
      @pause_latch.countdown!
      @pause_latch = nil
    end

    # @private
    def inspect
      "#<#{self.class} call=#{call.alive? ? call.id : ''}, metadata=#{metadata.inspect}>"
    end

    def eql?(other)
      other.instance_of?(self.class) && call == other.call && metadata == other.metadata
    end
    alias :== :eql?

    def logger
      call.logger
    rescue Celluloid::DeadActorError
      super
    end
  end#class
end
