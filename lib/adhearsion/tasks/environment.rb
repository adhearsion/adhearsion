# encoding: utf-8

task :environment do
  require 'adhearsion/rayo/plugin'

  begin
    Adhearsion.config # load default config vlaues
    initializer = Adhearsion::Initializer.new
    initializer.configure_plugins
    initializer.load_lib_folder
    initializer.load_config_file
  rescue Exception => ex
    STDERR.puts "\nError while loading application configuration file: #{ex}"
  end
end
