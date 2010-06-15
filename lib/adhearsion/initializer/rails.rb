require 'adhearsion/voip/asterisk'

module Adhearsion
  class Initializer
    class RailsInitializer

      cattr_accessor :rails_root, :config, :environment
      class << self

        def start
          ahn_config       = Adhearsion::AHN_CONFIG
          self.config      = ahn_config.rails
          self.rails_root  = config.rails_root
          self.environment = config.environment
          raise "You cannot enable the database and Rails at the same time!" if ahn_config.database_enabled?
          raise "Error loading Rails environment in #{rails_root.inspect}. "  +
                "It's not a directory!" unless File.directory?(rails_root)
          load_rails
          if defined? ActiveRecord
            # You may need to uncomment the following line for older versions of ActiveRecord
            # ActiveRecord::Base.allow_concurrency = true
            Events.register_callback([:asterisk, :before_call]) do
              ActiveRecord::Base.verify_active_connections!
            end
          end
        end

        private

        def load_rails
          environment_file = File.expand_path(rails_root + "/config/environment.rb")
          raise "There is no config/environment.rb file!" unless File.exists?(environment_file)
          ENV['RAILS_ENV'] = environment.to_s
          require environment_file
        end

      end

    end
  end
end
