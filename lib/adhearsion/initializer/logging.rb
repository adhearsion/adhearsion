require 'logging'

module Adhearsion
  class Initializer
    class Logging
      class << self

        def start(_appenders = nil, level = :info, formatter = nil)
          ::Logging.init Adhearsion::Logging::LOG_LEVELS

          ::Logging.logger.root.appenders = _appenders.nil? ? appenders : _appenders

          ::Logging.logger.root.level = level

          ::Logging.logger.root.appenders.each do |appender|
            appender.layout = formatter
          end unless formatter.nil?
        end

        # default appenders
        def appenders
          @appenders ||= [::Logging.appenders.stdout(
                            'stdout',
                            :layout => ::Logging.layouts.pattern(
                              :pattern => Adhearsion::Logging.adhearsion_pattern,
                              :color_scheme => 'bright'
                            )
                          )]
        end
      end
    end
  end
end