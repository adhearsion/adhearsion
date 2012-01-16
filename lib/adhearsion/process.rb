require 'state_machine'
require 'singleton'

module Adhearsion
  class Process
    include Singleton

    state_machine :initial => :booting do
      before_transition :log_state_change
      after_transition :on => :shutdown, :do => :request_stop
      after_transition any => :stopped, :do => :final_shutdown
      after_transition :on => :force_stop, :do => :die_now!

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
      end

      event :hard_shutdown do
        transition [:running, :stopping] => :rejecting
      end

      event :stop do
        transition :rejecting => :stopped
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
      logger.info "Transitioning from #{from} to #{to} with #{Adhearsion.active_calls.size} active calls."
    end

    def request_stop
      Events.trigger_immediately :stop_requested
      important_threads << Thread.new { stop_when_zero_calls }
    end

    def final_shutdown
      Adhearsion.active_calls.each do |call|
        call.hangup
      end
      # This should shut down any remaining threads.  Once those threads have
      # stopped, important_threads will be empty and the process will exit
      # normally.
      Events.trigger_immediately :shutdown
    end

    def stop_when_zero_calls
      until Adhearsion.active_calls.count == 0
        logger.trace "Stop requested but we still have #{Adhearsion.active_calls.count} active calls."
        sleep 0.2
      end
      final_shutdown
    end

    def die_now!
      ::Process.exit 1
    end

    def self.method_missing(method_name, *args, &block)
      instance.send method_name, *args, &block
    end
  end
end
