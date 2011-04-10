%w[theatre jicksta-theatre].each do |theatre_gem_name|
  # Some older versions of the master branch required the theatre gem be installed. This is deprecation logic to inform the
  # user to uninstall the gem if they happened to have used theatre in the past.
  begin
    gem theatre_gem_name
  rescue LoadError
    # Good. It should not be installed.
  else
    abort <<-MESSAGE
It seems you have the "#{theatre_gem_name}" gem installed. As of Dec. 7th, 2008 Theatre has been rolled into Adhearsion
and will be distributed with it.

Please uninstall the gem by doing "sudo gem uninstall #{theatre_gem_name}".

You will not need to install it again in the future. Sorry for the inconvenience.
    MESSAGE
  end
end

require 'theatre'


module Adhearsion
  module Events

    DEFAULT_FRAMEWORK_EVENT_NAMESPACES = %w[
      /after_initialized
      /shutdown
      /exception
      /asterisk/manager_interface
      /asterisk/before_call
      /asterisk/after_call
      /asterisk/hungup_call
      /asterisk/failed_call
    ]

    class << self

      def framework_theatre
        defined?(@@framework_theatre) ? @@framework_theatre : reinitialize_theatre!
      end

      def trigger(*args)
        framework_theatre.trigger(*args)
      end

      def trigger_immediately(*args)
        framework_theatre.trigger_immediately(*args)
      end

      def reinitialize_theatre!
        @@framework_theatre.gracefully_stop! if defined? @@framework_theatre
      rescue
        # Recover and reinitalize
      ensure
        # TODO: Extract number of threads to use from AHN_CONFIG
        @@framework_theatre = Theatre::Theatre.new
        DEFAULT_FRAMEWORK_EVENT_NAMESPACES.each do |namespace|
          register_namespace_name namespace
        end
        return @@framework_theatre
      end

      def register_namespace_name(name)
        framework_theatre.register_namespace_name name
      end

      def stop!
        Events.trigger :shutdown
        framework_theatre.graceful_stop!
        framework_theatre.join
      end

      def register_callback(namespace, block_arg=nil, &method_block)
        raise ArgumentError, "Cannot supply two blocks!" if block_arg && block_given?
        block = method_block || block_arg
        raise ArgumentError, "Must supply a callback!" unless block

        framework_theatre.register_callback_at_namespace(namespace, block)
      end

    end

  end
end
