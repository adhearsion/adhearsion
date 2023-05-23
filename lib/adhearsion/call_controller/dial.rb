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
      # @option options [CallController] :confirm Confirmation controller to execute. Confirmation will be attempted on all answered calls, and calls will be allowed to progress through confirmation in parallel. The first to complete confirmation will be joined to the A-leg, with the others being hung up.
      # @option options [Hash] :confirm_metadata Metadata to set on the confirmation controller before executing it. This is shared between all calls if dialing multiple endpoints; if you care about it being mutated, you should provide an immutable value (using eg https://github.com/harukizaemon/hamster).
      #
      # @option options [CallController] :apology controller to execute on calls which lose the race to complete confirmation before they are hung up
      #
      # @option options [CallController] :cleanup The controller to execute on each call being cleaned up. This can be used, for instance, to notify that the call is being terminated. Calls are terminated right after this controller completes execution. If this is not specified, calls are silently terminated during cleanup.
      # @option options [Hash] :cleanup_metadata Metadata to set on the cleanup controller before executing it. Defaults to :confirm_metadata if not specified.
      #
      # @option options [Hash] :join_options Options to specify the kind of join operation to perform. See `Call#join` for details.
      # @option options [Call, String, Hash] :join_target the target to join to. May be a Call object, a call ID (String, Hash) or a mixer name (Hash). See `Call#join` for details.
      #
      # @option options [#call] :pre_join A callback to be executed immediately prior to answering and joining a successful call. Is called with a single parameter which is the outbound call being joined.
      #
      # @option options [Array, #call] :ringback A collection of audio (see #play for acceptable values) to render as a replacement for ringback. If a callback is passed, it will be used to start ringback, and must return something that responds to #stop! to stop it.
      #
      # @yield [Adhearsion::CallController::Dial::Dial] Provides the newly initialized Dial object to the given block, particularly useful in order to obtain a reference to it for later use.
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
      def dial(to, options = {})
        dial = Dial.new to, options, call
        yield dial if block_given?
        dial.run(self)
        dial.await_completion
        dial.terminate_ringback
        dial.cleanup_calls
        dial.status
      ensure
        catching_standard_errors { dial.delete_logger if dial }
      end

      class Dial
        attr_accessor :status

        def initialize(to, options, call)
          raise Call::Hangup unless call.active?
          @id = SecureRandom.uuid
          @options, @call = options, call
          @targets = to.respond_to?(:has_key?) ? to : Array(to)
          @call_targets = {}
          set_defaults
        end

        def inspect
          "#<#{self.class}[#{@id}] to=#{@to.inspect} options=#{@options.inspect}>"
        end

        # Prep outbound calls, link call lifecycles and place outbound calls
        def run(controller)
          track_originating_call
          start_ringback controller
          prep_calls
          place_calls
        end

        #
        # Links the lifecycle of the originating call to the Dial operation such that the Dial is unblocked when the originating call ends
        def track_originating_call
          @call.on_end do |_|
            logger.debug "Root call ended, unblocking connected calls"
            @waiters.each do |latch|
              latch.countdown! until latch.count == 0
            end
          end
        end

        #
        # Starts ringback on the specified controller
        #
        # @param [Adhearsion::CallController] controller the controller on which to play ringback
        def start_ringback(controller)
          return unless @ringback
          @ringback_component = if @ringback.respond_to?(:call)
            @ringback.call
          else
            controller.play! @ringback, repeat_times: 0
          end
        end

        #
        # Terminates any ringback that might be playing
        #
        def terminate_ringback
          return unless @ringback_component
          return unless @ringback_component.executing?
          @ringback_component.stop!
        end

        #
        # Prepares a set of OutboundCall actors to be dialed and links their lifecycles to the Dial operation
        #
        # @yield Each call to the passed block for further setup operations
        def prep_calls
          @calls = Set.new
          @targets.map do |target, specific_options|
            new_call = OutboundCall.new

            join_status = JoinStatus.new
            status.joins[new_call] = join_status

            new_call.on_end do |event|
              @latch.countdown! unless new_call["dial_countdown_#{@id}"]
              if event.reason == :error
                status.error!
                join_status.errored!
              end
            end

            new_call.on_answer do |event|
              new_call.on_joined @call do |joined|
                join_status.started joined.timestamp.to_time
              end

              new_call.on_unjoined @call do |unjoined|
                join_status.ended unjoined.timestamp.to_time
                unless @splitting
                  new_call["dial_countdown_#{@id}"] = true
                  @latch.countdown!
                end
              end

              if @confirmation_controller
                status.unconfirmed!
                join_status.unconfirmed!
                condition = Celluloid::Condition.new
                new_call.execute_controller @confirmation_controller.new(new_call, @confirmation_metadata), lambda { |call| condition.broadcast }
                condition.wait
              end

              if new_call.active? && status.result != :answer
                logger.info "#dial joining call #{new_call.id} to #{@call.id}"
                pre_join_tasks new_call
                @call.answer
                new_call.join(@join_target, **@join_options)
                unless @join_target == @call
                  @call.join(@join_target, **@join_options)
                end
                status.answer!
              elsif status.result == :answer
                join_status.lost_confirmation!
              end
            end

            @call_targets[new_call] = [target, specific_options]

            yield new_call if block_given?

            @calls << new_call
          end

          status.calls = @calls
        end

        #
        # Dials the set of outbound calls
        def place_calls
          @calls.each do |call|
            target, specific_options = @call_targets[call]
            local_options = @options.dup.deep_merge specific_options if specific_options
            call.dial(target, **(local_options || @options))
          end
        end

        # Split calls party to the dial
        # Marks the end time in the status of each join, but does not unblock #dial until one of the calls ends
        # Optionally executes call controllers on calls once split, where 'current_dial' is available in controller metadata in order to perform further operations on the Dial, including rejoining and termination.
        # @param [Hash] targets Target call controllers to execute on call legs once split
        # @option options [Adhearsion::CallController] :main The call controller class to execute on the 'main' call leg (the one who initiated the #dial)
        # @option options [Proc] :main_callback A block to call when the :main controller completes
        # @option options [Adhearsion::CallController] :others The call controller class to execute on the 'other' call legs (the ones created as a result of the #dial)
        # @option options [Proc] :others_callback A block to call when the :others controller completes on an individual call
        def split(targets = {})
          @splitting = true
          calls_to_split = @calls.map do |call|
            ignoring_ended_calls do
              [call.id, call] if call.active?
            end
          end.compact
          logger.info "Splitting off peer calls #{calls_to_split.map(&:first).join ", "}"
          calls_to_split.each do |id, call|
            ignoring_ended_calls do
              logger.debug "Unjoining peer #{call.id} from #{join_target}"
              ignoring_missing_joins { call.unjoin join_target }
              if split_controller = targets[:others]
                logger.info "Executing controller #{split_controller} on split call #{call.id}"
                call.execute_controller split_controller.new(call, 'current_dial' => self), targets[:others_callback]
              end
            end
          end
          ignoring_ended_calls do
            if join_target != @call
              logger.debug "Unjoining main call #{@call.id} from #{join_target}"
              @call.unjoin(join_target)
            end
            if split_controller = targets[:main]
              logger.info "Executing controller #{split_controller} on main call"
              @call.execute_controller split_controller.new(@call, 'current_dial' => self), targets[:main_callback]
            end
          end
        end

        # Rejoin parties that were previously split
        # @param [Call, String, Hash] target The target to join calls to. See Call#join for details.
        # @param [Hash] join_options Options to specify the kind of join operation to perform. See `Call#join` for details.
        def rejoin(target = nil, join_options = nil)
          target ||= join_target
          join_options ||= @join_options
          logger.info "Rejoining to #{target}"
          ignoring_ended_calls do
            unless target == @call
              @join_target = target
              @call.join(target, **join_options)
            end
          end
          @calls.each do |call|
            ignoring_ended_calls { call.join target, **join_options }
          end
        end

        # Merge another Dial into this one, joining all calls to a mixer
        # @param [Dial] other the other dial operation to merge calls from
        def merge(other)
          logger.info "Merging with #{other.inspect}"

          split
          other.split

          rejoin({mixer_name: @id}, {})
          other.rejoin({mixer_name: @id}, {})

          calls_to_merge = other.status.calls + [other.root_call]
          @calls.merge calls_to_merge

          latch = CountDownLatch.new calls_to_merge.size
          calls_to_merge.each do |call|
            call.on_end { |event| latch.countdown! }
          end
          @waiters << latch
        end

        #
        # Block until the dial operation is completed by an appropriate quorum of the involved calls ending
        def await_completion
          @latch.wait(@options[:timeout]) || status.timeout!
          return unless status.result == :answer
          logger.debug "Main calls were completed, waiting for any added calls: #{@waiters.inspect}"
          @waiters.each(&:wait)
          logger.debug "All calls were completed, unblocking."
        end

        #
        # Do not hangup outbound calls when the Dial operation finishes. This allows outbound calls to continue with other processing once they are unjoined.
        def skip_cleanup
          @skip_cleanup = true
        end

        #
        # Hangup any remaining calls
        def cleanup_calls
          calls_to_hangup = @calls.map do |call|
            ignoring_ended_calls do
              [call.id, call] if call.active?
            end
          end.compact
          if calls_to_hangup.size.zero?
            logger.info "#dial finished with no remaining outbound calls"
            return
          end
          if @skip_cleanup
            logger.info "#dial finished. Leaving #{calls_to_hangup.size} outbound calls going which are still active: #{calls_to_hangup.map(&:first).join ", "}."
          else
            logger.info "#dial finished. Hanging up #{calls_to_hangup.size} outbound calls which are still active: #{calls_to_hangup.map(&:first).join ", "}."
            calls_to_hangup.each do |id, outbound_call|
              ignoring_ended_calls do
                if @cleanup_controller
                  logger.info "#dial running #{@cleanup_controller.class.name} on #{outbound_call.id}"
                  outbound_call.execute_controller @cleanup_controller.new(outbound_call, @cleanup_metadata), ->(call) { call.hangup }
                else
                  logger.info "#dial hanging up #{outbound_call.id}"
                  outbound_call.hangup
                end
              end
            end
          end
        end

        def delete_logger
          ::Logging::Repository.instance.delete logger_id
        end

        protected

        def root_call
          @call
        end

        private

        # @private
        def logger_id
          "#{self.class}: #{@id}"
        end

        def join_target
          @join_target || @call
        end

        def set_defaults
          @status = DialStatus.new

          @latch = CountDownLatch.new @targets.size
          @waiters = [@latch]

          @options[:from] ||= @call.from

          _for = @options.delete :for
          @options[:timeout] ||= _for if _for

          @confirmation_controller = @options.delete :confirm
          @confirmation_metadata = @options.delete :confirm_metadata

          @apology_controller = @options.delete :apology

          @pre_join = @options.delete :pre_join
          @ringback = @options.delete :ringback

          @join_options = @options.delete(:join_options) || {}
          @join_target = @options.delete(:join_target) || @call

          @cleanup_controller = @options.delete :cleanup
          @cleanup_metadata = @options.delete :cleanup_metadata || @confirmation_metadata
          @skip_cleanup = false
        end

        def pre_join_tasks(call)
          @pre_join.call(call) if @pre_join
          terminate_ringback
          on_all_except call do |target_call|
            if @apology_controller
              logger.info "#dial executing apology controller #{@apology_controller} on call #{target_call.id} because this call has been confirmed by another channel"
              target_call.async.execute_controller @apology_controller.new(target_call, @confirmation_metadata), ->(call) { call.hangup }
            else
              logger.info "#dial hanging up call #{target_call.id} because this call has been confirmed by another channel"
              target_call.hangup
            end
          end
        end

        def on_all_except(call)
          @calls.each do |target_call|
            ignoring_ended_calls do
              next if target_call.id == call.id
              yield target_call
            end
          end
        end

        def ignoring_missing_joins
          yield
        rescue Adhearsion::ProtocolError => e
          raise unless e.name == :service_unavailable
        end

        def ignoring_ended_calls
          yield
        rescue Celluloid::DeadActorError, Adhearsion::Call::Hangup, Adhearsion::Call::ExpiredError
          # This actor may previously have been shut down due to the call ending
        end
      end

      class DialStatus
        # The collection of calls created during the dial operation
        attr_accessor :calls

        # A collection of status objects indexed by call. Provides status on the joins such as duration
        attr_accessor :joins

        # @private
        def initialize
          @result = nil
          @joins = {}
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

      class JoinStatus
        # The time at which the calls were joined
        attr_accessor :start_time

        # Time at which the join was broken
        attr_accessor :end_time

        def initialize
          @result = :no_answer
        end

        # The result of the attempt to join calls
        # Can be:
        # * :joined - The calls were sucessfully joined
        # * :no_answer - The attempt to dial the third-party was cancelled before they answered
        # * :unconfirmed - The callee did not complete confirmation
        # * :lost_confirmation - The callee completed confirmation, but was beaten by another
        # * :error - The call ended with some error
        attr_reader :result

        # The duration for which the calls were joined. Does not include time spent in confirmation controllers or after being separated.
        def duration
          if start_time && end_time
            end_time.to_i - start_time.to_i
          else
            0.0
          end
        end

        def errored!
          @result = :error
        end

        def unconfirmed!
          @result = :unconfirmed
        end

        def lost_confirmation!
          @result = :lost_confirmation
        end

        def started(time)
          @start_time = time
          @result = :joined
        end

        def ended(time)
          @end_time = time
        end
      end

    end
  end
end
