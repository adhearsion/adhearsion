# encoding: utf-8

module Adhearsion
  class Statistics
    include Celluloid

    exclusive

    def initialize
      @calls_dialed = @calls_offered = @calls_routed = @calls_rejected = 0
      @calls_by_route = Hash.new { |h,k| h[k] = 0 }
      @event_handlers = []
    end

    #
    # Create a point-time dump of process statistics
    #
    # @return [Adhearsion::Statistics::Dump]
    def dump
      Dump.new timestamp: Time.now, call_counts: dump_call_counts, calls_by_route: dump_calls_by_route
    end

    # @private
    def register_call_dialed
      @calls_dialed += 1
    end

    # @private
    def register_call_offered
      @calls_offered += 1
    end

    # @private
    def register_call_routed(data)
      @calls_routed += 1
      @calls_by_route[data[:route].name] += 1
    end

    # @private
    def register_call_rejected
      @calls_rejected += 1
    end

    # @private
    def setup_event_handlers
      stats = current_actor

      Events.punchblock(Punchblock::Event::Offer) do
        begin
          stats.register_call_offered
        rescue Celluloid::DeadActorError
        end
        throw :pass
      end

      Events.call_dialed do
        begin
          stats.register_call_dialed
        rescue Celluloid::DeadActorError
        end
        throw :pass
      end

      Events.call_rejected do
        begin
          stats.register_call_rejected
        rescue Celluloid::DeadActorError
        end
        throw :pass
      end

      Events.call_routed do |data|
        begin
          stats.register_call_routed data
        rescue Celluloid::DeadActorError
        end
        throw :pass
      end
    end

    private

    def dump_call_counts
      {dialed: @calls_dialed, offered: @calls_offered, routed: @calls_routed, rejected: @calls_rejected, active: Adhearsion.active_calls.count}
    end

    def dump_calls_by_route
      @calls_by_route.tap do |index|
        Adhearsion.router.routes.each do |route|
          index[route.name]
        end
      end
    end

    #
    # A point-time dump of process statistics
    class Dump
      include Comparable

      #
      # @attribute
      # @return [Time] the time at which this dump was generated
      attr_reader :timestamp

      #
      # @attribute
      # @return [Hash] hash of call counts during the lifetime of the process.
      attr_reader :call_counts

      #
      # @attribute
      # @return [Hash] hash of call counts during the lifetime of the process, indexed by the route they matched.
      attr_reader :calls_by_route

      def initialize(opts = {})
        @timestamp = opts[:timestamp]
        @call_counts = opts[:call_counts]
        @calls_by_route = opts[:calls_by_route]
      end

      def <=>(other)
        timestamp <=> other.timestamp
      end
    end
  end
end
