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

%w{
  rubygems
  bundler/setup
  flexmock
  flexmock/rspec
  active_support
  rubigen
  stringio
  countdownlatch
  adhearsion
}.each { |f| require f }

Bundler.require(:default, :test) if defined?(Bundler)

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

Foo = Class.new

Bar = Class.new Foo
