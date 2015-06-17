# encoding: utf-8

require 'active_support/core_ext/string/filters'
require 'adhearsion/translator/asterisk/ami_error_converter'

module Adhearsion
  module Translator
    class Asterisk
      class AGICommand
        ARG_QUOTER = /["\\]/.freeze

        attr_reader :id

        def initialize(id, channel, command, *params)
          @id, @channel, @command, @params = id, channel, command, params
        end

        # @raises RubyAMI::Error, ChannelGoneError
        def execute(ami_client)
          AMIErrorConverter.convert { ami_client.send_action 'AGI', 'Channel' => @channel, 'Command' => agi_command, 'CommandID' => id }
        end

        def parse_result(event)
          parser = RubyAMI::AGIResultParser.new event['Result']
          {code: parser.code, result: parser.result, data: parser.data}
        rescue ArgumentError => e
          logger.warn "Illegal message received from Asterisk: #{e.message}"
          {code: -1, result: nil, data: nil}
        end

        private

        def agi_command
          "#{@command} #{@params.map { |arg| quote_arg(arg) }.join(' ')}".squish
        end

        # Arguments surrounded by quotes; quotes backslash-escaped.
        # See parse_args in asterisk/res/res_agi.c (Asterisk 1.4.21.1)
        def quote_arg(arg)
          '"' + arg.to_s.gsub(ARG_QUOTER) { |m| "\\#{m}" } + '"'
        end
      end
    end
  end
end
