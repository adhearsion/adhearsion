require 'log4r'

module Adhearsion
  module Logging
    
    class AdhearsionLogger < Log4r::Logger

      def initialize(*args)
        super
        self.outputters = Adhearsion::Logging::DefaultAdhearsionOutputter
      end
      
      def method_missing(logger_name, *args)
        Log4r::Logger[logger_name.to_s] || self.class.new(logger_name.to_s)
      end
      
    end
    
    DefaultAdhearsionOutputter = Log4r::Outputter.stdout
    DefaultAdhearsionLogger    = AdhearsionLogger.new 'ahn'
    
    def self.silence!
      DefaultAdhearsionLogger.level = Log4r::FATAL
    end
    
    def self.unsilence!
      DefaultAdhearsionLogger.level = Log4r::INFO
    end
    
  end
end

def ahn_log(*args)
  if args.any?
    Adhearsion::Logging::DefaultAdhearsionLogger.info(*args)
  else
    Adhearsion::Logging::DefaultAdhearsionLogger
  end
end
