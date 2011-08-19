# Check the Ruby version
STDERR.puts "WARNING: You are running Adhearsion in an unsupported
version of Ruby (Ruby #{RUBY_VERSION} #{RUBY_RELEASE_DATE})!
Please upgrade to at least Ruby v1.8.5." if RUBY_VERSION < "1.8.5"

$: << File.expand_path(File.dirname(__FILE__))

%w{
  rubygems
  bundler/setup

  active_support/all
  uuid
  future-resource
  punchblock
  ostruct

  adhearsion/foundation/all
}.each { |f| require f }

module Adhearsion
  extend ActiveSupport::Autoload

  autoload :Asterisk
  autoload :Call
  autoload :CallRouting
  autoload :Calls
  autoload :Commands
  autoload :Components
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
  autoload :Rayo
  autoload :Version

  # Sets up the Gem require path.
  AHN_INSTALL_DIR = File.expand_path(File.dirname(__FILE__) + "/..")
  AHN_CONFIG = Configuration.new

  ##
  # This Array holds all the Threads whose life matters. Adhearsion will not exit until all of these have died.
  #
  IMPORTANT_THREADS = []

  class << self
    def active_calls
      @calls ||= Calls.new
    end

    def receive_call_from(offer)
      Call.new(offer).tap do |call|
        active_calls << call
      end
    end

    def remove_inactive_call(call)
      active_calls.remove_inactive_call(call)
    end
  end

  Hangup = Class.new StandardError # At the moment, we'll just use this to end a call-handling Thread
  PlaybackError = Class.new StandardError # Represents failure to play audio, such as when the sound file cannot be found
  RecordError = Class.new StandardError # Represents failure to record such as when a file cannot be written.
end
