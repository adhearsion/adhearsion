require 'adhearsion/basic_configuration'

module Adhearsion

  class Configuration < BasicConfiguration

    attr_accessor :ahnrc

    def initialize
      super
      load_default_config
    end

    def load_default_config
      self.class.load_default_config(self)
    end

    [:rails, :database, :xmpp, :drb].each do |type|
      define_method("load_#{type}_configuration".to_sym) do |params = {}|
        self.class.send("load_#{type}_configuration".to_sym, self, params)
      end
      
      # deprecated behaviour
      module_eval 'alias :"enable_#{type}" :"load_#{type}_configuration"'
    end


    # Direct access to a specific plugin configuration values
    def [] value
      return self.plugins.send(value.to_sym)
    end

    def logging options
      Adhearsion::Logging.logging_level = options[:level]             if options.has_key? :level
      Adhearsion::Logging.outputters    = Array(options[:outputters]) if options.has_key? :outputters
      Adhearsion::Logging.formatter     = options[:formatter]         if options.has_key? :formatter
      #Adhearsion::Logging::AdhearsionLogger.formatters = Array(options[:formatter]) * Adhearsion::Logging::AdhearsionLogger.outputters.count if options.has_key? :formatter
    end

    def plugins
      @plugins ||= BasicConfiguration.new
    end

    def plugins_definitions
      @plugins_definitions ||= {}
    end

    def show_configuration element = :core, opts = {}
      case element
      when :core
        return self.values.inject([]) do |_values, elem|
          unless self.send(elem).kind_of? Adhearsion::BasicConfiguration
            _values << "#{elem} => #{self.send(elem)}"
          end
          _values
        end
      else
        if opts[:description]
          
        else
          self[element]
        end
      end
    end

    ##
    # Load the contents of an .ahnrc file into this Configuration.
    #
    # @param [String, Hash] ahnrc String of YAML .ahnrc data or a Hash of the pre-loaded YAML data structure
    #
    def ahnrc=(new_ahnrc)
      @ahnrc = case new_ahnrc
      when Hash
        new_ahnrc.clone.freeze
      when String
        YAML.load(new_ahnrc).freeze
      end
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
      queried_nested_setting = path_through_config.flatten.inject(@ahnrc) do |hash, key_name|
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

    def files_from_glob(glob)
      Dir.glob "#{Adhearsion.config.root}/#{glob}"
    end

    class << self

      # deprecated way to get Adhearsion configuration
      def configure
        yield Adhearsion.config
      end

      def load_default_config config
        config.automatically_accept_incoming_calls = true
        config.end_call_on_hangup                  = true
        config.end_call_on_error                   = true

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
        config
      end

      def load_rails_configuration(config, params = {})
        config.add_configuration_for(:rails)
        config.rails.rails_root  = params[:path] or raise ArgumentError, "Must supply an :path argument to the Rails initializer!"
        config.rails.environment = params[:env] || params[:environment] or raise ArgumentError, "Must supply an :env argument to the Rails initializer!"
        config.rails.rails_root  = File.expand_path(config.rails.rails_root)
      end

      def load_database_configuration(config, params = {})
        params = params.dup
        config.add_configuration_for(:database)
        config.database.orm        = params.delete(:orm) || :active_record
        config.database.connection_options = params
      end

      def load_xmpp_configuration(config, params = {})
        params = params.dup
        config.add_configuration_for(:xmpp)

        config.xmpp.jid      = params[:jid] or raise ArgumentError, "Must supply a :jid argument to the XMPP initializer!"
        config.xmpp.password = params[:password] or raise ArgumentError, "Must supply a :password argument to the XMPP initializer!"
        config.xmpp.server   = params[:server] or raise ArgumentError, "Must supply a :server argument to the XMPP initializer!"
        config.xmpp.port     = params[:port] || 5222
      end

      def load_drb_configuration(config, params = {})
        params = params.dup
        config.add_configuration_for(:drb)
        config.drb.port = params[:port] || 9050
        config.drb.host = params[:host] || "localhost"
        config.drb.acl  = params[:acl] || params[:raw_acl] || nil
        unless config.drb.acl
          config.drb.acl = []
          [*params[ :deny]].compact.each { |ip| config.drb.acl << 'deny' << ip }
          [*params[:allow]].compact.each { |ip| config.drb.acl << 'allow' << ip }
          config.drb.acl.concat %w[allow 127.0.0.1] if config.drb.acl.empty?
        end
      end
    end

  end
end
