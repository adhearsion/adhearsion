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
      wire_logger      nil              , :desc => ""
      transport_logger nil              , :desc => ""
    end

    init :punchblock do
      Initializer.start
    end
    
  end

end