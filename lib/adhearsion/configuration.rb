# encoding: utf-8

require 'loquacious'

module Adhearsion
  class Configuration

    ConfigurationError = Class.new Adhearsion::Error # Error raised while trying to configure a non existent plugin

    def self.validate_number(value)
      return 1.0/0.0 if ["Infinity", 1.0/0.0].include? value
      value.to_i
    end

    def self.default_port_for_platform(platform)
      case platform
        when :asterisk then 5038
        when :xmpp then 5222
        else nil
      end
    end

    ##
    # Initialize the configuration object
    #
    # * &block core configuration block
    # Adhearsion::Configuration.new do
    #   foo "bar", :desc => "My description"
    # end
    #
    # @return [Adhearsion::Configuration]
    def initialize(env = :development, &block)
      @active_environment = env

      Loquacious.env_config = true
      Loquacious.env_prefix = "AHN"

      Loquacious::Configuration.for :core do
        root nil, :desc => "Adhearsion application root folder"

        lib "lib", :desc => <<-__
          Folder to include the own libraries to be used. Adhearsion loads any ruby file
          located into this folder during the bootstrap process. Set to nil if you do not
          want these files to be loaded. This folder is relative to the application root folder.
        __

        process_name "ahn", :desc => <<-__
          Adhearsion process name, useful to make it easier to find in the process list
          Pro tip: set this to your application's name and you can do "killall myapp"
          Does not work under JRuby.
        __

        event_threads 5, transform: Proc.new { |v| Adhearsion::Configuration.validate_number v }, desc: <<-__
          The number of threads to include in the event worker pool."
        __

        desc "Log configuration"
        logging {
          level :info, :transform => Proc.new { |v| v.to_sym }, :desc => <<-__
            Supported levels (in increasing severity) -- :trace < :debug < :info < :warn < :error < :fatal
          __
          formatter nil, :desc => <<-__
            A log formatter to apply to the stream. If nil, the Adhearsion default formatter will be used.
          __
        }

        type                :xmpp            , :transform => Proc.new { |v| v.to_sym }, :desc => <<-__
          Platform used to connect to the Telephony provider. Currently supported values:
          - :xmpp
          - :asterisk
        __
        username            "usera@127.0.0.1", :desc => "Authentication credentials"
        password            "1"              , :desc => "Authentication credentials"
        host                nil              , :desc => "Host to connect to (where rayo/asterisk is located)"
        port                Proc.new { Adhearsion::Configuration.default_port_for_platform type }, :transform => Proc.new { |v| Adhearsion::Configuration.validate_number v }, :desc => "Port used to connect"
        certs_directory     nil              , :desc => "Directory containing certificates for securing the connection."
        root_domain         nil              , :desc => "The root domain at which to address the server"
        connection_timeout  60               , :transform => Proc.new { |v| Adhearsion::Configuration.validate_number v }, :desc => "The amount of time to wait for a connection"
        reconnect_attempts  1.0/0.0          , :transform => Proc.new { |v| Adhearsion::Configuration.validate_number v }, :desc => "The number of times to (re)attempt connection to the server"
        reconnect_timer     5                , :transform => Proc.new { |v| Adhearsion::Configuration.validate_number v }, :desc => "Delay between connection attempts"

        after_hangup_lifetime 1, :transform => Proc.new { |v| v.to_i }, :desc => <<-__
          Lifetime of a call after it has hung up. Should be set to the minimum functional value for your application. Call actors (threads) living after hangup consume more system resources and reduce the concurrent call capacity of your application.
        __

        desc "Media configuration"
        media {
          default_voice nil, desc: 'The default voice used for all output. Set nil to use platform default.'
          default_renderer nil, desc: 'The default renderer used for all output. Set nil to use platform default.'

          min_confidence 0.5, desc: 'The default minimum confidence level used for all recognizer invocations.', transform: Proc.new { |v| v.to_f }
          timeout 5, desc: 'The default timeout (in seconds) used for all recognizer invocations.', transform: Proc.new { |v| v.to_i }
          inter_digit_timeout 2, desc: 'The timeout used between DTMF digits and to terminate partial invocations', transform: Proc.new { |v| v.to_i }
          recognizer nil, desc: 'The default recognizer used for all input. Set nil to use platform default.'
          input_language 'en-US', desc: 'The default language set on generated grammars. Set nil to use platform default.'
        }

        desc "Internationalisation"
        i18n {
          locale_path ["config/locales"], transform: Proc.new { |v| v.split ':' }, desc: <<-__
            List of directories from which to load locale data, colon-delimited
          __
          audio_path "app/assets/audio", desc: <<-__
            Base path from which audio files can be found. May be a filesystem path or some other URL (like HTTP)
          __
          fallback true, desc: <<-__
            Whether to include text for translations that provide both text & audio. True or false.
          __
        }

        desc "HTTP server"
        http do
          enable true, desc: "Enable or disable the HTTP server"
          host "0.0.0.0", desc: "IP to bind the HTTP listener to"
          port "8080", desc: "Port to bind the HTTP listener to"
          rackup 'config.ru', desc: 'Path to Rack configuration file (relative to Adhearsion application root)'
        end
      end

      Loquacious::Configuration.for :core, &block if block_given?

      self
    end

    def env(environment)
      if environment == @active_environment
        yield self
      else
        logger.trace "Ignoring configuration for inactive environment #{environment}"
      end
    end

    ##
    # Direct access to a specific configuration object
    #
    # Adhearsion.config[:core] => returns the configuration object associated with Adhearsion core
    #
    # @return [Loquacious::Configuration] configuration object or nil if the plugin does not exist
    def [](value)
      self.send value.to_sym
    end

    ##
    # Wrapper to access to a specific configuration object
    #
    # Adhearsion.config.foo => returns the configuration object associated to the foo plugin
    def method_missing(method_name, *args, &block)
      config = Loquacious::Configuration.for method_name, &block
      raise Adhearsion::Configuration::ConfigurationError.new "Invalid plugin #{method_name}" if config.nil?
      config
    end

    # root accessor
    def root
      core.root
    end

    ##
    # Handle the Adhearsion core configuration
    #
    # It accepts a block that will be executed in the Adhearsion config var environment
    # to update the desired values
    #
    # Adhearsion.config.core do
    #   foo "bar", :desc => "My new description"
    # end
    #
    # values = Adhearsion.config.core
    # values.foo => "bar"
    #
    # @return [Loquacious::Configuration] configuration object or nil if the plugin does not exist
    def core(&block)
      Loquacious::Configuration.for :core, &block
    end

    ##
    # Fetchs the configuration info for the Adhearsion core or a specific plugin
    # @param name [Symbol]
    #     - :all      => Adhearsion core and all the loaded plugins
    #     - nil       => Adhearsion core configuration
    #     - :core => Adhearsion core configuration
    #     - :<plugin-config-name> => Adhearsion plugin configuration
    #
    # @param args [Hash]
    #     - @option :show_values [Boolean] true | false to return the current values or just the description
    #
    # @return string with the configuration description/values
    def description(name, args = {:show_values => true})
      desc = StringIO.new

      name.nil? and name = :core
      if name.eql? :all
        value = ""
        Loquacious::Configuration.instance_variable_get("@table").keys.map do |config|
          value.concat description config, args
        end
        return value
      else
        return "" if Loquacious::Configuration.for(name).nil?

        if args[:show_values]
          name_leader = "  config.#{name}."
          desc_leader = "  # "
          name_value_sep = " = "
          title_leader = "  "
        else
          name_leader = ""
          desc_leader = "#"
          name_value_sep = " => "
          title_leader = ""
        end

        config = Loquacious::Configuration.help_for name,
                                :name_leader => name_leader,
                                :desc_leader => desc_leader,
                                :colorize    => true,
                                :io          => desc,
                                :name_value_sep => name_value_sep
        config.show :values => args[:show_values]
        "#{title_leader}# ******* Configuration for #{name} **************\n\n#{desc.string}"
      end
    end
  end
end
