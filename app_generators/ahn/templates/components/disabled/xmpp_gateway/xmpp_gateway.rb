initialization do
  
  XMPP::Connection.message :body do |m|
    XMPP::Connection.say m.from, "You said: #{m.body}"
  end
  
  XMPP::Connection.subscription :request? do |s|
    XMPP::Connection.write_to_stream s.approve!
  end

end