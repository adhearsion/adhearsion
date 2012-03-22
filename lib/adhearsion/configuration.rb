# encoding: utf-8

module Adhearsion
  class Configuration

    ConfigurationError = Class.new Adhearsion::Error # Error raised while trying to configure a non existent plugin

    ##
    # Initialize the configuration object
    #
    # * &block platform configuration block
    # Adhearsion::Configuration.new do
    #   foo "bar", :desc => "My description"
    # end
    #
    # @return [Adhearsion::Configuration]
    def initialize(&block)
      initialize_environments

      Loquacious.env_config = true
      Loquacious.env_prefix = "AHN"

      Loquacious::Configuration.for :platform do
        root nil, :desc => "Adhearsion application root folder"

        lib "lib", :desc => <<-__
          Folder to include the own libraries to be used. Adhearsion loads any ruby file
          located into this folder during the bootstrap process. Set to nil if you do not
          want these files to be loaded. This folder is relative to the application root folder.
        __

        environment :development, :transform => Proc.new { |v| v.to_sym }, :desc => <<-__
          Active environment. Supported values: development, production, staging, test
        __

        process_name "ahn", :desc => <<-__
          Adhearsion process name, useful to make it easier to find in the process list
          Pro tip: set this to your application's name and you can do "killall myapp"
          Does not work under JRuby.
        __

        desc "Log configuration"
        logging {
          level :info, :transform => Proc.new { |v| v.to_sym }, :desc => <<-__
            Supported levels (in increasing severity) -- :trace < :debug < :info < :warn < :error < :fatal
          __
          outputters ["log/adhearsion.log"], :transform => Proc.new { |val| Array(val) }, :desc => <<-__
            An array of log outputters to use. The default is to log to stdout and log/adhearsion.log.
            Each item must be either a string to use as a filename, or a valid Logging appender (see http://github.com/TwP/logging)
          __
          formatter nil, :desc => <<-__
            A log formatter to apply to all active outputters. If nil, the Adhearsion default formatter will be used.
          __
        }
      end

      Loquacious::Configuration.for :platform, &block if block_given?

      self
    end

    def initialize_environments
      # Create a method per each valid environment that, when invoked, may execute
      # the block received if the environment is active
      valid_environments.each do |enviro|
        add_environment enviro
      end
    end

    def valid_environment?(env)
      env && self.valid_environments.include?(env.to_sym)
    end

    def valid_environments
      @valid_environments ||= [:production, :development, :staging, :test]
    end

    def add_environment(env)
      return if self.class.method_defined? env.to_sym
      self.class.send(:define_method, env.to_sym) do |*args, &block|
        unless block.nil? || env != self.platform.environment.to_sym
          self.instance_eval(&block)
        end
        self
      end
    end

    ##
    # Direct access to a specific configuration object
    #
    # Adhearsion.config[:platform] => returns the configuration object associated to the Adhearsion platform
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
      platform.root
    end

    ##
    # Handle the Adhearsion platform configuration
    #
    # It accepts a block that will be executed in the Adhearsion config var environment
    # to update the desired values
    #
    # Adhearsion.config.platform do
    #   foo "bar", :desc => "My new description"
    # end
    #
    # values = Adhearsion.config.platform
    # values.foo => "bar"
    #
    # @return [Loquacious::Configuration] configuration object or nil if the plugin does not exist
    def platform(&block)
      Loquacious::Configuration.for :platform, &block
    end

    ##
    # Fetchs the configuration info for the Adhearsion platform or a specific plugin
    # @param name [Symbol]
    #     - :all      => Adhearsion platform and all the loaded plugins
    #     - nil       => Adhearsion platform configuration
    #     - :platform => Adhearsion platform configuration
    #     - :<plugin-config-name> => Adhearsion plugin configuration
    #
    # @param args [Hash]
    #     - @option :show_values [Boolean] true | false to return the current values or just the description
    #
    # @return string with the configuration description/values
    def description(name, args = {:show_values => true})
      desc = StringIO.new

      name.nil? and name = :platform
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
