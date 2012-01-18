require 'adhearsion/punchblock_plugin'

begin
  Adhearsion.config # load default config vlaues
  require "#{Dir.pwd}/config/adhearsion.rb"
rescue Exception => ex
  STDERR.puts "\nError while loading application configuration file: #{ex}"
end

namespace :adhearsion do

  namespace :config do

    desc "Show configuration values in STDOUT; it accepts a parameter: [nil|platform|<plugin-name>|all]"
    task :show, :name do |t, args|
      name = args.name.nil? ? :all : args.name.to_sym
      puts "\nAdhearsion.config do |config|\n\n"
      puts Adhearsion.config.description name, :show_values => true
      puts "end"
    end

    desc "Show configuration description in STDOUT; it accepts a parameter: [nil|platform|<plugin-name>|all]"
    task :desc, :name do |t, args|
      name = args.name.nil? ? :all : args.name.to_sym
      puts Adhearsion.config.description name, :show_values => false
    end
  end
end
