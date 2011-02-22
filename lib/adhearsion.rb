# Check the Ruby version
STDERR.puts "WARNING: You are running Adhearsion in an unsupported
version of Ruby (Ruby #{RUBY_VERSION} #{RUBY_RELEASE_DATE})!
Please upgrade to at least Ruby v1.8.5." if RUBY_VERSION < "1.8.5"

$: << File.expand_path(File.dirname(__FILE__))

require 'rubygems'
require 'bundler/setup'

require 'adhearsion/version'
require 'adhearsion/voip/call'
require 'adhearsion/voip/dial_plan'
require 'adhearsion/voip/asterisk/special_dial_plan_managers'
require 'adhearsion/foundation/all'
require 'adhearsion/events_support'
require 'adhearsion/logging'
require 'adhearsion/component_manager'
require 'adhearsion/initializer/configuration'
require 'adhearsion/initializer'
require 'adhearsion/voip/dsl/numerical_string'
require 'adhearsion/voip/dsl/dialplan/parser'
require 'adhearsion/voip/commands'
require 'adhearsion/voip/asterisk/commands'
require 'adhearsion/voip/dsl/dialing_dsl'
require 'adhearsion/voip/call_routing'

begin
  # Try ActiveSupport >= 2.3.0
  require 'active_support/all'
rescue LoadError
  # Assume ActiveSupport < 2.3.0
  require 'active_support'
end

module Adhearsion
  # Sets up the Gem require path.
  AHN_INSTALL_DIR = File.expand_path(File.dirname(__FILE__) + "/..")
  AHN_CONFIG = Configuration.new

  ##
  # This Array holds all the Threads whose life matters. Adhearsion will not exit until all of these have died.
  #
  IMPORTANT_THREADS = []

end
