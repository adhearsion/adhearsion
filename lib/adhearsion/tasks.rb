require 'adhearsion'

%w<components 
configuration
database 
testing 
generating 
lint
plugins>.each do |file|
  require "adhearsion/tasks/#{file}"
end

Adhearsion::Plugin.load_tasks

puts "\nAdhearsion configured environment: #{Adhearsion.config.platform.environment}\n" unless ARGV.empty?

namespace :adhearsion do
  desc "Dump useful information about this application's adhearsion environment"
  task :about do
    puts "Adhearsion version: #{Adhearsion::VERSION}"
  end
end

task :default => "adhearsion:about"
