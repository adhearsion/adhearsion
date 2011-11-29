require 'adhearsion/punchblock_plugin'

begin
  require "#{Dir.pwd}/config/startup.rb"
rescue Exception => ex
  STDERR.puts "\nCannot find the Adhearsion application startup file: #{ex}"
end

namespace :adhearsion do

  namespace :config do

    desc "Show configuration values in STDOUT; it accepts a parameter: [nil|platform|<plugin-name>|all]"
    task :show, :name do |t, args|
      name = args.name.nil? ? :all : args.name.to_sym
      puts Adhearsion.config.description name, :show_values => true
    end

    desc "Show configuration description in STDOUT; it accepts a parameter: [nil|platform|<plugin-name>|all]"
    task :desc, :name do |t, args|
      name = args.name.nil? ? :all : args.name.to_sym
      puts Adhearsion.config.description name, :show_values => false
    end
  end
end
