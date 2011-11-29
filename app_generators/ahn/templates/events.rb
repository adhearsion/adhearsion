Adhearsion::Events.draw do
  ##
  # In this file you can define callbacks for different aspects of the framework. Below is an example:
  ##
  #
  # before_call do |call|
  #   # This simply logs the extension for all calls going through this Adhearsion app.
  #   extension = call.variables[:extension]
  #   logger.info "Got a new call with extension #{extension}"
  # end
  #
  ##
  # Asterisk Manager Interface example:
  #
  # asterisk_manager_interface do |event|
  #   logger.info event.inspect
  # end
  #
  # This assumes you gave :events => true to the config.asterisk.enable_ami method in config/adhearsion.rb
  #
  ##
  # Here is a list of the events included by default:
  #
  # - exception
  # - asterisk_manager_interface
  # - after_initialized
  # - shutdown
  # - before_call
  # - failed_call
  # - hungup_call
  #
  #
  # Note: events are mostly for plugins to register and expose to you.
  ##
end
