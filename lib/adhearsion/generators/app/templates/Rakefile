#!/usr/bin/env rake

require File.expand_path('../config/environment',  __FILE__)

require 'adhearsion/tasks'

begin
  require 'rspec/core/rake_task'
  RSpec::Core::RakeTask.new(:spec)
  task :default => :spec
rescue LoadError
  task :default => :about
end
