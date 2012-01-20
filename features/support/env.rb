require 'simplecov'
require 'simplecov-rcov'
class SimpleCov::Formatter::MergedFormatter
  def format(result)
     SimpleCov::Formatter::HTMLFormatter.new.format(result)
     SimpleCov::Formatter::RcovFormatter.new.format(result)
  end
end
SimpleCov.formatter = SimpleCov::Formatter::MergedFormatter
SimpleCov.start do
  add_filter "/vendor/"
end

JRUBY_OPTS_SAVED=ENV['JRUBY_OPTS']
JAVA_OPTS_SAVED=ENV['JAVA_OPTS']

require 'cucumber'
require 'aruba/cucumber'
require 'adhearsion'

module ChildProcess
  class << self
    def os
      @os ||= (
        require "rbconfig"
        host_os = RbConfig::CONFIG['host_os'].downcase

        case host_os
        when /linux/
          :linux
        when /darwin|mac os/
          :macosx
        when /mswin|msys|mingw32/
          :windows
        when /cygwin/
          :cygwin
        when /solaris|sunos/
          :solaris
        when /bsd/
          :bsd
        else
          raise Error, "unknown os: #{host_os.inspect}"
        end
      )
    end
  end # class << self
end # ChildProcess

Before do
  @aruba_timeout_seconds = ENV['ARUBA_TIMEOUT'] || RUBY_PLATFORM == 'java' ? 120 : 60
end

# TODO: check for name space / run issues
# NOTE: this will not stop a forked process (eg. daemon mode)
After do
  terminate_processes!
end

# Aruba upstream overwrites these variables so set them here until it is fixed.
Aruba.configure do |config|
  config.before_cmd do |cmd|
    set_env('JRUBY_OPTS', "#{ENV['JRUBY_OPTS']} #{JRUBY_OPTS_SAVED}")
    set_env('JAVA_OPTS', "#{ENV['JAVA_OPTS']} #{JAVA_OPTS_SAVED}")
  end
end if RUBY_PLATFORM == 'java'
