module Adhearsion
  class Configuration
    module ConfigurationEntryPoint
      def add_configuration_for(name)
        configuration_class_name = "#{name}Configuration"
        lowercased_name          = name.to_s.underscore

        class_eval(<<-EVAL, __FILE__, __LINE__)
          def enable_#{lowercased_name}(configuration_options = {})
            @#{lowercased_name}_configuration = #{configuration_class_name}.new(configuration_options)
          end

          def #{lowercased_name}
            @#{lowercased_name}_configuration
          end

          def #{lowercased_name}_enabled?
            !#{lowercased_name}.nil?
          end
        EVAL
      end
    end
    extend ConfigurationEntryPoint

    class << self
      def configure(&block)
        if Adhearsion.const_defined?(:AHN_CONFIG)
          yield AHN_CONFIG if block_given?
        else
          Adhearsion.const_set(:AHN_CONFIG, new(&block))
        end
      end
    end

    attr_accessor :automatically_answer_incoming_calls
    attr_accessor :end_call_on_hangup
    attr_accessor :end_call_on_error
    attr_accessor :components_to_load

    def initialize
      @automatically_answer_incoming_calls = true
      @end_call_on_hangup                  = true
      @end_call_on_error                   = true
      @components_to_load                  = []
      yield self if block_given?
    end

    def ahnrc
      @ahnrc
    end

    ##
    # Load the contents of an .ahnrc file into this Configuration.
    #
    # @param [String, Hash] ahnrc String of YAML .ahnrc data or a Hash of the pre-loaded YAML data structure
    #
    def ahnrc=(new_ahnrc)
      case new_ahnrc
        when Hash
          @raw_ahnrc = new_ahnrc.to_yaml.freeze
          @ahnrc = new_ahnrc.clone.freeze
        when String
          @raw_ahnrc = new_ahnrc.clone.freeze
          @ahnrc = YAML.load(new_ahnrc).freeze
      end
    end

    def logging(options)
      Adhearsion::Logging.logging_level = options[:level] if options.has_key? :level
      Adhearsion::Logging::AdhearsionLogger.outputters = Array(options[:outputters]) if options.has_key? :outputters
      Adhearsion::Logging::AdhearsionLogger.formatters = Array(options[:formatters]) if options.has_key? :formatters
      Adhearsion::Logging::AdhearsionLogger.formatters = Array(options[:formatter]) * Adhearsion::Logging::AdhearsionLogger.outputters.count if options.has_key? :formatter
    end

    def add_component(*list)
      AHN_CONFIG.components_to_load |= list
    end

    ##
    # Adhearsion's .ahnrc file is used to define paths to certain parts of the framework. For example, the name dialplan.rb
    # is actually specified in .ahnrc. This file can actually be just a filename, a filename with a glob (.e.g "*.rb"), an
    # Array of filenames or even an Array of globs.
    #
    # @param [String,Array] String segments which convey the nesting of Hash keys through .ahnrc
    # @raise [RuntimeError] If ahnrc has not been set yet with #ahnrc=()
    # @raise [NameError] If the path through the ahnrc is invalid
    #
    def files_from_setting(*path_through_config)
      raise RuntimeError, "No ahnrc has been set yet!" unless @ahnrc
      queried_nested_setting = path_through_config.flatten.inject(@ahnrc) do |hash,key_name|
        if hash.kind_of?(Hash) && hash.has_key?(key_name)
          hash[key_name]
        else
          raise NameError, "Paths #{path_through_config.inspect} not found in .ahnrc!"
        end
      end
      raise NameError, "Paths #{path_through_config.inspect} not found in .ahnrc!" unless queried_nested_setting
      queried_nested_setting = Array queried_nested_setting
      queried_nested_setting.map { |filename| files_from_glob(filename) }.flatten.uniq
    end

    private

    def files_from_glob(glob)
      Dir.glob "#{AHN_ROOT}/#{glob}"
    end

    class AbstractConfiguration
      extend ConfigurationEntryPoint

      class << self
        private
          def abstract_method!
            raise "Must be implemented in subclasses"
          end
      end

      def initialize(overrides = {})
        overrides.each_pair do |attribute, value|
          send("#{attribute}=", value)
        end
      end
    end

    # Abstract superclass for AsteriskConfiguration and FreeSwitchConfiguration.
    class TelephonyPlatformConfiguration < AbstractConfiguration
      attr_accessor :listening_port
      attr_accessor :listening_host

      class << self
        def default_listening_port
          abstract_method!
        end

        def default_listening_host
          '0.0.0.0'
        end
      end

      def initialize(overrides = {})
        @listening_host = overrides.has_key?(:host) ? overrides.delete(:host) : self.class.default_listening_host
        @listening_port = overrides.has_key?(:port) ? overrides.delete(:port) : self.class.default_listening_port
        super
      end
    end

    class AsteriskConfiguration < TelephonyPlatformConfiguration
      attr_accessor :speech_engine
      attr_accessor :argument_delimiter

      class << self
        def default_listening_port
          4573
        end

        # Keep Asterisk 1.4 (and prior) as the default to protect upgraders
        # This setting only applies to AGI.  AMI delimiters are always
        # auto-detected.
        def default_argument_delimiter
          '|'
        end
      end

      def initialize(overrides = {})
        @argument_delimiter = self.class.default_argument_delimiter
        super
      end

      class AMIConfiguration < AbstractConfiguration
        attr_accessor :port, :username, :password, :events, :host, :auto_reconnect

        class << self
          def default_port
            5038
          end

          def default_events
            false
          end

          def default_host
            'localhost'
          end

          def default_auto_reconnect
            true
          end
        end

        def initialize(overrides = {})
          self.host           = self.class.default_host
          self.port           = self.class.default_port
          self.events         = self.class.default_events
          self.auto_reconnect = self.class.default_auto_reconnect
          super
        end
      end
      add_configuration_for :AMI
    end
    add_configuration_for :Asterisk

    class FreeswitchConfiguration < TelephonyPlatformConfiguration
      class << self
        def default_listening_port
          4572
        end
      end
    end
    add_configuration_for :Freeswitch

    class DatabaseConfiguration < AbstractConfiguration
      attr_accessor :connection_options, :orm
      def initialize(options)
        @orm                = options.delete(:orm) || :active_record # TODO: ORM is a misnomer
        @connection_options = options
      end
    end
    add_configuration_for :Database

    class LdapConfiguration < AbstractConfiguration
      attr_accessor :connection_options
      def initialize(options)
        @connection_options = options
      end
    end
    add_configuration_for :Ldap

    class DrbConfiguration < AbstractConfiguration
      attr_accessor :port
      attr_accessor :host
      attr_accessor :acl

      # ACL = Access Control List

      class << self
        def default_port
          9050
        end

        def default_host
          'localhost'
        end
      end

      def initialize(overrides = {})
        self.port = overrides[:port] || self.class.default_port
        self.host = overrides[:host] || self.class.default_host
        self.acl  = overrides[:raw_acl]

        unless acl
          self.acl = []
          [*overrides[ :deny]].compact.each { |ip| acl << 'deny' << ip }
          [*overrides[:allow]].compact.each { |ip| acl << 'allow' << ip }
          acl.concat %w[allow 127.0.0.1] if acl.empty?
        end
      end
    end
    add_configuration_for :Drb

    class RailsConfiguration < AbstractConfiguration

      attr_accessor :rails_root, :environment
      def initialize(options)
        path_to_rails, environment = check_options options
        @rails_root = File.expand_path(path_to_rails)
        @environment = environment.to_sym
      end

      private

      def check_options(options)
        options = options.clone
        path    = options.delete :path
        env     = options.delete :env
        raise ArgumentError, "Unrecognied argument(s) #{options.keys.to_sentence} in Rails initializer!" unless options.size.zero?
        raise ArgumentError, "Must supply an :env argument to the Rails initializer!" unless env
        raise ArgumentError, "Must supply an :path argument to the Rails initializer!" unless path
        [path, env]
      end

    end
    add_configuration_for :Rails

    class XMPPConfiguration < AbstractConfiguration

      attr_accessor :jid, :password, :server, :port
      def initialize(options)
        jid, password, server, port = check_options options
        @jid = jid
        @password = password
        @server = server
        @port = port
      end

      class << self
        def default_port
          5222
        end
      end

      private

      def check_options(options)
        options  = options.clone
        jid      = options.delete :jid
        password = options.delete :password
        server   = options.delete :server
        port     = options.delete :port
        raise ArgumentError, "Unrecognied argument(s) #{options.keys.to_sentence} in XMPP initializer!" unless options.size.zero?
        raise ArgumentError, "Must supply a :jid argument to the XMPP initializer!" unless jid
        raise ArgumentError, "Must supply a :password argument to the XMPP initializer!" unless password
        if server
          port ||= self.class.default_port
        else
          raise ArgumentError, "Must supply a :server argument as well as :port to the XMPP initializer!" if port
        end
        [jid, password, server, port]
      end

    end
    add_configuration_for :XMPP

  end
end
