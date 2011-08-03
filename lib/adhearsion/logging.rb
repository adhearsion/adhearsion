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
      alias :level= :logging_level=

      def logging_level(level = nil)
        return self.logging_level= level unless level.nil?
        @@logging_level_lock.synchronize do
          return @@logging_level ||= Log4r::INFO
        end
      end
      alias :level :logging_level
    end

    class AdhearsionLogger < Log4r::Logger

      @@outputters = [Log4r::Outputter.stdout]

      class << self
        def sanitized_logger_name(name)
          name.to_s.gsub(/\W/, '').downcase
        end

        def outputters
          @@outputters
        end

        def outputters=(other)
          @@outputters = other
        end

        def formatters
          @@outputters.map &:formatter
        end

        def formatters=(other)
          other.each_with_index do |formatter, i|
            outputter = @@outputters[i]
            outputter.formatter = formatter if outputter
          end
        end
      end

      def initialize(*args)
        super
        redefine_outputters
      end

      def redefine_outputters
        self.outputters = @@outputters
      end

      def method_missing(logger_name, *args, &block)
        define_logging_method logger_name, self.class.new(logger_name.to_s)
        send self.class.sanitized_logger_name(logger_name), *args, &block
      end

      private

      def define_logging_method(name, logger)
        # Can't use Module#define_method() because blocks in Ruby 1.8.x can't
        # have their own block arguments.
        self.class.class_eval(<<-CODE, __FILE__, __LINE__)
          def #{self.class.sanitized_logger_name name}(*args, &block)
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

    DefaultAdhearsionLogger = AdhearsionLogger.new 'ahn'

  end
end

def ahn_log(*args)
  if args.any?
    Adhearsion::Logging::DefaultAdhearsionLogger.info(*args)
  else
    Adhearsion::Logging::DefaultAdhearsionLogger
  end
end
