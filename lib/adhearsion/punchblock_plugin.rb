# encoding: utf-8

module Adhearsion
  class PunchblockPlugin < Plugin
    extend ActiveSupport::Autoload

    autoload :Initializer

    config :punchblock do
      enabled             true             , :transform => Proc.new { |v| v == 'true' }, :desc => "Enable or disable Punchblock connectivity to a Voice server"
      platform            :xmpp            , :transform => Proc.new { |v| v.to_sym }, :desc => <<-__
        Platform punchblock shall use to connect to the Telephony provider. Currently supported values:
        - :xmpp
        - :asterisk
        - :freeswitch
      __
      username            "usera@127.0.0.1", :desc => "Authentication credentials"
      password            "1"              , :desc => "Authentication credentials"
      host                nil              , :desc => "Host punchblock needs to connect (where rayo/asterisk/freeswitch is located)"
      port                Proc.new { PunchblockPlugin.default_port_for_platform platform }, :transform => Proc.new { |v| PunchblockPlugin.validate_number v }, :desc => "Port punchblock needs to connect"
      certs_directory     nil              , :desc => "Directory containing certificates for securing the connection."
      root_domain         nil              , :desc => "The root domain at which to address the server"
      calls_domain        nil              , :desc => "The domain at which to address calls"
      mixers_domain       nil              , :desc => "The domain at which to address mixers"
      connection_timeout  60               , :transform => Proc.new { |v| PunchblockPlugin.validate_number v }, :desc => "The amount of time to wait for a connection"
      reconnect_attempts  1.0/0.0          , :transform => Proc.new { |v| PunchblockPlugin.validate_number v }, :desc => "The number of times to (re)attempt connection to the server"
      reconnect_timer     5                , :transform => Proc.new { |v| PunchblockPlugin.validate_number v }, :desc => "Delay between connection attempts"
      media_engine        nil              , :transform => Proc.new { |v| v.to_sym }, :desc => "The media engine to use. Defaults to platform default."
      default_voice       nil              , :transform => Proc.new { |v| v.to_sym }, :desc => "The default TTS voice to use."
    end

    init :punchblock do
      Initializer.init if config.enabled
    end

    run :punchblock do
      Initializer.run if config.enabled
    end

    class << self
      delegate :client, :to => Initializer
      delegate :connection, :to => Initializer

      def validate_number(value)
        return 1.0/0.0 if ["Infinity", 1.0/0.0].include? value
        value.to_i
      end

      def default_port_for_platform(platform)
        case platform
          when :freeswitch then 8021
          when :asterisk then 5038
          when :xmpp then 5222
          else nil
        end
      end

      def execute_component(command, timeout = 60)
        client.execute_command command, :async => true
        response = command.response timeout
        raise response if response.is_a? Exception
        command
      end
    end
  end
end
