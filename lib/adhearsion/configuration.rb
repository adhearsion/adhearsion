
module Adhearsion

  class Configuration

    ##
    # Initialize the configuration object
    #
    # * &block platform configuration block
    # Adhearsion::Configuration.new do
    #   foo "bar", :desc => "My description"
    # end
    #
    # @return [Adhearsion::Configuration]
    def initialize &block
      Loquacious::Configuration.for(:platform) do
        root nil, :desc => "Adhearsion application root folder"
        automatically_accept_incoming_calls true, :desc => "Adhearsion will accept automatically any inbound call"

        desc "Log configuration"
        logging {
          level :info, :desc => <<-__
            Supported levels (in increasing severity) -- :trace < :debug < :info < :warn < :error < :fatal
          __
          outputters nil, :desc => <<-__
            An array of log outputters to use. The default is to log to stdout and log/adhearsion.log
          __
          formatters ::Logging::Layouts.basic({:format_as => :string, :backtrace => true}), :desc => <<-__
            An array of log formatters to apply to the outputters in use
          __
          formatter nil, :desc => <<-__
            A log formatter to apply to all active outputters
          __
        }
      end
      if block_given?
        Loquacious::Configuration.for(:platform, &block)
      end
      self
    end


    ##
    # Direct access to a specific configuration object
    #
    # Adhearsion.config[:platform] => returns the configuration object associated to the Adhearsion platform
    #
    # @return [Loquacious::Configuration] configuration object or nil if the plugin does not exist
    def [] value
      self.send value.to_sym
    end

    def logging options
      Adhearsion::Logging.logging_level = options[:level]             if options.has_key? :level
      Adhearsion::Logging.outputters    = Array(options[:outputters]) if options.has_key? :outputters
      Adhearsion::Logging.formatter     = options[:formatter]         if options.has_key? :formatter
      #Adhearsion::Logging::AdhearsionLogger.formatters = Array(options[:formatter]) * Adhearsion::Logging::AdhearsionLogger.outputters.count if options.has_key? :formatter
    end

    ##
    # Wrapper to access to a specific configuration object
    #
    # Adhearsion.config.foo => returns the configuration object associated to the foo plugin
    def method_missing method_name, *args, &block
      Loquacious::Configuration.for(method_name, &block)
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
    def platform &block
      Loquacious::Configuration.for(:platform, &block)
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
    def description name, args = {:show_values => true}
      desc = StringIO.new

      name.nil? and name = :platform
      if name.eql? :all
        value = ""
        Loquacious::Configuration.instance_variable_get("@table").keys.map do |config|
          value.concat description config, args
        end
        return value
      else
        if Loquacious::Configuration.for(name).nil?
          return ""
        end
        config = Loquacious::Configuration.help_for name,
                                :name_leader => "| * ",
                                :desc_leader => "| ",
                                :colorize    => true,
                                :io          => desc
        config.show :values => args[:show_values]
        "\n******* Configuration for #{name} **************\n\n#{desc.string}"
      end
    end
  end
end
