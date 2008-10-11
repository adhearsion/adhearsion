def on(state)
	case state
	  when :handshake: puts "Hey there!"
	end
end

%%{
	machine server;
	
	action HandshakeOnNewSocketPerformed { on:handshake }
	
	# Execute HandshakeOnNewSocketPerformed after "ohai" is read
	main := "ohai" @HandshakeOnNewSocketPerformed;
}%%

%% write data;
%% write init;
%% write exec;

