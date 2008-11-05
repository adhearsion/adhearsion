# This is a file which shows you how to use the Asterisk Manager Interface library in a separate process from Adhearsion.

PATH_TO_ADHEARSION = File.join(File.dirname(__FILE__), "/../..")

MANAGER_CONNECTION_INFORMATION = {
  :hostname => "10.0.1.97",
  :user => "jicksta",
  :password => "roflcopter",
  :events => true
}

require 'rubygems'
begin
  require 'adhearsion'
rescue LoadError
  begin
    require File.join(PATH_TO_ADHEARSION, "/lib/adhearsion")
  rescue LoadError
    abort "Could not find Adhearsion! Please update the PATH_TO_ADHEARSION constant in this file"
  end
end

require 'adhearsion/voip/asterisk/manager_interface'
include Adhearsion::VoIP::Asterisk::Manager

ManagerInterface.standalone do
  interface = ManagerInterface.connect MANAGER_CONNECTION_INFORMATION
  interface.send_action "Ping"
end
