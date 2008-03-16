# Check the Ruby version
STDERR.puts "WARNING: You are running Adhearsion in an unsupported
version of Ruby (Ruby #{RUBY_VERSION} #{RUBY_RELEASE_DATE})!
Please upgrade to at least Ruby v1.8.5." if RUBY_VERSION < "1.8.5"

module Adhearsion
  # Sets up the Gem require path.
  AHN_INSTALL_DIR = File.expand_path(File.dirname(__FILE__) + "/..")
  CONFIG = {}
end

$: << File.expand_path(File.dirname(__FILE__))

require 'rubygems'
require 'adhearsion/version'
require 'adhearsion/voip/call'
require 'adhearsion/voip/dial_plan'
require 'adhearsion/voip/asterisk/special_dial_plan_managers'
require 'adhearsion/core_extensions/all'
require 'adhearsion/blank_slate'
require 'adhearsion/hooks'
require 'adhearsion/logging'
require 'adhearsion/initializer/configuration'
require 'adhearsion/initializer'
require 'adhearsion/initializer/paths'
require 'adhearsion/voip/dsl/numerical_string'
require 'adhearsion/voip/dsl/dialplan/parser'
require 'adhearsion/voip/commands'
require 'adhearsion/voip/asterisk/commands'
require 'adhearsion/voip/dsl/dialing_dsl'
require 'adhearsion/voip/call_routing'