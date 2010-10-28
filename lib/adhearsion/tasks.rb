require 'rake/testtask'
require 'adhearsion'
require 'adhearsion/tasks/components'
require 'adhearsion/tasks/database'
require 'adhearsion/tasks/testing'
require 'adhearsion/tasks/generating'
require 'adhearsion/tasks/lint'
require 'adhearsion/tasks/deprecations'

namespace :adhearsion do
  desc "Dump useful information about this application's adhearsion environment"
  task :about do
    puts "Adhearsion version: #{Adhearsion::VERSION::STRING}"
  end
end

task :default => "adhearsion:about"
