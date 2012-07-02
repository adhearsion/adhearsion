# encoding: utf-8

Given /^PENDING/ do
  pending
end


Given /^JRuby skip test/ do
  pending "Daemonize not supported under JRuby" if RUBY_PLATFORM == 'java'
end
