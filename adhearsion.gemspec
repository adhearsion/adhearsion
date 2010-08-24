ADHEARSION_FILES = %w{
  adhearsion.gemspec
  app_generators/ahn/ahn_generator.rb
  app_generators/ahn/templates/.ahnrc
  app_generators/ahn/templates/components/ami_remote/ami_remote.rb
  app_generators/ahn/templates/components/disabled/HOW_TO_ENABLE
  app_generators/ahn/templates/components/disabled/stomp_gateway/stomp_gateway.yml
  app_generators/ahn/templates/components/disabled/stomp_gateway/README.markdown
  app_generators/ahn/templates/components/disabled/stomp_gateway/stomp_gateway.rb
  app_generators/ahn/templates/components/disabled/sandbox/sandbox.rb
  app_generators/ahn/templates/components/disabled/sandbox/sandbox.yml
  app_generators/ahn/templates/components/disabled/restful_rpc/restful_rpc.yml
  app_generators/ahn/templates/components/disabled/restful_rpc/example-client.rb
  app_generators/ahn/templates/components/disabled/restful_rpc/README.markdown
  app_generators/ahn/templates/components/disabled/restful_rpc/restful_rpc.rb
  app_generators/ahn/templates/components/disabled/restful_rpc/spec/restful_rpc_spec.rb
  app_generators/ahn/templates/components/disabled/xmpp_gateway/xmpp_gateway.rb
  app_generators/ahn/templates/components/disabled/xmpp_gateway/xmpp_gateway.yml
  app_generators/ahn/templates/components/disabled/xmpp_gateway/README.markdown
  app_generators/ahn/templates/components/simon_game/simon_game.rb
  app_generators/ahn/templates/config/startup.rb
  app_generators/ahn/templates/dialplan.rb
  app_generators/ahn/templates/events.rb
  app_generators/ahn/templates/Rakefile
  app_generators/ahn/templates/README
  app_generators/ahn/USAGE
  bin/ahn
  bin/ahnctl
  bin/jahn
  CHANGELOG
  EVENTS
  examples/asterisk_manager_interface/standalone.rb
  lib/adhearsion.rb
  lib/adhearsion/cli.rb
  lib/adhearsion/component_manager.rb
  lib/adhearsion/component_manager/component_tester.rb
  lib/adhearsion/component_manager/spec_framework.rb
  lib/adhearsion/events_support.rb
  lib/adhearsion/foundation/all.rb
  lib/adhearsion/foundation/blank_slate.rb
  lib/adhearsion/foundation/custom_daemonizer.rb
  lib/adhearsion/foundation/event_socket.rb
  lib/adhearsion/foundation/future_resource.rb
  lib/adhearsion/foundation/metaprogramming.rb
  lib/adhearsion/foundation/numeric.rb
  lib/adhearsion/foundation/pseudo_guid.rb
  lib/adhearsion/foundation/relationship_properties.rb
  lib/adhearsion/foundation/string.rb
  lib/adhearsion/foundation/synchronized_hash.rb
  lib/adhearsion/foundation/thread_safety.rb
  lib/adhearsion/host_definitions.rb
  lib/adhearsion/initializer.rb
  lib/adhearsion/initializer/asterisk.rb
  lib/adhearsion/initializer/configuration.rb
  lib/adhearsion/initializer/database.rb
  lib/adhearsion/initializer/ldap.rb
  lib/adhearsion/initializer/drb.rb
  lib/adhearsion/initializer/freeswitch.rb
  lib/adhearsion/initializer/rails.rb
  lib/adhearsion/initializer/xmpp.rb
  lib/adhearsion/logging.rb
  lib/adhearsion/tasks.rb
  lib/adhearsion/tasks/database.rb
  lib/adhearsion/tasks/deprecations.rb
  lib/adhearsion/tasks/generating.rb
  lib/adhearsion/tasks/lint.rb
  lib/adhearsion/tasks/testing.rb
  lib/adhearsion/version.rb
  lib/adhearsion/voip/asterisk.rb
  lib/adhearsion/voip/asterisk/agi_server.rb
  lib/adhearsion/voip/asterisk/commands.rb
  lib/adhearsion/voip/asterisk/config_generators/agents.conf.rb
  lib/adhearsion/voip/asterisk/config_generators/config_generator.rb
  lib/adhearsion/voip/asterisk/config_generators/queues.conf.rb
  lib/adhearsion/voip/asterisk/config_generators/voicemail.conf.rb
  lib/adhearsion/voip/asterisk/config_manager.rb
  lib/adhearsion/voip/asterisk/manager_interface.rb
  lib/adhearsion/voip/asterisk/manager_interface/ami_lexer.rb
  lib/adhearsion/voip/asterisk/manager_interface/ami_lexer.rl.rb
  lib/adhearsion/voip/asterisk/manager_interface/ami_messages.rb
  lib/adhearsion/voip/asterisk/manager_interface/ami_protocol_lexer_machine.rl
  lib/adhearsion/voip/asterisk/special_dial_plan_managers.rb
  lib/adhearsion/voip/asterisk/super_manager.rb
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
  lib/adhearsion/xmpp/connection.rb
  lib/theatre.rb
  lib/theatre/callback_definition_loader.rb
  lib/theatre/guid.rb
  lib/theatre/invocation.rb
  lib/theatre/namespace_manager.rb
  lib/theatre/README.markdown
  lib/theatre/version.rb
  LICENSE
  Rakefile
}

Gem::Specification.new do |s|
  s.name = "adhearsion"
  s.version = "0.8.6"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Jay Phillips", "Jason Goecke", "Ben Klang"]

  s.date = "2010-08-24"
  s.description = "Adhearsion is an open-source telephony development framework"
  s.email = "dev&Adhearsion.com"
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
      s.add_runtime_dependency("activesupport", [">= 2.1.0"])
    else
      s.add_dependency("rubigen", [">= 1.0.6"])
      s.add_dependency("log4r", [">= 1.0.5"])
      s.add_dependency("activesupport", [">= 2.1.0"])
    end
  else
    s.add_dependency("rubigen", [">= 1.0.6"])
    s.add_dependency("log4r", [">= 1.0.5"])
    s.add_dependency("activesupport", [">= 2.1.0"])
  end
end
