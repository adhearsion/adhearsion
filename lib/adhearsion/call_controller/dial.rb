module Adhearsion
  class CallController
    module Dial
      #
      # Dial a third party and join to this call
      #
      # @param [String|Array<String>] number represents the extension or "number" that asterisk should dial.
      # Be careful to not just specify a number like 5001, 9095551001
      # You must specify a properly formatted string as Asterisk would expect to use in order to understand
      # whether the call should be dialed using SIP, IAX, or some other means.
      # You can also specify an array of destinations: each will be called with the same options simultaneously.
      # The first call answered is joined, the others are hung up.
      #
      # @param [Hash] options
      #
      # +:from+ - the caller id to be used when the call is placed. It is advised you properly adhere to the
      # policy of VoIP termination providers with respect to caller id values.
      #
      # +:for+ - this option can be thought of best as a timeout.  i.e. timeout after :for if no one answers the call
      # For example, dial(%w{SIP/jay-desk-650 SIP/jay-desk-601 SIP/jay-desk-601-2}, :for => 15.seconds, :from => callerid)
      # this call will timeout after 15 seconds if 1 of the 3 extensions being dialed do not pick prior to the 15 second time limit
      #
      # @example Make a call to the PSTN using my SIP provider for VoIP termination
      #   dial "SIP/19095551001@my.sip.voip.terminator.us"
      #
      # @example Make 3 Simulataneous calls to the SIP extensions, try for 15 seconds and use the callerid
      # for this call specified by the variable my_callerid
      #   dial %w{SIP/jay-desk-650 SIP/jay-desk-601 SIP/jay-desk-601-2}, :for => 15.seconds, :from => my_callerid
      #
      # @example Make a call using the IAX provider to the PSTN
      #   dial "IAX2/my.id@voipjet/19095551234", :from => "John Doe <9095551234>"
      #
      def dial(to, options = {}, latch = nil)
        targets = Array(to)

        latch ||= CountDownLatch.new targets.size

        call.on_end { |_| latch.countdown! until latch.count == 0 }

        _for = options.delete :for
        options[:timeout] ||= _for if _for

        calls = targets.map do |target|
          new_call = OutboundCall.new options

          new_call.on_answer do |event|
            calls.each do |call_to_hangup, target|
              logger.debug "Hanging up call #{call_to_hangup} because it was not the first to answer a #dial"
              begin
                call_to_hangup.hangup unless call_to_hangup.id == new_call.id
              rescue Celluloid::DeadActorError
                # This actor may previously have been shut down due to the call ending
              end
            end

            new_call.register_event_handler Punchblock::Event::Unjoined, :other_call_id => call.id do |event|
              new_call[:"dial_countdown_#{call.id}"] = true
              latch.countdown!
              throw :pass
            end

            logger.debug "Joining call #{new_call} to #{call} due to a #dial"
            new_call.join call
          end

          new_call.on_end do |event|
            latch.countdown! unless new_call[:"dial_countdown_#{call.id}"]
          end

          [new_call, target]
        end

        calls.map! do |call, target|
          call.dial target, options
          call
        end

        timeout = latch.wait options[:timeout]

        logger.debug "#dial finished. Hanging up outbound calls #{calls.inspect}."
        calls.each do |outbound_call, target|
          logger.debug "Hanging up #{outbound_call} because the #dial that created it is complete."
          begin
            outbound_call.hangup
          rescue Celluloid::DeadActorError
            # This actor may previously have been shut down due to the call ending
          end
        end

        return timeout unless timeout

        calls.size == 1 ? calls.first : calls
      end

    end#module Dial
  end
end
