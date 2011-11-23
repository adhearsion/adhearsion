require 'state_machine'
require 'singleton'

module Adhearsion
  class Process
    include Singleton

    state_machine :initial => :booting do
      before_transition :log_state_change
      after_transition :on => :shutdown, :do => :trigger_shutdown_events

      event :booted do
        transition :booting => :running
      end

      event :shutdown do
        transition :running => :stopping
      end

      event :shutdown do
        transition :stopping => :rejecting
      end

      event :final_shutdown do
        transition [:running, :stopping] => :rejecting
      end

      event :stop do
        transition :rejecting => :stopped
      end

      event :hard_stop do
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
      puts "Adhearsion transitioning from #{from} to #{to}."
    end

    def trigger_shutdown_events
      Events.trigger_immediately :shutdown
    end

    def self.method_missing(method_name, *args, &block)
      instance.send method_name, *args, &block
    end
  end
end