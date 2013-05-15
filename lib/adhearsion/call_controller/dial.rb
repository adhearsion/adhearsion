# encoding: utf-8

require 'countdownlatch'

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
      #   policy of VoIP termination providers with respect to caller id values. Defaults to the caller ID of the dialing call, so for normal bridging scenarios, you do not need to set this.
      #
      # @option options [Numeric] :for this option can be thought of best as a timeout.
      #   i.e. timeout after :for if no one answers the call
      #
      # @option options [CallController] :confirm the controller to execute on answered outbound calls to give an opportunity to screen the call. The calls will be joined if the outbound call is still active after this controller completes.
      # @option options [Hash] :confirm_metadata Metadata to set on the confirmation controller before executing it. This is shared between all calls if dialing multiple endpoints; if you care about it being mutated, you should provide an immutable value (using eg https://github.com/harukizaemon/hamster).
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
        dial = Dial.new to, options, latch, call
        dial.run
        dial.await_completion
        dial.cleanup_calls
        dial.status
      end

      class Dial
        attr_accessor :status

        def initialize(to, options, latch, call)
          raise Call::Hangup unless call.alive? && call.active?
          @options, @latch, @call = options, latch, call
          @targets = to.respond_to?(:has_key?) ? to : Array(to)
          set_defaults
        end

        def set_defaults
          @status = DialStatus.new

          @latch ||= CountDownLatch.new @targets.size

          @options[:from] ||= @call.from

          _for = @options.delete :for
          @options[:timeout] ||= _for if _for

          @confirmation_controller = @options.delete :confirm
          @confirmation_metadata = @options.delete :confirm_metadata
        end

        def run
          track_originating_call
          prep_calls
          place_calls
        end

        def track_originating_call
          @call.on_end { |_| @latch.countdown! until @latch.count == 0 }
        end

        def prep_calls
          @calls = @targets.map do |target, specific_options|
            new_call = OutboundCall.new

            new_call.on_end do |event|
              @latch.countdown! unless new_call["dial_countdown_#{@call.id}"]
              status.error! if event.reason == :error
            end

            new_call.on_answer do |event|
              @calls.each do |call_to_hangup, _|
                begin
                  next if call_to_hangup.id == new_call.id
                  logger.debug "#dial hanging up call #{call_to_hangup.id} because this call has been answered by another channel"
                  call_to_hangup.hangup
                rescue Celluloid::DeadActorError
                  # This actor may previously have been shut down due to the call ending
                end
              end

              new_call.on_unjoined @call do |unjoined|
                new_call["dial_countdown_#{@call.id}"] = true
                @latch.countdown!
              end

              if @confirmation_controller
                status.unconfirmed!
                new_call.execute_controller @confirmation_controller.new(new_call, @confirmation_metadata), lambda { |call| call.signal :confirmed }
                new_call.wait :confirmed
              end

              if new_call.alive? && new_call.active?
                logger.debug "#dial joining call #{new_call.id} to #{@call.id}"
                @call.answer
                new_call.join @call
                status.answer!
              end
            end

            [new_call, target, specific_options]
          end

          status.calls = @calls
        end

        def place_calls
          @calls.map! do |call, target, specific_options|
            local_options = @options.dup.deep_merge specific_options if specific_options
            call.dial target, (local_options || @options)
            call
          end
        end

        def await_completion
          @latch.wait(@options[:timeout]) || status.timeout!
          @latch.wait if status.result == :answer
        end

        def cleanup_calls
          logger.debug "#dial finished. Hanging up #{@calls.size} outbound calls: #{@calls.map(&:id).join ", "}."
          @calls.each do |outbound_call|
            begin
              outbound_call.hangup
            rescue Celluloid::DeadActorError
              # This actor may previously have been shut down due to the call ending
            end
          end
        end
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

        # @private
        def unconfirmed!
          @result ||= :unconfirmed
        end
      end

    end
  end
end
