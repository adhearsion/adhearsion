# Check the Ruby version
STDERR.puts "WARNING: You are running Adhearsion in an unsupported
version of Ruby (Ruby #{RUBY_VERSION} #{RUBY_RELEASE_DATE})!
Please upgrade to at least Ruby v1.8.5." if RUBY_VERSION < "1.8.5"

$: << File.expand_path(File.dirname(__FILE__))

require 'rubygems'
require 'bundler/setup'

require 'active_support/all'
require 'uuid'
require 'future-resource'
require 'punchblock'

require 'adhearsion/foundation/all'

require 'adhearsion/dsl/numerical_string'
require 'adhearsion/dsl/dialplan/parser'
require 'adhearsion/dsl/dialing_dsl'

module Adhearsion
  extend ActiveSupport::Autoload

  autoload :Asterisk
  autoload :Call
  autoload :CallRouting
  autoload :Calls
  autoload :Commands
  autoload :Components
  autoload :Configuration
  autoload :DialPlan
  autoload :Dispatcher
  autoload :Events
  autoload :Initializer
  autoload :Logging
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
