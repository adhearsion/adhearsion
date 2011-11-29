module Adhearsion

  class PunchblockPlugin < Plugin

    extend ActiveSupport::Autoload

    autoload :Initializer

    config :punchblock do
      platform       :xmpp            , :desc => "Platform punchblock shall use to connect to the Telephony provider"
      username       "usera@127.0.0.1", :desc => "Authentication credentials"
      password       "1"              , :desc => "Authentication credentials"
      auto_reconnect true             , :desc => "Autoreconnect in case of failure"
      wire_logger    nil              , :desc => ""
      transport_logger nil            , :desc => ""
    end

    init :punchblock do
      if Adhearsion.config[:punchblock] && Adhearsion.config[:punchblock].enabled
        logger.debug "Initializing Punchblock using PunchblockPlugin"
        Initializer.start
      end
    end
    
  end

end