# THIS FREESWITCH LIBRARY HASN'T BEEN INTEGRATED INTO THE REFACTORED 0.8.0 YET.
# WHAT EXISTS HERE IS OLD, MUST BE CHANGED, AND DOES NOT EVEN GET LOADED AT THE MOMENT.
require "adhearsion/voip/freeswitch/oes_server"
require "adhearsion/voip/freeswitch/event_handler"
require "adhearsion/voip/freeswitch/inbound_connection_manager"
require "adhearsion/voip/dsl/dialplan/control_passing_exception"

oes_enabled = Adhearsion::Configuration.core.voip.freeswitch.oes && Adhearsion::Configuration.core.voip.freeswitch.oes.port


if oes_enabled

  port = Adhearsion::Configuration.core.voip.freeswitch.oes.port
  host = Adhearsion::Configuration.core.voip.freeswitch.oes.host

  server = Adhearsion::VoIP::FreeSwitch::OesServer.new port, host

  Events.register_callback(:after_initialized) { server.start }
  Events.register_callback(:shutdown) { server.stop }
  IMPORTANT_THREADS << server

end
