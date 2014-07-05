# encoding: utf-8

Given /^PENDING/ do
  skip
end

Given /^JRuby skip test/ do
  skip "Daemonize not supported under JRuby" if RUBY_PLATFORM == 'java'
end
