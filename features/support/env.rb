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

require 'cucumber'
require 'aruba/cucumber'
require 'adhearsion'

Before do
    @aruba_timeout_seconds = 10
end

#Aruba.configure do |config|
#  config.before_cmd do |cmd|
#    puts "About to run '#{cmd}'"
#  end
#end
