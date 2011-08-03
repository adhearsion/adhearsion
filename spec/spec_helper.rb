unless ENV['SKIP_RCOV']
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
    add_filter "/spec/"
  end
end

Dir.chdir File.join(File.dirname(__FILE__), '..')
$:.push('.')
$: << File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib'))
$: << File.expand_path('lib')
$: << File.dirname(__FILE__)

%w{
  rubygems
  rspec/core
  bundler/setup
  flexmock/rspec
  active_support
  rubigen
  pp
  stringio
  adhearsion
  adhearsion/voip/asterisk
  adhearsion/component_manager
}.each { |f| require f }

Dir[File.dirname(__FILE__) + "/support/**/*.rb"].each { |f| require f }

RSpec.configure do |config|
  config.mock_framework = :flexmock
  config.filter_run_excluding :ignore => true
  config.filter_run :focus => true
  config.run_all_when_everything_filtered = true
  config.color_enabled = true
end

Adhearsion::Initializer.ahn_root = File.dirname(__FILE__) + '/fixtures'
Adhearsion::Logging.silence!
