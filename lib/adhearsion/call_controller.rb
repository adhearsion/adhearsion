module Adhearsion
  class CallController
    extend ActiveSupport::Autoload

    autoload :Dial
    autoload :Input
    autoload :Output
    autoload :Record
    autoload :Menu
    autoload :Utility

    include Dial
    include Input
    include Output
    include Record
    include Menu
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
    delegate :write_and_await_response, :answer, :reject, :mute, :unmute, :join, :to => :call

    def initialize(call, metadata = nil, &block)
      @call, @metadata, @block = call, metadata || {}, block
    end

    def execute!(*options)
      execute_callbacks :before_call
      run
    rescue Hangup
      logger.info "Call was hung up"
    rescue SyntaxError, StandardError => e
      Events.trigger :exception, e
    ensure
      after_call
    end

    def run
      instance_exec &block if block
    end

    def invoke(controller_class, metadata = nil)
      controller = controller_class.new call, metadata
      controller.run
    end

    def pass(controller_class, metadata = nil)
      throw :pass_controller, controller_class.new(call, metadata)
    end

    def execute_callbacks(type)
      self.class.callbacks[type].each do |callback|
        catching_standard_errors do
          instance_exec &callback
        end
      end
    end

    def after_call
      @after_call ||= execute_callbacks :after_call
    end

    def hangup(headers = nil)
      hangup_response = call.hangup headers
      after_call unless hangup_response == false
    end

    def execute_component_and_await_completion(component)
      write_and_await_response component

      yield component if block_given?

      complete_event = component.complete_event
      raise StandardError, complete_event.reason.details if complete_event.reason.is_a? Punchblock::Event::Complete::Error
      component
    end
  end#class
end
