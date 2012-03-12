# encoding: utf-8

require 'logging'

module Adhearsion
  module Logging

    LOG_LEVELS = %w(TRACE DEBUG INFO WARN ERROR FATAL)

    METHOD = :logger

    class << self

      ::Logging.color_scheme 'bright',
        :levels => {
          :debug => :magenta,
          :info  => :green,
          :warn  => :yellow,
          :error => :red,
          :fatal => [:white, :on_red]
        },
        :date     => [:bold, :blue],
        :logger   => :cyan

      def adhearsion_pattern
        '[%d] %-5l %c: %m\n'
      end

      # Silence Adhearsion's logging, printing only FATAL messages
      def silence!
        self.logging_level = :fatal
      end

      # Restore the default configured logging level
      def unsilence!
        self.logging_level = Adhearsion.config.platform.logging['level']
      end

      # Toggle between the configured log level and :trace
      # Useful for debugging a live Adhearsion instance
      def toggle_trace!
        if level == ::Logging.level_num(Adhearsion.config.platform.logging['level'])
          logger.warn "Turning TRACE logging ON."
          self.level = :trace
        else
          logger.warn "Turning TRACE logging OFF."
          self.level = Adhearsion.config.platform.logging['level']
        end
      end

      # Close logfiles and reopen them.  Useful for log rotation.
      def reopen_logs
        logger.info "Closing logfiles."
        ::Logging.reopen
        logger.info "Logfiles reopened."
      end

      def init
        ::Logging.init LOG_LEVELS

        LOG_LEVELS.each do |level|
          Adhearsion::Logging.const_defined?(level) or Adhearsion::Logging.const_set(level, ::Logging::LEVELS[::Logging.levelify(level)])
        end
      end

      def start(_appenders = nil, level = :info, formatter = nil)
        ::Logging.logger.root.appenders = _appenders.nil? ? default_appenders : _appenders

        ::Logging.logger.root.level = level

        formatter = formatter if formatter
      end

      def default_appenders
        [::Logging.appenders.stdout(
           'stdout',
           :layout => ::Logging.layouts.pattern(
             :pattern => adhearsion_pattern,
             :color_scheme => 'bright'
           ),
           :auto_flushing => 2,
           :flush_period => 2
         )]
      end

      def logging_level=(new_logging_level)
        ::Logging.logger.root.level = new_logging_level
      end

      alias :level= :logging_level=

      def logging_level
        ::Logging.logger.root.level
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
        ::Logging.logger.root.appenders.each do |appender|
          appender.layout = formatter
        end
      end

      alias :layout= :formatter=

      def formatter
        ::Logging.logger.root.appenders.first.layout
      end

      alias :layout :formatter

    end

    init unless ::Logging.const_defined? :MAX_LEVEL_LENGTH
  end
end
