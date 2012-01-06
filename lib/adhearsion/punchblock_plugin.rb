module Adhearsion

  class PunchblockPlugin < Plugin

    extend ActiveSupport::Autoload

    autoload :Initializer

    config :punchblock do
      platform         :xmpp            , :desc => <<-__
        Platform punchblock shall use to connect to the Telephony provider. Currently supported values:
        - :xmpp
        - :asterisk
      __
      username         "usera@127.0.0.1", :desc => "Authentication credentials"
      password         "1"              , :desc => "Authentication credentials"
      host               nil              , :desc => "Host punchblock needs to connect (where rayo or asterisk are located)"
      port               nil              , :desc => "Port punchblock needs to connect (by default 5038 for Asterisk, 5222 for Rayo)"
      root_domain        nil              , :desc => "The root domain at which to address the server"
      calls_domain       nil              , :desc => "The domain at which to address calls"
      mixers_domain      nil              , :desc => "The domain at which to address mixers"
      auto_reconnect     true             , :desc => "Autoreconnect in case of failure"
      reconnect_attempts 1.0/0.0          , :desc => "The number of times to (re)attempt connection to the server"
      reconnect_timer    5                , :desc => "Delay between connection attempts"
    end

    init :punchblock do
      Initializer.start
    end

  end

end
