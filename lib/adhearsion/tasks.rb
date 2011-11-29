require 'rake/testtask'
require 'adhearsion'

%w<components 
configuration
database 
testing 
generating 
lint
plugins
deprecations>.each do |file|
  require "adhearsion/tasks/#{file}"
end


namespace :adhearsion do
  desc "Dump useful information about this application's adhearsion environment"
  task :about do
    puts "Adhearsion version: #{Adhearsion::VERSION::STRING}"
  end
end

task :default => "adhearsion:about"
