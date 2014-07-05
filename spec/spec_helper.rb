# encoding: utf-8

$testing = true

require 'coveralls'
Coveralls.wear!

%w{
  bundler/setup
  active_support
  stringio
  countdownlatch
  timecop
  adhearsion
}.each { |f| require f }

Thread.abort_on_exception = true

Bundler.require(:default, :test) if defined?(Bundler)

Dir[File.dirname(__FILE__) + "/support/**/*.rb"].each { |f| require f }

RSpec.configure do |config|
  config.mock_framework = :rspec
  config.filter_run :focus => true
  config.run_all_when_everything_filtered = true
  config.color = true

  config.raise_errors_for_deprecations!

  config.mock_with :rspec do |mocks|
    mocks.add_stub_and_should_receive_to Celluloid::AbstractProxy, ThreadSafeArray
  end

  config.before :suite do
    Adhearsion::Logging.start Adhearsion::Logging.default_appenders, :trace, Adhearsion.config.platform.logging.formatter
    Adhearsion.config.platform.after_hangup_lifetime = 10
    Adhearsion::Initializer.new.initialize_exception_logger
  end

  config.before :each do
    Adhearsion.router = nil
    allow(Punchblock).to receive(:new_request_id).and_return 'foo'
  end

  config.after :each do
    Timecop.return
  end
end

Adhearsion::Events.exeption do |e|
  puts e.message
  puts e.backtrace.join("\n")
end

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
  SecureRandom.uuid
end
alias :random_call_id :new_uuid
