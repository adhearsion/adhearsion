require 'logging'

module Adhearsion
  class Initializer
    class Logging
      class << self

        def start(_appenders = nil, level = :info)

          ::Logging.logger.root.appenders = _appenders.nil? ? appenders : _appenders

          ::Logging.logger.root.level = level
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