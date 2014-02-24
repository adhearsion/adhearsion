# encoding: utf-8

require 'adhearsion'

initializer = Adhearsion::Initializer.new
initializer.configure_plugins
initializer.load_lib_folder
initializer.load_config_file
initializer.load_events_file
initializer.load_routes_file
