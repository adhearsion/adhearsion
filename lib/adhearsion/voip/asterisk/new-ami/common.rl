%%{ #%

#########
## This file is written with the Ragel programming language and parses the Asterisk Manager Interface protocol. It depends
## upon Ragel actions which should be implemented in the Ragel which which includes this file.
##
## Note:This file is language agnostic. From this AMI parsers in many other languages can be generated.
#########

machine ami_protocol_parser_common;

carriage_return = "\r";
line_feed       = "\n";
white           = [\t ];
crlf            = carriage_return line_feed;
stanza_break    = crlf crlf;
rest_of_line    = (any* -- crlf);

Prompt = "Asterisk Call Manager/" digit+ >open_version "." digit+ %close_version crlf;
KeyValuePair = (alnum | print)+ >before_key %after_key (":" white**) rest_of_line >before_value %after_value crlf;

ActionID = "ActionID: "i rest_of_line >before_action_id %after_action_id crlf;

FollowsDelimiter = crlf "--END COMMAND--";

Response = "Response: "i;
Success	 = Response "Success"i %init_success crlf %{ fgoto success; };
Pong     = Response "Pong"i %init_success crlf;
Error    = Response "Error"i crlf "Message: "i @error_reason_start rest_of_line crlf crlf @error_reason_end;
Follows  = Response "Follows" crlf @init_response_follows;
Event    = "Event: "i %begin_capturing_event_name rest_of_line %init_event crlf;

# For "Response: Follows"
FollowsBody = (any* -- FollowsDelimiter) >start_capturing_follows_text FollowsDelimiter >end_capturing_follows_text crlf @{ fgoto main; };

# Events = Response "Events " ("On" | "Off") crlf;

# Can't use a Ragel Scanner because Scanners don't handle errors to my knowledge.
main := Prompt? ((((Success | Pong | Event) @message_received) | Error | (Follows crlf))) $err(start_ignoring_syntax_error);

success := (ActionID | KeyValuePair)+ crlf @message_received;

# Skip over everything until we get back to crlf{2}
error_recovery := (any* -- stanza_break) stanza_break @end_ignoring_syntax_error; 

# For the "Response: Follows" protocol abnormality. What happens if there's a protocol irregularity in this state???
response_follows := |*
    ActionID;
    KeyValuePair;
    FollowsBody;
    crlf;
*|;
 

}%%