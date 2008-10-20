require 'rubygems'
require 'eventmachine'

module EchoServer
  def receive_data(data)
    send_data ">> You Sent: #{data}\n"
    close_connection if data =~ /quit/i
  end
end

EventMachine.run do
  EventMachine.start_server '0.0.0.0', 1337, EchoServer
end
