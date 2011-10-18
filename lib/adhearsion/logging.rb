require 'logging'

module Adhearsion
  module Logging

    LOG_LEVELS = %w(TRACE DEBUG INFO WARN ERROR FATAL)

    METHOD = :logger

    class << self

      ::Logging.color_scheme( 'bright',
        :levels => {
          :info  => :green,
          :warn  => :yellow,
          :error => :red,
          :fatal => [:white, :on_red]
        },
        :date => :blue,
        :logger => :cyan,
        :message => :magenta
      )

      def adhearsion_pattern
        '[%d] %-5l %c: %m\n'
      end

      def silence!
        self.logging_level = :fatal
      end

      def unsilence!
        self.logging_level = :info
      end

      def reset
        ::Logging.reset
      end

      def start
        ::Logging.init(LOG_LEVELS) 
        ::Logging.logger.root.appenders = [::Logging.appenders.stdout('stdout')]
        self.send(:_set_formatter, ::Logging::Layouts.basic({:format_as => :string, :backtrace => true}))
        
        LOG_LEVELS.each{|level|
          Adhearsion::Logging.const_defined?(level) or Adhearsion::Logging.const_set(level, ::Logging::LEVELS[::Logging.levelify(level)])
        }
      end

      def logging_level=(new_logging_level)
        ::Logging::Logger[:root].level = new_logging_level
      end

      alias :level= :logging_level=

      def logging_level
        ::Logging::Logger[:root].level
      end

      def get_logger(logger_name)
        ::Logging::Logger[logger_name]
      end

      alias :level :logging_level

      def sanitized_logger_name(name)
        name.to_s.gsub(/\W/, '').downcase
      end

      def outputters=(outputters)
        ::Logging.logger.root.appenders = outputters
      end

      alias :appenders= :outputters=

      def outputters
        ::Logging.logger.root.appenders
      end

      alias :appenders :outputters

      def formatter=(formatter)
        _set_formatter(formatter)
      end

      alias :layout= :formatter=

      def formatter
        ::Logging.logger.root.appenders.first.layout
      end

      alias :layout :formatter

      private

      def _set_formatter(formatter)
        ::Logging.logger.root.appenders.each do |appender|
          appender.layout = formatter
        end
      end

    end

    unless ::Logging.const_defined? :MAX_LEVEL_LENGTH
      start
    end

  end
end
