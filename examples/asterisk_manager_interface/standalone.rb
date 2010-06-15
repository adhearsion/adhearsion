# This is a file which shows you how to use the Asterisk Manager Interface library in a standalone Ruby script.

PATH_TO_ADHEARSION = File.join(File.dirname(__FILE__), "/../..")

MANAGER_CONNECTION_INFORMATION = {
  :host     => "10.0.1.97",
  :username => "jicksta",
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

# If you'd like to see the AMI protocol data, change this to :debug
Adhearsion::Logging.logging_level = :warn

# This makes addressing the ManagerInterface class a little cleaner
include Adhearsion::VoIP::Asterisk::Manager

# Let's instantiate a new ManagerInterface object and have it automatically connect using the Hash we defined above.
interface = ManagerInterface.connect MANAGER_CONNECTION_INFORMATION

# Send an AMI action with our new ManagerInterface object. This will return an Array of SIPPeer events.
sip_peers = interface.send_action "SIPPeers"

# Pretty-print the SIP peers on the server

if sip_peers.any?
  sip_peers.each do |peer|
    # Uncomment the following line to view all the headers for each peer.
    # p peer.headers

    peer_name   = peer.headers["ObjectName"]
    peer_status = peer.headers["Status"]

    puts "#{peer_name}: #{peer_status}"
  end
else
  puts "This Asterisk server has no SIP peers!"
end
