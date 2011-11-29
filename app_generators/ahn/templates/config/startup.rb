require File.join(File.dirname(__FILE__), 'environment')

Adhearsion.config do |config|


  # Adhearsion core configuration
  config.automatically_accept_incoming_calls = true

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

  config.logging :level => :info

  # Whether incoming calls be automatically accepted. Defaults to true.
  # config.automatically_accept_incoming_calls = false

  # Adhearsion supports two possible speech engines with Asterisk: UniMRCP and Cepstral.
  # Uncomment one of the below if you have it available.
  # config.asterisk.speech_engine = :cepstral
  # config.asterisk.speech_engine = :unimrcp

  # Note: You CANNOT do enable_rails and enable_database at the same time. When you enable Rails,
  # it will automatically connect to same database Rails does and load the Rails app's models.

end

Adhearsion::Initializer.start_from_init_file(__FILE__, File.dirname(__FILE__) + "/..")
