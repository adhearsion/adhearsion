require 'logging'

module Adhearsion
  class Initializer
    class Logging
      class << self

        def adhearsion_pattern
          '[%d] %-5l %c: %m\n'
        end

        def start

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

          ::Logging.appenders.stdout(
            'stdout',
            :layout => ::Logging.layouts.pattern(
              :pattern => adhearsion_pattern,
              :color_scheme => 'bright'
            )
          )

          ::Logging.appenders.file(
            'adhearsion.log',
            :layout => ::Logging.layouts.pattern(
              :pattern => adhearsion_pattern
            )
          )

          ::Logging.logger.root.appenders = ['stdout', 'adhearsion.log']

          ::Logging.logger.root.level = :info
        end
      end
    end
  end
end