require 'stomp'

# TODO: Recover from a disconnect!

initialization do
  user = COMPONENTS.stomp_gateway[:user] || ""
  pass = COMPONENTS.stomp_gateway[:pass] || ""
  host = COMPONENTS.stomp_gateway[:host] || "localhost"
  port = COMPONENTS.stomp_gateway[:port] || 61613
  
  ::StompGatewayConnection = Stomp::Client.open(user, pass, host, port)
  
  subscriptions = COMPONENTS.stomp_gateway["subscriptions"]
  
  ahn_log.stomp_gateway "Connection established. Subscriptions: #{subscriptions.inspect}"
  
  Events.register_namespace_name "/stomp"
  
  subscriptions.each do |subscription|
    Events.register_namespace_name "/stomp/#{subscription}"
    ::StompGatewayConnection.subscribe subscription do |event|
      Adhearsion::Events.trigger ["stomp", subscription], event
    end
  end
  
end

methods_for :global do
  def send_stomp(destination, message, headers={})
    ::StompGatewayConnection.send(destination, message, headers)
  end
end

# In the future, I may add a methods_for(:events) method which allows synchronous messaging.