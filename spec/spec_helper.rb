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
  config.filter_run :focus => true
  config.run_all_when_everything_filtered = true
  config.color = true

  config.mock_with :rspec do |mocks|
    mocks.add_stub_and_should_receive_to Celluloid::AbstractProxy
  end

  config.raise_errors_for_deprecations!

  config.before :suite do
    Adhearsion::Logging.start :trace, Adhearsion.config.core.logging.formatter
    Adhearsion.config.core.after_hangup_lifetime = 10
    Adhearsion::Initializer.new.initialize_exception_logger
  end

  config.before :each do
    Adhearsion.config.core.i18n.locale_path = ["#{File.dirname(__FILE__)}/fixtures/locale"]
    Adhearsion::Initializer.new.setup_i18n_load_path

    Adhearsion.router = nil
    @uuid = SecureRandom.uuid
    allow(Adhearsion).to receive(:new_request_id).and_return @uuid
  end

  config.after :each do
    Timecop.return
    Adhearsion::Events.clear
    if defined?(:Celluloid)
      Celluloid.shutdown
      Adhearsion.active_calls = nil
      Celluloid.boot
    end
  end
end

Adhearsion::Events.exception do |e, _|
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
