require 'log4r'

module Adhearsion
  module Logging
    
    @@logging_level_lock = Mutex.new
    
    class << self
      
      def silence!
        self.logging_level = :fatal
      end

      def unsilence!
        self.logging_level = :info
      end
      
      def logging_level=(new_logging_level)
        new_logging_level = Log4r.const_get(new_logging_level.to_s.upcase)
        @@logging_level_lock.synchronize do
          @@logging_level = new_logging_level
          Log4r::Logger.each_logger do |logger|
            logger.level = new_logging_level
          end
        end
      end
      
      def logging_level
        @@logging_level_lock.synchronize do
          return @@logging_level ||= Log4r::INFO
        end
      end
    end
    
    class AdhearsionLogger < Log4r::Logger
      
      def initialize(*args)
        super
        self.outputters = Adhearsion::Logging::DefaultAdhearsionOutputter
      end
      
      def method_missing(logger_name, *args, &block)
        define_logging_method(logger_name, self.class.new(logger_name.to_s))
        send(logger_name, *args, &block)
      end
      
      private
      
      def define_logging_method(name, logger)
        # Can't use Module#define_method() because blocks in Ruby 1.8.x can't
        # have their own block arguments.
        self.class.class_eval(<<-CODE, __FILE__, __LINE__)
          def #{name}(*args, &block)
            logger = Log4r::Logger['#{name}']
            if args.any? || block_given?
              logger.info(*args, &block)
            else
              logger
            end
          end
        CODE
      end
      
    end
    
    DefaultAdhearsionOutputter = Log4r::Outputter.stdout
    DefaultAdhearsionLogger    = AdhearsionLogger.new 'ahn'
    
  end
end

def ahn_log(*args)
  if args.any?
    Adhearsion::Logging::DefaultAdhearsionLogger.info(*args)
  else
    Adhearsion::Logging::DefaultAdhearsionLogger
  end
end
