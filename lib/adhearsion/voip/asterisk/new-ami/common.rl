%%{ #%

#########
## This file is written with the Ragel programming language and parses the Asterisk Manager Interface protocol. It depends
## upon Ragel actions which should be implemented in the Ragel which which includes this file.
##
## Note:This file is language agnostic. From this AMI parsers in many other languages can be generated.
#########

machine ami_protocol_parser_common;

carriage_return = "\r";           # A carriage return. Used before (almost) every newline character.
line_feed = "\n";                 # Newline. Used (with carriage_return) to separate key/value pairs and stanzas.
crlf = carriage_return line_feed; # Means "carriage return and line feed". Used to separate key/value pairs and stanzas
white = [\t ];                    # Single whitespace character, either a tab or a space
colon = ":" [ ]**;                # Separates keys from values. "A colon followed by any number of spaces"
stanza_break    = crlf crlf;      # The seperator between two stanzas.
rest_of_line    = (any* -- crlf); # Match all characters until the next line seperator.

Prompt = "Asterisk Call Manager/" digit+ >open_version "." digit+ %close_version crlf;

Key = (alnum | print -- line_feed)+;
KeyValuePair = Key >before_key %after_key colon rest_of_line >before_value %after_value crlf;

FollowsDelimiter = crlf "--END COMMAND--";

Response = "Response"i colon;
Success	 = Response "Success"i %init_success crlf @{ fgoto success; };
Pong     = Response "Pong"i %init_success crlf @{ fgoto success; };
Error    = Response "Error"i crlf "Message"i colon rest_of_line >error_reason_start crlf crlf @error_reason_end;
Follows  = Response "Follows" crlf @init_response_follows;
Event    = "Event"i colon %begin_capturing_event_name rest_of_line %init_event crlf;

# For "Response: Follows"
FollowsBody = (any* -- FollowsDelimiter) >start_capturing_follows_text FollowsDelimiter @end_capturing_follows_text crlf;

# Events = Response "Events " ("On" | "Off") crlf;

# Can't use a Ragel Scanner because Scanners don't handle errors to my knowledge.
main := |*
  Prompt;
  Success | Pong | Event => message_received;
  Error;
  Follows crlf;
  any => { fhold; fgoto error_recovery; };
*|;

# Skip over everything until we get back to crlf{2}
error_recovery := (any**) >start_ignoring_syntax_error stanza_break @end_ignoring_syntax_error; 

success := KeyValuePair* crlf @message_received @{ fgoto main; };

# For the "Response: Follows" protocol abnormality. What happens if there's a protocol irregularity in this state???
response_follows := |*
    KeyValuePair+;
    FollowsBody;
    crlf @{ message_received; fgoto main; };
*|;
 
}%%