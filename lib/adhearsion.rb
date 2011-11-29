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
  autoload :Calls
  autoload :Configuration
  autoload :Console
  autoload :Constants
  autoload :Conveniences
  autoload :DialPlan
  autoload :Dispatcher
  autoload :DSL
  autoload :Events
  autoload :Initializer
  autoload :Logging
  autoload :OutboundCall
  autoload :Plugin
  autoload :Punchblock
  autoload :Version

  # Sets up the Gem require path.
  AHN_INSTALL_DIR = File.expand_path(File.dirname(__FILE__) + "/..")

  class << self

    def ahn_root=(path)
      Adhearsion.config[:platform].root = path.nil? ? nil : PathString.new(File.expand_path(path))
    end

    def config &block
      @config ||= Configuration.new &block
    end

    def config=(value)
      @config=value
    end

    def active_calls
      @calls ||= Calls.new
    end

    def receive_call_from(offer)
      Call.new(offer).tap do |call|
        active_calls << call
      end
    end

    def status
      Adhearsion::Process.state_name
    end

    def remove_inactive_call(call)
      active_calls.remove_inactive_call(call)
    end
  end

  Hangup = Class.new StandardError # At the moment, we'll just use this to end a call-handling Thread
  PlaybackError = Class.new StandardError # Represents failure to play audio, such as when the sound file cannot be found
  RecordError = Class.new StandardError # Represents failure to record such as when a file cannot be written.
end
