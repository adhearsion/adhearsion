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
      auto_reconnect   true             , :desc => "Autoreconnect in case of failure"
      host             nil              , :desc => "Host punchblock needs to connect (where rayo or asterisk are located)"
      port             nil              , :desc => "Port punchblock needs to connect (by default 5038 for Asterisk, 5222 for Rayo)"
    end

    init :punchblock do
      Initializer.start
    end
    
  end

end