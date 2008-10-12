# Protocol:
# On connect, must send ASCII "ohai". Server responds with ASCII "lol". The server then reads one kilobyte (1024 bytes) and then writes it back reversed

require "gserver"

class Server < GServer
  def serve(io)
    chars = ""
    chars << io.read(1) until chars[-4..-1] == "ohai"
    io.write "lol"
    loop do
      packet = io.read(1024)
      io.write packet.reverse
    end
  end
end

s = Server.new 1337, '0.0.0.0', (1.0/0.0)
s.start
s.join