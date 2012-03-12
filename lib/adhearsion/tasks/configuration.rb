# encoding: utf-8

namespace :config do
  desc "Show configuration values; accepts a parameter: [nil|platform|<plugin-name>|all]"
  task :show, [:name] => [:environment] do |t, args|
    name = args.name.nil? ? :all : args.name.to_sym
    puts "\nAdhearsion.config do |config|\n\n"
    puts Adhearsion.config.description name, :show_values => true
    puts "end"
  end
end
