# encoding: utf-8

require 'cucumber'
require 'aruba/cucumber'
require 'adhearsion'

Before do
  ENV['AHN_CORE_RECONNECT_ATTEMPTS'] = '0'
  ENV['AHN_CORE_PORT'] = '1'
end

Before '@reconnect' do
  ENV['AHN_CORE_RECONNECT_ATTEMPTS'] = '100'
end
