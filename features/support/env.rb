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

Before do
  @aruba_timeout_seconds = 30
end

# TODO: check for name space / run issues
# NOTE: this will not stop a forked process (eg. daemon mode)
After do
  terminate_processes!
end

# Aruba upstream overwrites these variables so set them here until it is fixed.
Aruba.configure do |config|
  config.before_cmd do |cmd|
    set_env('JRUBY_OPTS', "#{ENV['JRUBY_OPTS']} #{JRUBY_OPTS_SAVED}") # disable JIT since these processes are so short lived
    set_env('JAVA_OPTS', "#{ENV['JAVA_OPTS']} #{JAVA_OPTS_SAVED}") # force jRuby to use client JVM for faster startup times
  end
end if RUBY_PLATFORM == 'java'
