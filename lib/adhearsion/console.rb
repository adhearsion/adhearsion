require 'pry'

module Adhearsion
  class Console
    include Adhearsion
    include Singleton

    delegate :silence!, :unsilence!, :to => Adhearsion::Logging

    class << self
      ##
      # Include another external functionality into the console
      def mixin(mod)
        include mod
      end

      def method_missing(method, *args, &block)
        instance.send method, *args, &block
      end
    end

    ##
    # Start the Adhearsion console
    #
    def run
      Pry.prompt = [
                      proc do |*args|
                        obj, nest_level, pry_instance = args
                        "AHN#{'  ' * nest_level}> "
                      end,
                      proc do |*args|
                        obj, nest_level, pry_instance = args
                        "AHN#{'  ' * nest_level}? "
                      end
                    ]
      Pry.config.command_prefix = "%"
      if libedit?
        logger.error "Cannot start. You are running Adhearsion on Ruby with libedit. You must use readline for the console to work."
      else
        logger.info "Starting up..."
        @pry_thread = Thread.current
        binding.pry
      end
    end

    def stop
      return unless @pry_thread
      @pry_thread.kill
      @pry_thread = nil
      logger.info "Shutting down"
    end

    def log_level(level = nil)
      if level
        Adhearsion::Logging.level = level
      else
        ::Logging::LEVELS.invert[Adhearsion::Logging.level].to_sym
      end
    end

    def calls
      Adhearsion.active_calls
    end

    def use(call)
      unless call.is_a? Adhearsion::Call
        raise ArgumentError unless Adhearsion.active_calls[call]
        call = Adhearsion.active_calls[call]
      end
      Pry.prompt = [ proc { "AHN<#{call.channel}> " },
                     proc { "AHN<#{call.channel}? " }  ]

      # Pause execution of the thread currently controlling the call
      call.with_command_lock do
        CallWrapper.new(call).pry
      end
    end

    def libedit?
      begin
        # If NotImplemented then this might be libedit
        Readline.emacs_editing_mode
        false
      rescue NotImplementedError
        true
      end
    end

    class CallWrapper
      attr_accessor :call

      def initialize(call)
        @call = call
        extend Adhearsion::Commands.for('asterisk')
      end
    end
  end
end
