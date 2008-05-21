events.ahn.before_call.each do |event|
	defer :handle_something, :limit => 3 do
	  event.
	end
end

events.freeswitch.event_socket.each do |event|

end
