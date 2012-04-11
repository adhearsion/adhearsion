# encoding: utf-8

module Adhearsion
  class CallController
    module Dial
      #
      # Dial one or more third parties and join one to this call
      #
      # @overload dial(to[String], options = {})
      #   @param [String] to The target URI to dial.
      #     You must specify a properly formatted string that your VoIP platform understands.
      #     eg. sip:foo@bar.com, tel:+14044754840, or SIP/foo/1234
      #   @param [Hash] options see below
      #
      # @overload dial(to[Array], options = {})
      #   @param [Array<String>] to Target URIs to dial.
      #     Each will be called with the same options simultaneously.
      #     The first call answered is joined, the others are hung up.
      #   @param [Hash] options see below
      #
      # @overload dial(to[Hash], options = {})
      #   @param [Hash<String => Hash>] to Target URIs to dial, mapped to their per-target options overrides.
      #     Each will be called with the same options simultaneously.
      #     The first call answered is joined, the others are hung up.
      #     Each calls options are deep-merged with the global options hash.
      #   @param [Hash] options see below
      #
      # @option options [String] :from the caller id to be used when the call is placed. It is advised you properly adhere to the
      #   policy of VoIP termination providers with respect to caller id values.
      #
      # @option options [Numeric] :for this option can be thought of best as a timeout.
      #   i.e. timeout after :for if no one answers the call
      #
      # @example Make a call to the PSTN using my SIP provider for VoIP termination
      #   dial "SIP/19095551001@my.sip.voip.terminator.us"
      #
      # @example Make 3 simulataneous calls to the SIP extensions, try for 15 seconds and use the callerid for this call specified by the variable my_callerid
      #   dial %w{SIP/jay-desk-650 SIP/jay-desk-601 SIP/jay-desk-601-2}, :for => 15.seconds, :from => my_callerid
      #
      # @example Make a call using the IAX provider to the PSTN
      #   dial "IAX2/my.id@voipjet/19095551234", :from => "John Doe <9095551234>"
      #
      # @return [DialStatus] the status of the dial operation
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
        # The collection of calls created during the dial operation
        attr_accessor :calls

        # @private
        def initialize
          @result = nil
        end

        #
        # The result of the dial operation.
        #
        # @return [Symbol] :no_answer, :answer, :timeout, :error
        def result
          @result || :no_answer
        end

        # @private
        def answer!
          @result = :answer
        end

        # @private
        def timeout!
          @result ||= :timeout
        end

        # @private
        def error!
          @result ||= :error
        end
      end

    end
  end
end
