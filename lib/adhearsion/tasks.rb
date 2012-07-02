# encoding: utf-8

require 'adhearsion'

Dir[File.join(File.dirname(__FILE__), "tasks/*.rb")].each do |file|
  require file
end

Adhearsion::Plugin.load_tasks

puts "\nAdhearsion configured environment: #{Adhearsion.config.platform.environment}\n" unless ARGV.empty?

desc "Dump useful information about this application's Adhearsion environment"
task :about do
  puts "Adhearsion version: #{Adhearsion::VERSION}"
end

task :default => :about
