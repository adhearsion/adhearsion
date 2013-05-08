# encoding: utf-8

abort "ERROR: You are running Adhearsion on an unsupported version of Ruby (Ruby #{RUBY_VERSION} #{RUBY_RELEASE_DATE})! Please upgrade to at least Ruby v1.9.2, JRuby 1.7.0 or Rubinius 2.0." if RUBY_VERSION < "1.9.2"

%w{
  active_support/all
  punchblock
  celluloid

  adhearsion/version
  adhearsion/foundation
}.each { |f| require f }

module Adhearsion
  extend ActiveSupport::Autoload

  Error = Class.new StandardError

  autoload :Call
  autoload :CallController
  autoload :Calls
  autoload :Configuration
  autoload :Console
  autoload :Dispatcher
  autoload :Events
  autoload :Generators
  autoload :Initializer
  autoload :Logging
  autoload :OutboundCall
  autoload :Plugin
  autoload :Process
  autoload :Router
  autoload :Statistics

  class << self

    #
    # Sets the application path
    # @param[String|Pathname] The application path to set
    #
    def root=(path)
      Adhearsion.config[:platform].root = path.nil? ? nil : File.expand_path(path)
    end

    #
    # Returns the current application path
    # @return [Pathname] The application path
    #
    def root
      Adhearsion.config[:platform].root
    end

    #
    # @deprecated Use #root= instead
    #
    def ahn_root=(path)
      Adhearsion.deprecated "#Adhearsion.root="
      Adhearsion.root = path
    end

    def config(&block)
      @config ||= initialize_config
      block_given? and yield @config
      @config
    end

    def deprecated(new_method)
      logger.info "#{caller[0]} - This method is deprecated, please use #{new_method}."
      logger.warn caller.join("\n")
    end

    def initialize_config
      _config = Configuration.new
      env = ENV['AHN_ENV'] || ENV['RAILS_ENV']
      env = env.to_sym if env.respond_to? :to_sym
      env = nil unless _config.valid_environment? env
      _config.platform.environment = env if env
      _config
    end

    def environments
      config.valid_environments
    end

    def config=(config)
      @config = config
    end

    def router(&block)
      @router ||= Router.new(&block || Proc.new {})
    end

    def router=(other)
      @router = other
    end

    def active_calls
      Celluloid::Actor[:active_calls] || Calls.supervise_as(:active_calls)
      Celluloid::Actor[:active_calls]
    end

    #
    # @return [Adhearsion::Statistics] a statistics aggregator object capable of producing stats dumps
    def statistics
      unless Celluloid::Actor[:statistics]
        Statistics.supervise_as :statistics
        Statistics.setup_event_handlers
      end
      Celluloid::Actor[:statistics]
    end

    def status
      Adhearsion::Process.state_name
    end
  end
end

Celluloid.exception_handler { |e| Adhearsion::Events.trigger :exception, e }

module Celluloid
  class << self
    undef :logger
    def logger
      ::Logging.logger['Celluloid']
    end
  end
end
