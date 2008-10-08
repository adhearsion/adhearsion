require File.dirname(__FILE__) + "/dsl/numerical_string"
require File.dirname(__FILE__) + "/asterisk/agi_server"
require File.dirname(__FILE__) + "/asterisk/ami"
require File.dirname(__FILE__) + "/asterisk/commands"

# These will soon replace hooks
#
# [:before_call, :after_call, :hungup_call, :failed_call].each do |callback_name|
#   Adhearsion::Events.framework_theatre.namespace_manager.register_namespace_name [:asterisk, callback_name]
# end
