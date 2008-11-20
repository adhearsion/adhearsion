# This is a file which shows you how to use the Asterisk Manager Interface library in a separate process from Adhearsion.
require 'pp'

PATH_TO_ADHEARSION = File.join(File.dirname(__FILE__), "/../..")

MANAGER_CONNECTION_INFORMATION = {
  :host     => "10.0.1.97",
  :username     => "jicksta",
  :password => "roflcopter",
  :events   => true
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

interface = ManagerInterface.connect MANAGER_CONNECTION_INFORMATION

threads = Array.new(100) do
  Thread.new do
    response = interface.send_action("SIPPeers")
    abort "ZOMG" if response.size != 2
    # sleep "0.#{rand(1000)}".to_f
  end
end

threads.each { |t| t.join }