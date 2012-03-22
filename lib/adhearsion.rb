# encoding: utf-8

abort "ERROR: You are running Adhearsion on an unsupported version of Ruby (Ruby #{RUBY_VERSION} #{RUBY_RELEASE_DATE})! Please upgrade to at least Ruby v1.9.2, JRuby 1.6.5 or Rubinius 2.0." if RUBY_VERSION < "1.9.2"

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
  celluloid

  adhearsion/version
  adhearsion/foundation
}.each { |f| require f }

module Adhearsion
  extend ActiveSupport::Autoload

  Error = Class.new StandardError

  autoload :Process
  autoload :Call
  autoload :CallController
  autoload :Calls
  autoload :Configuration
  autoload :Console
  autoload :Conveniences
  autoload :Dispatcher
  autoload :Events
  autoload :Generators
  autoload :MenuDSL
  autoload :Initializer
  autoload :Logging
  autoload :OutboundCall
  autoload :Plugin
  autoload :Router

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
      if @calls && @calls.alive?
        @calls
      else
        @calls = Calls.new
      end
    end

    def status
      Adhearsion::Process.state_name
    end
  end
end

Celluloid.exception_handler { |e| Adhearsion::Events.trigger :exception, e }
