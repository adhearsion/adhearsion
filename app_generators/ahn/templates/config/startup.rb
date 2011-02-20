require 'rubygems'
require 'bundler'
Bundler.setup
Bundler.require

Adhearsion::Configuration.configure do |config|

  # Components to load from the system.
  # All components that are activated in components/ will be automatically
  # loaded and made available.
  # This configuration option allows you to load components provided by gems.
  # List the gem names here:
  # config.add_component "ahn_test_component"

  # Supported levels (in increasing severity) -- :debug < :info < :warn < :error < :fatal
  config.logging :level => :info

  # Whether incoming calls be automatically answered. Defaults to true.
  # config.automatically_answer_incoming_calls = false

  # Whether the other end hanging up should end the call immediately. Defaults to true.
  # config.end_call_on_hangup = false

  # Whether to end the call immediately if an unrescued exception is caught. Defaults to true.
  # config.end_call_on_error = false

  # NOTE: Pay special attention to the argument_delimiter field below:
  # For Asterisk <= 1.4, use "|" (default)
  # For Asterisk >= 1.6, use ","
  # The delimiter can also be specified in Asterisk's asterisk.conf.
  # This setting applies only to AGI.  The AMI delimiter is auto-detected.
  config.enable_asterisk :argument_delimiter => '|'
  # config.asterisk.enable_ami :host => "127.0.0.1", :username => "admin", :password => "password", :events => true

  # config.enable_drb

  # Streamlined Rails integration! The first argument should be a relative or absolute path to
  # the Rails app folder with which you're integrating. The second argument must be one of the
  # the following: :development, :production, or :test.

  # config.enable_rails :path => 'gui', :env => :development

  # Note: You CANNOT do enable_rails and enable_database at the same time. When you enable Rails,
  # it will automatically connect to same database Rails does and load the Rails app's models.

  # Configure a database to use ActiveRecord-backed models. See ActiveRecord::Base.establish_connection
  # for the appropriate settings here.
  # You can also override the default log destination by supplying an alternate
  # logging object with :logger.  The default is ahn_log.db.
  # config.enable_database :adapter  => 'mysql',
  #                        :username => 'joe',
  #                        :password => 'secret',
  #                        :host     => 'db.example.org'

  # Configure an LDAP connection using ActiveLdap.  See ActiveLdap::Base.establish_connect
  # for the appropriate settings here.
  # config.enable_ldap :host => 'ldap.dataspill.org',
  #                    :port => 389,
  #                    :base => 'dc=dataspill,dc=org',
  #                    :logger => ahn_log.ldap,
  #                    :bind_dn => "uid=drewry,ou=People,dc=dataspill,dc=org",
  #                    :password => 'password12345',
  #                    :allow_anonymous => false,
  #                    :try_sasl => false

  # Configure XMPP call controller
  # config.enable_xmpp :jid => 'active-calls.xmpp.example.com',
  #                    :password => 'passwd',
  #                    :server => 'xmpp.example.com',
  #                    :port => 5347

end

Adhearsion::Initializer.start_from_init_file(__FILE__, File.dirname(__FILE__) + "/..")
