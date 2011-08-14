require 'theatre/guid'
require 'thread'
require 'monitor'

module Theatre

  ##
  # An Invocation is an object which Theatre generates and returns from Theatre#trigger.
  #
  class Invocation

    attr_reader :queued_time, :started_time, :finished_time, :unique_id, :callback, :namespace, :error, :returned_value

    class InvalidStateError < StandardError; end

    ##
    # Create a new Invocation.
    #
    # @param [String] namespace The "/foo/bar/qaz" path to the namespace to which this Invocation belongs.
    # @param [Proc] callback The block which should be executed by an Actor scheduler.
    # @param [Object] payload The message that will be sent to the callback for processing.
    #
    def initialize(namespace, callback, payload=:theatre_no_payload)
      raise ArgumentError, "Callback must be a Proc" unless callback.kind_of? Proc
      @payload       = payload
      @unique_id     = new_guid.freeze
      @callback      = callback
      @current_state = :new
      @state_lock    = Mutex.new

      # Used just to protect access to the @returned_value instance variable
      @returned_value_lock = Monitor.new

      # Used when wait() is called to notify all waiting threads by using a ConditionVariable
      @returned_value_blocker = @returned_value_lock.new_cond#Monitor::ConditionVariable.new @returned_value_lock
    end

    def queued
      with_state_lock do
        raise InvalidStateError unless @current_state == :new
        @current_state = :queued
        @queued_time = Time.now.freeze
      end
      true
    end

    def current_state
      with_state_lock { @current_state }
    end

    def start
      with_state_lock do
        raise InvalidStateError unless @current_state == :queued
        @current_state = :running
      end
      @started_time = Time.now.freeze

      begin
        self.returned_value = if @payload.equal? :theatre_no_payload
          @callback.call
        else
          @callback.call @payload
        end
        with_state_lock { @current_state = :success }
      rescue => e
        @error = e
        with_state_lock { @current_state = :error }
      ensure
        @finished_time = Time.now.freeze
      end
    end

    def execution_duration
      return nil unless @finished_time
      @finished_time - @started_time
    end

    def error?
      current_state.equal? :error
    end

    def success?
      current_state.equal? :success
    end

    ##
    # When this Invocation has been queued, started, and entered either the :success or :error state, this method will
    # finally return. Until then, it blocks the Thread.
    #
    # @return [Object] The result of invoking this Invocation's callback
    #
    def wait
      with_returned_value_lock { return @returned_value if defined? @returned_value }
      @returned_value_blocker.wait
      # Return the returned_value
      with_returned_value_lock { @returned_value }
    end

    protected

    ##
    # Protected setter which does some other housework when the returned value is found (such as notifying wait()ers)
    #
    # @param [returned_value] The value to set this returned value to.
    #
    def returned_value=(returned_value)
      with_returned_value_lock do
        @returned_value = returned_value
        @returned_value_blocker.broadcast
      end
    end

    def with_returned_value_lock(&block)
      @returned_value_lock.synchronize(&block)
    end

    def with_state_lock(&block)
      @state_lock.synchronize(&block)
    end

  end
end
