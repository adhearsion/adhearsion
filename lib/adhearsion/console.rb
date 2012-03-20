# encoding: utf-8

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
      set_prompt
      Pry.config.command_prefix = "%"
      if libedit?
        logger.error "Cannot start. You are running Adhearsion on Ruby with libedit. You must use readline for the console to work."
      else
        logger.info "Launching Adhearsion Console"
        @pry_thread = Thread.current
        pry
        logger.info "Adhearsion Console exiting"
      end
    end

    def stop
      return unless instance_variable_defined?(:@pry_thread)
      @pry_thread.kill
      @pry_thread = nil
      logger.info "Adhearsion Console shutting down"
    end

    def log_level(level = nil)
      if level
        Adhearsion::Logging.level = level
      else
        ::Logging::LEVELS.invert[Adhearsion::Logging.level].to_sym
      end
    end

    def shutdown!
      Process.shutdown!
    end

    def calls
      Adhearsion.active_calls
    end

    def take(call = nil)
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
        case calls.size
        when 0
          logger.warn "No calls active to take"
        when 1
          interact_with_call calls.values.first
        else
          puts "Please choose a call:"
          puts "# (inbound/outbound) details"
          current_calls = calls.values
          current_calls.each_with_index do |active_call, index|
            puts "#{index}: (#{active_call.is_a?(OutboundCall) ? 'o' : 'i' }) #{active_call.id} from #{active_call.from} to #{active_call.to}"
          end
          print "#> "
          index = input.gets.chomp.to_i
          call = current_calls[index]
          interact_with_call call
        end
      else
        raise ArgumentError
      end
    ensure
      set_prompt
      pry
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

    def set_prompt
      Pry.prompt = [
                proc do |*args|
                  _, nest_level, _ = args
                  "AHN#{'  ' * nest_level}> "
                end,
                proc do |*args|
                  _, nest_level, _ = args
                  "AHN#{'  ' * nest_level}? "
                end
              ]
    end

    def interact_with_call(call)
      Pry.prompt = [ proc { "AHN<#{call.id}> " },
                     proc { "AHN<#{call.id}? " }  ]

      begin
        call.pause_controllers
        CallController.exec InteractiveController.new(call)
      ensure
        logger.debug "Restoring control of call to controllers"
        call.resume_controllers
      end
    end

    class InteractiveController < CallController
      def run
        logger.debug "Starting interactive controller"
        pry
        logger.debug "Interactive controller finished"
      end

      def hangup(*args)
        super
        exit
      end
    end
  end
end
