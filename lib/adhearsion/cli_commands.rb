# encoding: utf-8

require 'fileutils'
require 'adhearsion/script_ahn_loader'
require 'thor'
require 'adhearsion/generators/controller/controller_generator'
require 'adhearsion/generators/plugin/plugin_generator'
Adhearsion::Generators.add_generator :controller, Adhearsion::Generators::ControllerGenerator
Adhearsion::Generators.add_generator :plugin, Adhearsion::Generators::PluginGenerator

# @private
class Thor
  class Task
    protected

    def sans_backtrace(backtrace, caller)
      saned  = backtrace.reject { |frame| frame =~ FILE_REGEXP || (frame =~ /\.java:/ && RUBY_PLATFORM =~ /java/) }
      saned -= caller
    end
  end
end

module Adhearsion
  module CLI
    require 'adhearsion/cli_commands/plugin_command'
    require 'adhearsion/cli_commands/ahn_command'
    require 'adhearsion/cli_commands/thor_errors'
  end
end
