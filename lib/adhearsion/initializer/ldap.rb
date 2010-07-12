# TODO: Have all of the initializer modules required and then traverse the subclasses, asking them if they're enabled. If they are enabled, then they should do their initialization stuff. Is this really necessary to develop this entirely new system when the components system exists?

module Adhearsion
  class Initializer

    class LdapInitializer

      class << self

        def start
          require_dependencies
          require_models
          @@config = Adhearsion::AHN_CONFIG.ldap
          # You may need to uncomment the following line for older versions of ActiveRecord
          # ActiveRecord::Base.allow_concurrency = true
          establish_connection
        end

        def stop
          ActiveLdap::Base.remove_connection
        end

        private

        # TODO: It appears that ActiveLdap does not have a connection validation
        # or reconnection routine.
        #def create_call_hook_for_connection_cleanup
        #  Events.register_callback([:asterisk, :before_call]) do
        #    ActiveLdap::Base.verify_active_connections!
        #  end
        #end

        def require_dependencies
          begin
            require 'active_ldap'
          rescue LoadError
            ahn_log.fatal "LDAP support requires the \"activeldap\" gem."
            # Silence the abort so we don't get an ugly backtrace
            abort ""
          end
        end

        def require_models
          AHN_CONFIG.files_from_setting("paths", "models").each do |model|
            load model
          end
        end

        def establish_connection
          ActiveLdap::Base.setup_connection @@config.connection_options
        end

      end
    end

  end
end