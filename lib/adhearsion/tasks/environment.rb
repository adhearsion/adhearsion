# encoding: utf-8

task :environment do
  require 'adhearsion/punchblock_plugin'

  begin
    Adhearsion.config # load default config vlaues
    initializer = Adhearsion::Initializer.new
    initializer.load_lib_folder
    initializer.load_config
  rescue Exception => ex
    STDERR.puts "\nError while loading application configuration file: #{ex}"
  end
end
