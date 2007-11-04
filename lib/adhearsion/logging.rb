require 'logger'
module Adhearsion
  module Logging
    
    SEVERITIES = [:debug, :info, :warn, :error, :fatal]
    REGISTERED_LOGGERS = []
    
    @@severity = CONFIG['logging_severity'] || SEVERITIES.size - 1
    @@severity_lock = Mutex.new
    
    #@@silenced = false
    @@default_logger = nil
    
    # Arguments are the same as a normal Logger.
    # First argument must be an IO device or String into which all
    # logs are written. Other two arguments are log rotation and
    # log size respectively. They're likely not used quite so much.
    # If not arguments are given, STDOUT is used by default.
    class StandardLogger < Logger
      def initialize(*args)
        args = [$stdout] if args.empty?
        super(*args)
        self.formatter = lambda {}
      end
    end
    
    def self.remove_logger(logger)
      REGISTERED_LOGGERS.synchronize do
        if logger == :default then REGISTERED_LOGGERS.delete @@default_logger
        elsif logger == :all then REGISTERED_LOGGERS.clear
        else REGISTERED_LOGGERS.delete logger
        end
      end
    end

    Adhearsion::Hooks::TearDown.create_hook do
      REGISTERED_LOGGERS.each { |l| l.close if l.respond_to?(:close) }
    end

    # Lets helper authors and Adhearsion developers specify a logging endpoint.
    # The only requirement of a logger is that it implements each of the
    # methods defined in SEVERITIES. A logging endpoint could be STDOUT,
    # a log file, Jabber screen name, IRC channel, or a dispatched email.
    def self.register_logger(logger)
      REGISTERED_LOGGERS.synchronize do
        logger = @@default_logger = StandardLogger.new if logger == :default
        deviance = SEVERITIES.reject {|x| logger.respond_to? x }
        raise ImproperLoggerException, "Logger must implement the #{deviance.to_sentence} method(s)" if deviance.any?
        REGISTERED_LOGGERS << logger
      end
    end

    def self.registered_loggers
      REGISTERED_LOGGERS
    end
    
    # def self.silence!
    # end
    # def self.unsilence!
    # end
    # def silenced?
    # end

    # Provides a safe setter for the logging severity. Its one argument should
    # be a symbol matching something in the SEVERITIES array. The symbol
    # provided corresponds to the *minimum* logging level. For example, if
    # this method were invoked as such
    #
    #     logging_severity = :warn
    # 
    # Then only calls to fatal(), error(), and warn() would be processed.
    # Calls to log() or debug() would both be ignored.
    def self.severity=(sev)
      SEVERITIES.synchronize do
        sev = SEVERITIES.index sev if sev.is_a? Symbol
        raise "Specified severity #{sev} not valid!" unless sev
        @@severity_lock.synchronize { @@severity = sev }
      end
    end
    
    # Simply returns the current logging severity
    def self.severity() SEVERITIES[@@severity] end

    def self.log!(msg, severity, method)
      REGISTERED_LOGGERS.synchronize do
        @@severity_lock.synchronize do
          if @@severity >= severity
            REGISTERED_LOGGERS.each do |logger|
              logger.__send__ method, msg
            end
            msg
          else false
          end
        end
      end
    end
    
    class ImproperLoggerException < Exception; end
    
    module LoggingMethods
      # Used in development phases to log developer-related information.
      def debug(msg)
        Adhearsion::Logging.log! msg, 4, :debug
      end

      # The standard logging method. Give it a message to log.
      def info(msg)
        Adhearsion::Logging.log! msg, 3, :info
      end
      alias log info

      # For reporting messages about potentially hazardous issues.
      def warn(msg)
        Adhearsion::Logging.log! msg, 2, :warn
      end

      # Will Robinson, we've had an error! Let's report it!  You may
      # wish to have these errors emailed to the administrator when
      # they occur.
      def error(msg)
        Adhearsion::Logging.log! msg, 1, :error
      end

      # This is for seriously bad errors. You may wish to have
      # these errors emailed to the administrator when they occur.
      def fatal(msg)
        Adhearsion::Logging.log! msg, 0, :fatal
      end
      
    end
  end
end