# gem 'theatre', '>= 0.8.0'
require 'theatre'

module Adhearsion
  module Events
    
    class << self
      
      def framework_theatre
        defined?(@@framework_theatre) ? @@framework_theatre : reinitialize_theatre!
      end
      
      def reinitialize_theatre!
        @@framework_theatre.gracefully_stop! if defined? @@framework_theatre
      rescue
        # Recover and reinitalize
      ensure
        # TODO: Extract number of threads to use from AHN_CONFIG
        @@framework_theatre = Theatre::Theatre.new
        return @@framework_theatre
      end
      
    end
    
  end
end
