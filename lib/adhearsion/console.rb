require 'pry'

module Adhearsion
  class Console
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

    attr_accessor :input

    def initialize
      @input = $stdin
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

    def shutdown
      Process.shutdown!
    end

    alias :exit :shutdown

    def calls
      Adhearsion.active_calls
    end

    def use(call = nil)
      case call
      when Call
        interact_with_call call
      when String
        if call = calls[call]
          interact_with_call call
        else
          logger.error "An active call with that ID does not exist"
        end
      when nil
        if calls.size == 1
          interact_with_call calls.values.first
        else
          puts "Please choose a call:"
          current_calls = calls.values
          current_calls.each_with_index do |call, index|
            puts "#{index}. #{call.id}"
          end
          index = input.gets.chomp.to_i
          call = current_calls[index]
          interact_with_call call
        end
      else
        raise ArgumentError
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

    private

    def interact_with_call(call)
      Pry.prompt = [ proc { "AHN<#{call.id}> " },
                     proc { "AHN<#{call.id}? " }  ]

      begin
        controller = InteractiveController.new call
        call.exclusive_controller = controller
        CallController.exec controller
      ensure
        call.exclusive_controller = nil
      end
    end

    class InteractiveController < CallController
      def run
        pry
      end
    end
  end
end
