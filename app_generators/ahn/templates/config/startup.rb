unless defined? Adhearsion
  if File.exists? File.dirname(__FILE__) + "/../adhearsion/lib/adhearsion.rb"
    # If you wish to freeze a copy of Adhearsion to this app, simply place a copy of Adhearsion
    # into a folder named "adhearsion" within this app's main directory.
    require File.dirname(__FILE__) + "/../adhearsion/lib/adhearsion.rb"
  else  
    require 'rubygems'
    gem 'adhearsion', '>= 0.7.999'
    require 'adhearsion'
  end
end

Adhearsion::Configuration.configure do |config|
  
  # Supported levels (in increasing severity) -- :debug < :info < :warn < :error < :fatal
  config.logging :level => :info
  
  # Whether incoming calls be automatically answered. Defaults to true.
  # config.automatically_answer_incoming_calls = false
  
  # Whether the other end hanging up should end the call immediately. Defaults to true.
  # config.end_call_on_hangup = false
  
  # Whether to end the call immediately if an unrescued exception is caught. Defaults to true.
  # config.end_call_on_error = false
  
  # By default Asterisk is enabled with the default settings
  config.enable_asterisk
  # config.asterisk.enable_ami :host => "127.0.0.1", :username => "admin", :password => "password"
  
  # To change the host IP or port on which the AGI server listens, use this:
  # config.enable_asterisk :listening_port => 4574, :listening_host => "127.0.0.1"
  
  # config.enable_drb 
  
  # Streamlined Rails integration! The first argument should be a relative or absolute path to 
  # the Rails app folder with which you're integrating. The second argument must be one of the 
  # the following: :development, :production, or :test.
  
  # config.enable_rails :path => 'gui', :env => :development
  
  # Note: You CANNOT do enable_rails and enable_database at the same time. When you enable Rails,
  # it will automatically connect to same database Rails does and load the Rails app's models.
  
  # Configure a database to use ActiveRecord-backed models. See ActiveRecord::Base.establish_connection
  # for the appropriate settings here.
  # config.enable_database :adapter  => 'mysql',
  #                        :username => 'joe', 
  #                        :password => 'secret',
  #                        :host     => 'db.example.org'
end

Adhearsion::Initializer.start_from_init_file(__FILE__, File.dirname(__FILE__) + "/..")