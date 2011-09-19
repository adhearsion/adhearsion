module Adhearsion
  module Punchblock
    module Commands
      module Dial
        #
        # Dial a third party and join to this call
        #
        # @param [String] number represents the extension or "number" that asterisk should dial.
        # Be careful to not just specify a number like 5001, 9095551001
        # You must specify a properly formatted string as Asterisk would expect to use in order to understand
        # whether the call should be dialed using SIP, IAX, or some other means.
        #
        # @param [Hash] options
        #
        # +:caller_id+ - the caller id number to be used when the call is placed.  It is advised you properly adhere to the
        # policy of VoIP termination providers with respect to caller id values.
        #
        # +:name+ - this is the name which should be passed with the caller ID information
        # if :name=>"John Doe" and :caller_id => "444-333-1000" then the compelete CID and name would be "John Doe" <4443331000>
        # support for caller id information varies from country to country and from one VoIP termination provider to another.
        #
        # +:for+ - this option can be thought of best as a timeout.  i.e. timeout after :for if no one answers the call
        # For example, dial("SIP/jay-desk-650&SIP/jay-desk-601&SIP/jay-desk-601-2", :for => 15.seconds, :caller_id => callerid)
        # this call will timeout after 15 seconds if 1 of the 3 extensions being dialed do not pick prior to the 15 second time limit
        #
        # +:options+ - This is a string of options like "Tr" which are supported by the asterisk DIAL application.
        # for a complete list of these options and their usage please check the link below.
        #
        # +:confirm+ - ?
        #
        # @example Make a call to the PSTN using my SIP provider for VoIP termination
        #   dial "SIP/19095551001@my.sip.voip.terminator.us"
        #
        # @example Make 3 Simulataneous calls to the SIP extensions, try for 15 seconds and use the callerid
        # for this call specified by the variable my_callerid
        #   dial ["SIP/jay-desk-650", "SIP/jay-desk-601", "SIP/jay-desk-601-2"], :for => 15.seconds, :caller_id => my_callerid
        #
        # @example Make a call using the IAX provider to the PSTN
        #   dial "IAX2/my.id@voipjet/19095551234", :name => "John Doe", :caller_id => "9095551234"
        #
        def dial(to, options = {})
          OutboundCall.new(options).tap do |new_call|
            latch = CountDownLatch.new 1
            new_call.on_answer  = lambda { |event| new_call.join call.id }
            new_call.on_end     = lambda { |event| latch.countdown! }
            new_call.dial to, options
            latch.wait
          end
        end
      end
    end
  end
end
