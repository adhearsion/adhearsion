module Adhearsion
	module VoIP
		module Asterisk
			class AMI
				module Machine
				%%{
				    machine ami;

						cr = "\r";
						lf = "\n";
						crlf = cr lf;

						action _key 	{ mark("key") 	}
						action key 		{ set("key");		}
						action _value { mark("value") }
						action value 	{ set("value"); }
						Attr = [a-zA-Z\-]+ >_key %key ': ' (any* -- crlf) >_value %value crlf;
						Privilege = "Privilege" >_key %key ': ' (any* -- crlf) >_value %value crlf;
						ActionID = "ActionID" >_key %key ': ' (any* -- crlf) >_value %value crlf;

						action _event { mark("event") }
						action event 	{ set("event"); @current_packet = EventPacket.new(@__ragel_event) }
						Event = "Event: " alpha+ >_event %event crlf;

						action _success { @current_packet = Packet.new; }
						action _error 	{ @current_packet = ErrorPacket.new; }
						Response 	= "Response: ";
						Success		= Response "Success" >_success crlf;
						Pong 			= Response "Pong" >_success crlf;
						Error 		= Response "Error" >_error crlf;
						Events		= Response "Events " ("On" | "Off") >_success crlf;

						action _follows { @current_packet = FollowsPacket.new; }
						Follows 		= Response "Follows" >_follows crlf;
						EndFollows 	= "--END COMMAND--" crlf;

						# Capture the prompt. Signal any waiters.
						Prompt = "Asterisk Call Manager/";
						prompt := |*
							graph+ 	>{ mark("version"); };
							crlf 		>{ set("version"); @signal.signal	} => { fgoto main; };
							*|;

						# For typical commands with responses with headers
						response_normal := |*
							Attr => { pair; };
							crlf => { packet; fgoto main; };
							*|;
				
						# For immediate or raw commands
						Raw = (any+ >{ mark_array("raw"); } -- lf) lf;

						# For immediate or raw commands
						Imm = (any+ >{ mark_array("raw") } -- crlf) crlf %{ insert("raw") };

						# For raw commands
						response_follows := |*
							Privilege 			=> { pair; };
							ActionID 				=> { pair; };
							Raw 						=> { insert("raw") };
							EndFollows crlf => { packet; fgoto main; };
							*|;
			
						main := |*
							Prompt 	@{ fgoto prompt; 						};
							Success @{ fgoto response_normal; 	};
							Pong 		@{ fgoto response_normal; 	};
							Error 	@{ fgoto response_normal; 	};
							Event 	@{ fgoto response_normal; 	};
							Events 	@{ fgoto response_normal; 	};
							Follows @{ fgoto response_follows; 	};

							# Must also handle immediate responses with raw data
							Imm crlf crlf => { @current_packet = ImmediatePacket.new; packet; };
						*|;
				}%%
	
					class << self
						def extended(base)
							# Rename the Ragel variables. Not strictly necessary if
							# we were to make accessors for them.
							base.instance_eval do
								%%{
									variable p @__ragel_p;
									variable pe @__ragel_pe;
									variable cs @__ragel_cs;
									variable act @__ragel_act;
									variable data @__ragel_data;
									variable tokstart @__ragel_tokstart;
									variable tokend @__ragel_tokend;
									write data nofinal;
								}%%
							end			
						end
					end

					private					
					def ragel_init
						%% write init;
					end
					
					def ragel_exec
						%% write exec;
					end
				end
			end
		end
	end
end
