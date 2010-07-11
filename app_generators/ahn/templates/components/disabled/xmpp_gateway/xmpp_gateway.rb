initialization do
  
  XMPPBot.message :body do |m|
    XMPPBot.say m.from, "You said: #{m.body}"
  end
  
  XMPPBot.subscription :request? do |s|
    XMPPBot.write_to_stream s.approve!
  end

end