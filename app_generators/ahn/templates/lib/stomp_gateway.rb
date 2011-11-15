require 'stomp'

class StompGateway < Adhearsion::Plugin
  # TODO: Recover from a disconnect!

  def connection
    @@connection
  end

  init :stomp_gateway do
    user = ""
    pass = ""
    host = "localhost"
    port = 61613

    @@connection = Stomp::Client.open user, pass, host, port

    subscriptions = [:start_call, :hungup_call]

    logger.info "Connection established. Subscriptions: #{subscriptions.inspect}"

    subscriptions.each do |subscription|
      StompGateway.connection.subscribe subscription do |event|
        Adhearsion::Events.trigger :"stomp_subscription", event
      end
    end

  end

  global :send_stomp do |destination, message, headers = {}|
    StompGateway.connection.send destination, message, headers
  end
end
