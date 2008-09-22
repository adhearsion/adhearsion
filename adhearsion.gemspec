ADHEARSION_FILES = %w{
  adhearsion.gemspec
  LICENSE
  README.txt
  Rakefile
  app_generators/ahn/USAGE
  app_generators/ahn/ahn_generator.rb
  app_generators/ahn/templates/.ahnrc
  app_generators/ahn/templates/events.rb
  app_generators/ahn/templates/README
  app_generators/ahn/templates/Rakefile
  app_generators/ahn/templates/components/simon_game/configuration.rb
  app_generators/ahn/templates/components/simon_game/lib/simon_game.rb
  app_generators/ahn/templates/components/simon_game/test/test_helper.rb
  app_generators/ahn/templates/components/simon_game/test/test_simon_game.rb
  app_generators/ahn/templates/config/startup.rb
  app_generators/ahn/templates/dialplan.rb
  bin/ahn
  bin/ahnctl
  bin/jahn
  lib/adhearsion.rb
  lib/adhearsion/blank_slate.rb
  lib/adhearsion/cli.rb
  lib/adhearsion/events_support.rb
  lib/adhearsion/component_manager.rb
  lib/adhearsion/core_extensions/all.rb
  lib/adhearsion/core_extensions/array.rb
  lib/adhearsion/core_extensions/custom_daemonizer.rb
  lib/adhearsion/core_extensions/global.rb
  lib/adhearsion/core_extensions/guid.rb
  lib/adhearsion/core_extensions/hash.rb
  lib/adhearsion/core_extensions/metaprogramming.rb
  lib/adhearsion/core_extensions/numeric.rb
  lib/adhearsion/core_extensions/proc.rb
  lib/adhearsion/core_extensions/pseudo_uuid.rb
  lib/adhearsion/core_extensions/publishable.rb
  lib/adhearsion/core_extensions/relationship_properties.rb
  lib/adhearsion/core_extensions/string.rb
  lib/adhearsion/core_extensions/thread.rb
  lib/adhearsion/core_extensions/thread_safety.rb
  lib/adhearsion/core_extensions/time.rb
  lib/adhearsion/distributed/gateways/dbus_gateway.rb
  lib/adhearsion/distributed/gateways/osa_gateway.rb
  lib/adhearsion/distributed/gateways/rest_gateway.rb
  lib/adhearsion/distributed/gateways/soap_gateway.rb
  lib/adhearsion/distributed/gateways/xmlrpc_gateway.rb
  lib/adhearsion/distributed/peer_finder.rb
  lib/adhearsion/distributed/remote_cli.rb
  lib/adhearsion/hooks.rb
  lib/adhearsion/host_definitions.rb
  lib/adhearsion/initializer.rb
  lib/adhearsion/initializer/asterisk.rb
  lib/adhearsion/initializer/configuration.rb
  lib/adhearsion/initializer/database.rb
  lib/adhearsion/initializer/drb.rb
  lib/adhearsion/initializer/freeswitch.rb
  lib/adhearsion/initializer/paths.rb
  lib/adhearsion/initializer/rails.rb
  lib/adhearsion/logging.rb
  lib/adhearsion/tasks.rb
  lib/adhearsion/tasks/database.rb
  lib/adhearsion/tasks/generating.rb
  lib/adhearsion/tasks/lint.rb
  lib/adhearsion/tasks/testing.rb
  lib/adhearsion/version.rb
  lib/adhearsion/voip/asterisk.rb
  lib/adhearsion/voip/asterisk/agi_server.rb
  lib/adhearsion/voip/asterisk/ami.rb
  lib/adhearsion/voip/asterisk/ami/actions.rb
  lib/adhearsion/voip/asterisk/ami/machine.rb
  lib/adhearsion/voip/asterisk/ami/machine.rl
  lib/adhearsion/voip/asterisk/ami/parser.rb
  lib/adhearsion/voip/asterisk/commands.rb
  lib/adhearsion/voip/asterisk/config_generators/agents.conf.rb
  lib/adhearsion/voip/asterisk/config_generators/config_generator.rb
  lib/adhearsion/voip/asterisk/config_generators/queues.conf.rb
  lib/adhearsion/voip/asterisk/config_generators/voicemail.conf.rb
  lib/adhearsion/voip/asterisk/config_manager.rb
  lib/adhearsion/voip/asterisk/special_dial_plan_managers.rb
  lib/adhearsion/voip/call.rb
  lib/adhearsion/voip/call_routing.rb
  lib/adhearsion/voip/commands.rb
  lib/adhearsion/voip/constants.rb
  lib/adhearsion/voip/conveniences.rb
  lib/adhearsion/voip/dial_plan.rb
  lib/adhearsion/voip/dsl/dialing_dsl.rb
  lib/adhearsion/voip/dsl/dialing_dsl/dialing_dsl_monkey_patches.rb
  lib/adhearsion/voip/dsl/dialplan/control_passing_exception.rb
  lib/adhearsion/voip/dsl/dialplan/dispatcher.rb
  lib/adhearsion/voip/dsl/dialplan/parser.rb
  lib/adhearsion/voip/dsl/dialplan/thread_mixin.rb
  lib/adhearsion/voip/dsl/numerical_string.rb
  lib/adhearsion/voip/freeswitch/basic_connection_manager.rb
  lib/adhearsion/voip/freeswitch/event_handler.rb
  lib/adhearsion/voip/freeswitch/freeswitch_dialplan_command_factory.rb
  lib/adhearsion/voip/freeswitch/inbound_connection_manager.rb
  lib/adhearsion/voip/freeswitch/oes_server.rb
  lib/adhearsion/voip/menu_state_machine/calculated_match.rb
  lib/adhearsion/voip/menu_state_machine/matchers.rb
  lib/adhearsion/voip/menu_state_machine/menu_builder.rb
  lib/adhearsion/voip/menu_state_machine/menu_class.rb
}

Gem::Specification.new do |s|
  s.name = "adhearsion"
  s.version = "0.7.999"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Jay Phillips"]
  s.date = "2008-08-21"
  s.description = "Adhearsion is an open-source telephony development framework"
  s.email = "Jay -at- Codemecca.com"
  s.executables = ["ahn", "ahnctl", "jahn"]
  
  s.files = ADHEARSION_FILES
  
  s.has_rdoc = false
  s.homepage = "http://adhearsion.com"
  s.require_paths = ["lib"]
  s.rubyforge_project = "adhearsion"
  s.rubygems_version = "1.2.0"
  s.summary = "Adhearsion, open-source telephony development framework"

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if current_version >= 3 then
      s.add_runtime_dependency("rubigen", [">= 1.0.6"])
      s.add_runtime_dependency("log4r", [">= 1.0.5"])
    else
      s.add_dependency("rubigen", [">= 1.0.6"])
      s.add_dependency("log4r", [">= 1.0.5"])
    end
  else
    s.add_dependency("rubigen", [">= 1.0.6"])
    s.add_dependency("log4r", [">= 1.0.5"])
  end
end
