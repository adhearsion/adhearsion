# Check the Ruby version
STDERR.puts "WARNING: You are running Adhearsion on an unsupported version of Ruby (Ruby #{RUBY_VERSION} #{RUBY_RELEASE_DATE})! Please upgrade to at least Ruby v1.9.2, JRuby 1.6.4 or Rubinius 2.0." if RUBY_VERSION < "1.9.2"

$: << File.expand_path(File.dirname(__FILE__))

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
  autoload :Constants
  autoload :Conveniences
  autoload :DialplanController
  autoload :Dispatcher
  autoload :DSL
  autoload :Events
  autoload :MenuDSL
  autoload :Initializer
  autoload :Logging
  autoload :OutboundCall
  autoload :Plugin
  autoload :Router
  autoload :Version

  # Sets up the Gem require path.
  AHN_INSTALL_DIR = File.expand_path(File.dirname(__FILE__) + "/..")

  class << self

    def ahn_root=(path)
      Adhearsion.config[:platform].root = path.nil? ? nil : PathString.new(File.expand_path(path))
    end

    def config &block
      @config ||= Configuration.new &block
      block_given? and yield @config
      env = ENV['AHN_ENV']
      unless env.nil?
        env = nil unless Configuration.valid_environments.include?(env.to_sym)
      end
      @config.platform.environment = env if env
      @config
    end

    def config=(config)
      @config=config
    end

    def router(&block)
      @router || @router = Router.new(&block || Proc.new {})
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
  ConfigurationError = Class.new StandardError # Error raised while trying to configura a non existent pluginend
end
