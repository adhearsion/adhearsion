# encoding: utf-8

module Adhearsion
  module Translator
    class Asterisk
      module AMIErrorConverter
        def self.convert(result = ->(e) { raise ChannelGoneError, e.message } )
          yield
        rescue RubyAMI::Error => e
          case e.message
          when 'No such channel', /Channel (\S+) does not exist./, /channel not up/, /Channel does not exist/
            result.call e if result
          else
            raise e
          end
        end
      end
    end
  end
end
