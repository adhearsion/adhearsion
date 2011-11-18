require File.join(File.dirname(__FILE__), 'environment')

Adhearsion.config do |config|


  # Adhearsion core configuration
  config.automatically_accept_incoming_calls = true

  config.end_call_on_hangup = true
  config.end_call_on_error  = true


  config.add_configuration_for(:asterisk)

  config.asterisk.speech_engine = nil
  config.asterisk.argument_delimiter = '|' # This setting only applies to AGI.  AMI delimiters are always auto-detected.
  config.asterisk.listening_port = 4573
  config.asterisk.listening_host = "localhost"

  config.asterisk.add_configuration_for(:default_ami) do |ami|
    ami.port = 5038
    ami.events = false
    ami.host = "localhost"
    ami.auto_reconnect = true
  end

  # define enable_ami method, that loads the default values
  config.asterisk.instance_eval do
    def enable_ami(params = {})
      values = self.default_ami.methods(false).select{|m| m[-1] != "="}
      self.add_configuration_for(:ami) do |ami|
        (values - params.keys).each do |value|
          ami.send("#{value.to_s}=".to_sym, self.default_ami.send(value))
        end
        params.each_pair do |k,v|
          ami.send("#{k.to_s}=".to_sym, v)
        end
      end
    end
  end

  # Log configuration
  # :level : Supported levels (in increasing severity) -- :debug < :info < :warn < :error < :fatal
  # :outputters : An array of log outputters to use. The default is to log to stdout and log/adhearsion.log
  # :formatters : An array of log formatters to apply to the outputters in use
  # :formatter : A log formatter to apply to all active outputters
  config.logging :level => :info

  # Whether incoming calls be automatically accepted. Defaults to true.
  # config.automatically_accept_incoming_calls = false

  # Whether the other end hanging up should end the call immediately. Defaults to true.
  # config.end_call_on_hangup = false

  # Whether to end the call immediately if an unrescued exception is caught. Defaults to true.
  # config.end_call_on_error = false

  # Adhearsion supports two possible speech engines with Asterisk: UniMRCP and Cepstral.
  # Uncomment one of the below if you have it available.
  # config.asterisk.speech_engine = :cepstral
  # config.asterisk.speech_engine = :unimrcp

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
  #                    :logger => logger,
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
