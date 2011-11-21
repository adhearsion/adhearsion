require 'adhearsion/basic_configuration'

module Adhearsion

  class Configuration

    attr_accessor :ahnrc

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

    def method_missing method_name, *args
      platform.send method_name, *args
    end

    def platform
      @platforms ||= BasicConfiguration.new
    end

    # return Adhearsion or plugins current configuration or config description
    #
    # show_configuration :core          => shows the Adhearsion platform configuration values
    # show_configuration :<plugin_name> => shows the plugin_name configuration values
    # show_configuration :<plugin_name> => description => true: describes the valid values for a plugin configuration
    # show_configuration :all           => shows all the configuration values (platform and plugins)
    #
    # @param element symbol identifing:
    #     - :core          => the Adhearsion platform
    #     - :<plugin_name> => a specific plugin name
    #     - :all           => core and every plugins config values
    #
    # @param opts Hash of possible options
    #     - :description (true|false): either retrieve current config values (by default or false value) or the description
    #
    # @return string
    def show_configuration element = :core, opts = {}
      if element.kind_of? Array
        return element.map { |elem| show_configuration elem, opts }.join("")
      end
      case element
      when :core
        title = element.to_s.dup.concat(" configuration")
        title.
            concat("\n").
            concat("-"*title.to_s.length).
            concat("\n").
            concat platform.to_s.
            concat("\n"*2)
      when :all
        return show_configuration self.plugins.values.dup.unshift(:core), opts
        #show_configuration :core
      else
        if opts[:description]
          title = element.to_s.dup.concat(" configuration info")
          title.
              concat("\n").
              concat("-"*title.to_s.length).
              concat("\n").
              concat(self.plugins_definitions[element].join("\n")).
              concat("\n"*2)
        else
          title = element.to_s.dup.concat(" configuration")
          title.
              concat("\n").
              concat("-"*title.to_s.length).
              concat("\n").
              concat(self[element].to_s).
              concat("\n"*2)
          
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
