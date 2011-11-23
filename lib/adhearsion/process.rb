require 'state_machine'
require 'singleton'

module Adhearsion
  class Process
    include Singleton

    state_machine :initial => :booting do
      before_transition :log_state_change
      after_transition :on => :shutdown, :do => :request_stop
      after_transition :on => :stopped, :do => :final_shutdown

      event :booted do
        transition :booting => :running
      end

      event :shutdown do
        transition :running => :stopping
      end

      # On second shutdown request, start rejecting new calls.
      # This corresponds to the admin pressing CTRL+C twice.
      event :shutdown do
        transition :stopping => :rejecting
      end

      # On third shutdown request, hang up all active calls.
      # This corresponds to the admin pressing CTRL+C three times.
      event :shutdown do
        transition :rejecting => :stopped
      end

      event :hard_shutdown do
        transition [:running, :stopping] => :rejecting
      end

      event :stop do
        transition :rejecting => :stopped
      end

      event :force_stop do
        transition all => :stopped
      end

      event :reset do
        transition all => :booting
      end
    end

    def initialize
      super
    end

    def log_state_change(transition)
      event, from, to = transition.event, transition.from_name, transition.to_name
      logger.info "Adhearsion transitioning from #{from} to #{to} with #{Adhearsion.active_calls.size} active calls."
    end

    def request_stop
      Events.trigger_immediately :stop_requested
    end

    def final_shutdown
      Adhearsion.active_calls.each do |call|
        call.hangup rescue nil
      end
      Events.trigger_immediately :shutdown
    end

    def self.method_missing(method_name, *args, &block)
      instance.send method_name, *args, &block
    end
  end
end