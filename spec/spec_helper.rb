# encoding: utf-8

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
  flexmock/rspec
  active_support
  stringio
  countdownlatch
  adhearsion
}.each { |f| require f }

Thread.abort_on_exception = true

UUID.state_file = false

Bundler.require(:default, :test) if defined?(Bundler)

Dir[File.dirname(__FILE__) + "/support/**/*.rb"].each { |f| require f }

RSpec.configure do |config|
  config.mock_framework = :flexmock
  config.filter_run :focus => true
  config.run_all_when_everything_filtered = true
  config.color_enabled = true

  config.before :each do
    Adhearsion.router = nil
  end

  config.after :each do
    Celluloid.shutdown
  end
end

Adhearsion::Events.exeption do |e|
  puts e.message
  puts e.backtrace.join("\n")
end

Adhearsion::Logging.silence!

# Test modules for #mixin methods
module TestBiscuit
  def throwadogabone
    true
  end
end

module MarmaladeIsBetterThanJam
  def sobittersweet
    true
  end
end

def new_uuid
  UUID.new.generate.to_s
end
alias :random_call_id :new_uuid
