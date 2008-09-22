require 'theatre'

module Adhearsion
  module Events
    
    class << self
      
      def framework_theatre
        defined?(@@framework_theatre) ? @@framework_events_container : reinitialize_framework_events_container!
      end
      
      def reinitialize_framework_events_container!
        @@framework_theatre.gracefully_stop! if defined? @@framework_theatre
      rescue
        # Recover and reinitalize
      ensure
        AHN_CONFIG[]
        @@framework_events_container = Theatre::Theatre.new
      end
      
    end
    
  end
end
