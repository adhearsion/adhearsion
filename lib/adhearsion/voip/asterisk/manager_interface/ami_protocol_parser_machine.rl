%%{ #%

#########
## This file is written with the Ragel programming language and parses the Asterisk Manager Interface protocol. It depends
## upon Ragel actions which should be implemented in the Ragel which which includes this file.
##
## Note:This file is language agnostic. From this AMI parsers in many other languages can be generated.
#########

machine ami_protocol_parser_common;

cr = "\r";           # A carriage return. Used before (almost) every newline character.
lf = "\n";                 # Newline. Used (with cr) to separate key/value pairs and stanzas.
crlf = cr lf; # Means "carriage return and line feed". Used to separate key/value pairs and stanzas
loose_newline = cr? lf;

white = [\t ];                    # Single whitespace character, either a tab or a space
colon = ":" [ ]**;                # Separates keys from values. "A colon followed by any number of spaces"
stanza_break    = crlf crlf;      # The seperator between two stanzas.
rest_of_line    = (any* -- crlf); # Match all characters until the next line seperator.

Prompt = "Asterisk Call Manager/" digit+ >version_starts "." digit+ %version_stops crlf;

Key = ((alnum | print) -- (cr | lf))+;
KeyValuePair = Key >key_starts %key_stops colon rest_of_line >value_starts %value_stops crlf;

FollowsDelimiter = crlf "--END COMMAND--";

Response = "Response"i colon;
Success	 = Response "Success"i %init_success crlf @{ fgoto success; };
Pong     = Response "Pong"i %init_success crlf @{ fgoto success; };
Error    = Response "Error"i crlf "Message"i colon rest_of_line >error_reason_starts crlf crlf @error_reason_stops;
Follows  = Response "Follows" crlf @init_response_follows @{ fgoto response_follows; };
Event    = "Event"i colon %event_name_starts rest_of_line %event_name_stops crlf;

# For "Response: Follows"
FollowsBody = (any* -- FollowsDelimiter) >follows_text_starts FollowsDelimiter @follows_text_stops crlf;

# An "immediate" response is one which is not in the key/value pair format.
immediate_response := (any+ -- loose_newline) >immediate_response_starts (crlf) >immediate_response_stops @{fgoto protocol;};

# When a new socket is established, Asterisk will send the version of the protocol per the Prompt machine. Because it's
# tedious for unit tests to always send this, we'll put some intelligence into this parser to support going straight into
# the protocol-parsing machine. It's also conceivable that a variant of AMI would not send this initial information.
main := |*
  Prompt => { fgoto protocol; };
  any => {
    # If this scanner's look-ahead capability didn't match the prompt, let's ignore the need for a prompt
    fhold;
    fgoto protocol;
  };
*|;

protocol := |*
  Prompt;
  Success | Pong | Event => message_received;
  Error;
  Follows crlf;
  crlf => { fgoto protocol; }; # If we get a crlf out of place, let's just ignore it.
  any  => {
    fhold;
    fgoto immediate_response;
  };
*|;

# Skip over everything until we get back to crlf{2}
error_recovery := (any**) >syntax_error_starts stanza_break @syntax_error_stops @{fgoto protocol;}; 

success := KeyValuePair* crlf @message_received @{fgoto protocol;};

# For the "Response: Follows" protocol abnormality. What happens if there's a protocol irregularity in this state???
response_follows := |*
    KeyValuePair+;
    FollowsBody;
    crlf @{ message_received; fgoto protocol; };
*|;
 
}%%