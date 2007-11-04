require "adhearsion/voip/freeswitch/oes_server"
require "adhearsion/voip/freeswitch/event_handler"
require "adhearsion/voip/freeswitch/inbound_connection_manager"
require "adhearsion/voip/dsl/dialplan/control_passing_exception"

oes_enabled = Adhearsion::Configuration.core.voip.freeswitch.oes && Adhearsion::Configuration.core.voip.freeswitch.oes.port
                

if oes_enabled

  port = Adhearsion::Configuration.core.voip.freeswitch.oes.port
  host = Adhearsion::Configuration.core.voip.freeswitch.oes.host

  server = Adhearsion::VoIP::FreeSwitch::OesServer.new port, host

  Adhearsion::Hooks::AfterInitialized.create_hook do
    server.start
    server.join
  end

  Adhearsion::Hooks::TearDown.create_hook do
    server.stop
  end

end
