# TODO: Have all of the initializer modules required and then traverse the subclasses, asking them if they're enabled. If they are enabled, then they should do their initialization stuff. Is this really necessary to develop this entirely new system when the components system exists?

module Adhearsion
  class Initializer
    
    class DatabaseInitializer
      
      class << self

        def start
          require_dependencies
          require_models
          @@config = Adhearsion::AHN_CONFIG.database
          ActiveRecord::Base.allow_concurrency = true
          establish_connection
        end

        def stop
          ActiveRecord::Base.remove_connection
        end

        private

        def require_dependencies
          require 'active_record'
        end

        def require_models
          all_models.each do |model|
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

=begin
db_config = Adhearsion::Configuration.core.database
if db_config
  unless Adhearsion::Paths.manager_for? "models"
    raise "No paths specified for the database 'models' in .ahnrc! Aborting."
  end
  require 'active_record'
  
  ActiveRecord::Base.verification_timeout = 14400
  ActiveRecord::Base.logger = Logger.new("log/database.log")
  ActiveRecord::Base.establish_connection db_config
  
  all_models.each { |model| require model }
  
  # Below is a monkey patch for keeping ActiveRecord connections alive.
  # http://www.sparecycles.org/2007/7/2/saying-goodbye-to-lost-connections-in-rails
  
  module ActiveRecord
    module ConnectionAdapters
      class MysqlAdapter
        def execute(sql, name = nil) #:nodoc:
          reconnect_lost_connections = true
          begin
            log(sql, name) { @connection.query(sql) }
          rescue ActiveRecord::StatementInvalid => exception
            if reconnect_lost_connections and exception.message =~ /(Lost connection to MySQL server during query|MySQL server has gone away)/
              reconnect_lost_connections = false
              reconnect!
              retry
            elsif exception.message.split(":").first =~ /Packets out of order/
              raise ActiveRecord::StatementInvalid, "'Packets out of order' error was received from the database. Please update your mysql bindings (gem install mysql) and read http://dev.mysql.com/doc/mysql/en/password-hashing.html for more information.  If you're on Windows, use the Instant Rails installer to get the updated mysql bindings." 
            else
              raise
            end
          end
        end
      end
    end
  end
  
end
=end