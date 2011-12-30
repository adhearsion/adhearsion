module Adhearsion
  class CallController
    extend ActiveSupport::Autoload

    autoload :Conference
    autoload :Dial
    autoload :Input
    autoload :Output
    autoload :Record
    autoload :Menu
    autoload :Utility

    include Punchblock::Command
    include Punchblock::Component
    include Conference
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

    def self.exec(controller, fresh_call = true)
      return unless controller

      new_controller = catch :pass_controller do
        controller.skip_accept! unless fresh_call
        controller.execute
      end

      exec new_controller, false
    end

    attr_reader :call, :metadata

    delegate :[], :[]=, :to => :@metadata

    def initialize(call)
      @call = call
      @metadata = {}
      setup
    end

    def setup
      Plugin.add_dialplan_methods self if Plugin
      call.define_variable_accessors self
    end

    def execute(*options)
      execute_callbacks :before_call
      accept if auto_accept?
      run
    rescue Hangup
      logger.info "Call was hung up"
    rescue SyntaxError, StandardError => e
      Events.trigger :exception, e
    ensure
      after_call
    end

    def run
    end

    def invoke(controller_class)
      controller = controller_class.new call
      controller.run
    end

    def pass(controller_class)
      throw :pass_controller, controller_class.new(call)
    end

    def execute_callbacks(type)
      self.class.callbacks[type].each do |callback|
        catching_standard_errors do
          instance_exec &callback
        end
      end
    end

    def skip_accept!
      @skip_accept = true
    end

    def skip_accept?
      @skip_accept || false
    end

    def auto_accept?
      Adhearsion.config.platform.automatically_accept_incoming_calls && !skip_accept?
    end

    def after_call
      @after_call ||= execute_callbacks :after_call
    end

    def variables
      call.variables
    end

    def logger
      call.logger
    end

    def accept(headers = nil)
      call.accept headers
    end

    def answer(headers = nil)
      call.answer headers
    end

    def reject(reason = :busy, headers = nil)
      call.reject reason, headers
    end

    def hangup(headers = nil)
      hangup_response = call.hangup! headers
      after_call unless hangup_response == false
    end

    def mute
      write_and_await_response ::Punchblock::Command::Mute.new
    end

    def unmute
      write_and_await_response ::Punchblock::Command::Unmute.new
    end

    def write_and_await_response(command, timeout = nil)
      call.write_and_await_response command, timeout
    end
    alias :execute_component :write_and_await_response

    def execute_component_and_await_completion(component)
      write_and_await_response component

      yield component if block_given?

      complete_event = component.complete_event
      raise StandardError, complete_event.reason.details if complete_event.reason.is_a? Punchblock::Event::Complete::Error
      component
    end
  end#class
end
