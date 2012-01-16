abort "ERROR: You are running Adhearsion on an unsupported version of Ruby (Ruby #{RUBY_VERSION} #{RUBY_RELEASE_DATE})! Please upgrade to at least Ruby v1.9.2, JRuby 1.6.5 or Rubinius 2.0." if RUBY_VERSION < "1.9.2"

RUBY_VERSION < "1.9" and require 'rubygems'

%w{
  bundler/setup

  active_support/all
  uuid
  future-resource
  punchblock
  ostruct
  ruby_speech
  countdownlatch
  has_guarded_handlers
  girl_friday
  loquacious

  adhearsion/foundation/all
}.each { |f| require f }

module Adhearsion
  extend ActiveSupport::Autoload

  autoload :Process
  autoload :Call
  autoload :CallController
  autoload :Calls
  autoload :Configuration
  autoload :Console
  autoload :Conveniences
  autoload :DialplanController
  autoload :Dispatcher
  autoload :Events
  autoload :MenuDSL
  autoload :Initializer
  autoload :Logging
  autoload :OutboundCall
  autoload :Plugin
  autoload :Router
  autoload :Version

  class << self

    def ahn_root=(path)
      Adhearsion.config[:platform].root = path.nil? ? nil : File.expand_path(path)
    end

    def config(&block)
      @config ||= initialize_config
      block_given? and yield @config
      @config
    end

    def initialize_config
      _config = Configuration.new
      env = ENV['AHN_ENV']
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
      @calls ||= Calls.new
    end

    def status
      Adhearsion::Process.state_name
    end
  end

  Hangup             = Class.new StandardError # At the moment, we'll just use this to end a call-handling Thread
  PlaybackError      = Class.new StandardError # Represents failure to play audio, such as when the sound file cannot be found
  RecordError        = Class.new StandardError # Represents failure to record such as when a file cannot be written.
  ConfigurationError = Class.new StandardError # Error raised while trying to configure a non existent plugin
end
