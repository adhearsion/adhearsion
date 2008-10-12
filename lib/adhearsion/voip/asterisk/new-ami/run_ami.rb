require File.join(File.dirname(__FILE__), 'ami.rb')

parser = AmiStreamParser.new

packets = ["Asterisk Call Manager/1.0\r\n",
           "Response: Success\r\nMessage: Authentication accepted\r\n\r\n",
           "Response: Pong\r\n\r\n",
           "Response: Pong\r\nActionID: 1337\r\n\r\n",
           "Event: Registry\r\nPrivilege: system,all\r\nChannelDriver: SIP\r\nDomain: proxy.voip.ms\r\nStatus: Registered\r\n\r\n"]

packets.each do |packet|
  p parser << packet
end