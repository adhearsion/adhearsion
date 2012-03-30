# encoding: utf-8

module Adhearsion
  class CallController
    module Dial
      #
      # Dial a third party and join to this call
      #
      # @param [String|Array<String>|Hash] number represents the extension or "number" that asterisk should dial.
      # Be careful to not just specify a number like 5001, 9095551001
      # You must specify a properly formatted string as Asterisk would expect to use in order to understand
      # whether the call should be dialed using SIP, IAX, or some other means.
      # You can also specify an array of destinations: each will be called with the same options simultaneously.
      # The first call answered is joined, the others are hung up.
      # A hash argument has the dial target as each key, and an hash of options as the value, in the form:
      # dial({'SIP/100' => {:timeout => 3000}, 'SIP/200' => {:timeout => 4000} })
      # The option hash for each target is merged into the global options, overriding them for the single dial.
      # Destinations are dialed simultaneously as with an array.
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
        targets = to.respond_to?(:has_key?) ? to : Array(to)

        status = DialStatus.new

        latch ||= CountDownLatch.new targets.size

        call.on_end { |_| latch.countdown! until latch.count == 0 }

        _for = options.delete :for
        options[:timeout] ||= _for if _for

        options[:from] ||= call.from

        calls = targets.map do |target, specific_options|
          new_call = OutboundCall.new

          new_call.on_answer do |event|
            calls.each do |call_to_hangup, _|
              begin
                next if call_to_hangup.id == new_call.id
                logger.debug "#dial hanging up call #{call_to_hangup.id} because this call has been answered by another channel"
                call_to_hangup.hangup
              rescue Celluloid::DeadActorError
                # This actor may previously have been shut down due to the call ending
              end
            end

            new_call.register_event_handler Punchblock::Event::Unjoined, :call_id => call.id do |unjoined|
              new_call["dial_countdown_#{call.id}"] = true
              latch.countdown!
              throw :pass
            end

            logger.debug "#dial joining call #{new_call.id} to #{call.id}"
            new_call.join call
            status.answer!
          end

          new_call.on_end do |event|
            latch.countdown! unless new_call["dial_countdown_#{call.id}"]

            case event.reason
            when :error
              status.error!
            end
          end

          [new_call, target, specific_options]
        end

        calls.map! do |call, target, specific_options|
          local_options = options.dup.deep_merge specific_options if specific_options
          call.dial target, (local_options || options)
          call
        end

        status.calls = calls

        no_timeout = latch.wait options[:timeout]
        status.timeout! unless no_timeout

        logger.debug "#dial finished. Hanging up #{calls.size} outbound calls: #{calls.map(&:id).join ", "}."
        calls.each do |outbound_call|
          begin
            outbound_call.hangup
          rescue Celluloid::DeadActorError
            # This actor may previously have been shut down due to the call ending
          end
        end

        status
      end

      class DialStatus
        attr_accessor :calls

        def initialize
          @result = nil
        end

        def result
          @result || :no_answer
        end

        def answer!
          @result = :answer
        end

        def timeout!
          @result ||= :timeout
        end

        def error!
          @result ||= :error
        end
      end

    end#module Dial
  end
end
