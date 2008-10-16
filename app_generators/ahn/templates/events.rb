##
# In this file you can define callbacks for different aspects of the framework. Below is an example:
##
#
# events.asterisk.before_call.each do |call|
#   extension = call.variables[:extension]
#   ahn_log "Got a new call with extension #{extension}"
# end
#
##
# Here is a list of the events included by default:
#
# - events.after_initialized
# - events.shutdown
# - events.asterisk.before_call
# - events.asterisk.failed_call
# - events.asterisk.call_hangup
#
#
# Note: events are mostly for components to register and expose to you.
##
