module Adhearsion

  class PunchblockPlugin < Plugin

    extend ActiveSupport::Autoload

    autoload :Initializer

    config :punchblock do
      platform       :xmpp            , "Platform punchblock shall use to connect to the Telephony provider"
      username       "usera@127.0.0.1", "Authentication credentials"
      password       "1"              , "Authentication credentials"
      auto_reconnect true             , "Autoreconnect in case of failure"
      enabled        true
    end

    init :punchblock do
      if Adhearsion.config[:punchblock] && Adhearsion.config[:punchblock].enabled
        logger.debug "Initializing Punchblock using PunchblockPlugin"
        Initializer.start
      end
    end
    
  end

end