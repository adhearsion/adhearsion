# TODO: Have all of the initializer modules required and then traverse the subclasses, asking them if they're enabled. If they are enabled, then they should do their initialization stuff. Is this really necessary to develop this entirely new system when the components system exists?

module Adhearsion
  class Initializer

    class DatabaseInitializer

      class << self

        def start
          require_dependencies
          require_models
          @@config = Adhearsion::AHN_CONFIG.database
          # You may need to uncomment the following line for older versions of ActiveRecord
          # ActiveRecord::Base.allow_concurrency = true
          establish_connection
          ActiveRecord::Base.logger =
            @@config.connection_options.has_key?(:logger) ?
              @@config.connection_options[:logger] :
              ahn_log.db
          create_call_hook_for_connection_cleanup
        end

        def stop
          ActiveRecord::Base.remove_connection
        end

        private

        def create_call_hook_for_connection_cleanup
          Events.register_callback([:asterisk, :before_call]) do
            ActiveRecord::Base.verify_active_connections!
          end
        end

        def require_dependencies
          begin
            require 'active_record'
          rescue LoadError
            ahn_log.fatal "Database support requires the \"activerecord\" gem."
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
          ActiveRecord::Base.establish_connection @@config.connection_options
        end

      end
    end

  end
end