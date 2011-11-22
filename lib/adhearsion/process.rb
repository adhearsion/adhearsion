require 'state_machine'
require 'singleton'

module Adhearsion
  class Process
    include Singleton
    
    state_machine :initial => :booting do
      before_transition :log_state_change
      
      event :booted do
        transition :booting => :running
      end
      
      event :shutdown do
        transition :running => :stopping
      end
      
      event :final_shutdown do
        transition [:running, :stopping] => :rejecting
      end
      
      event :stop do
        transition :rejecting => :stopped
      end
      
      event :stop! do
        transition all => :stopped
      end
    end
    
    def initialize
      super
    end
    
    def log_state_change(transition)
      event, from, to = transition.event, transition.from_name, transition.to_name
      puts "Adhearsion transitioning from #{from} to #{to}."
    end
    
    def self.method_missing(method_name, *args, &block)
      instance.send method_name, *args, &block
    end
  end
end