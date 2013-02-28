# encoding: utf-8

require 'state_machine'
require 'singleton'
require 'socket'

module Adhearsion
  class Process
    include Singleton

    state_machine :initial => :booting do
      before_transition :log_state_change
      after_transition :on => :shutdown, :do => :request_stop
      after_transition any => :stopped, :do => :final_shutdown
      before_transition any => :force_stopped, :do => :die_now!

      event :booted do
        transition :booting => :running
      end

      event :shutdown do
        # On first shutdown request, flag our state but continue otherwise normally.
        transition :running => :stopping

        # On second shutdown request, start rejecting new calls.
        # This corresponds to the admin pressing CTRL+C twice.
        transition :stopping => :rejecting

        # On third shutdown request, hang up all active calls.
        # This corresponds to the admin pressing CTRL+C three times.
        transition :rejecting => :stopped

        # On the fourth shutdown request, we are probably hung.
        # Attempt no more graceful shutdown and exit as quickly as possible.
        transition :stopped => :force_stopped

        # If we are still booting, transition directly to stopped
        transition :booting => :force_stopped
      end

      event :hard_shutdown do
        transition [:running, :stopping] => :rejecting
      end

      event :stop do
        transition all => :stopped
      end

      event :force_stop do
        transition all => :force_stopped
      end

      event :reset do
        transition all => :booting
      end
    end

    attr_accessor :important_threads

    def initialize
      @important_threads = ThreadSafeArray.new
      super
    end

    def log_state_change(transition)
      event, from, to = transition.event, transition.from_name, transition.to_name
      logger.info "Transitioning from #{from} to #{to} with #{Adhearsion.active_calls.size} active calls due to #{event} event."
    end

    def request_stop
      Events.trigger_immediately :stop_requested
      important_threads << Thread.new { stop_when_zero_calls }
    end

    def final_shutdown
      Adhearsion.active_calls.each do |_, call|
        call.hangup!
      end

      # This should shut down any remaining threads.  Once those threads have
      # stopped, important_threads will be empty and the process will exit
      # normally.
      Events.trigger_immediately :shutdown

      Console.stop

      logger.info "Adhearsion shut down"
      ::Process.exit
    end

    def stop_when_zero_calls
      i = 0
      until Adhearsion.active_calls.count == 0
        logger.info "Stop requested but we still have #{Adhearsion.active_calls.count} active calls." if (i % 50) == 0
        sleep 0.2
        i += 1
      end
      final_shutdown
    end

    def die_now!
      ::Process.exit 1
    end

    def fqdn
      Socket.gethostbyname(Socket.gethostname).first
    end

    def self.method_missing(method_name, *args, &block)
      instance.send method_name, *args, &block
    end
  end
end
