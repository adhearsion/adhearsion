# encoding: utf-8

module Adhearsion
  class Statistics
    include Celluloid

    exclusive

    def initialize
      @calls_dialed = @calls_offered = @calls_routed = @calls_rejected = 0

      Events.punchblock(Punchblock::Event::Offer) { register_call_offered }
      Events.call_dialed { register_call_dialed }
      Events.call_rejected { register_call_rejected }
      Events.call_routed { register_call_routed }
    end

    #
    # Create a point-time dump of process statistics
    #
    # @return [Adhearsion::Statistics::Dump]
    def dump
      Dump.new timestamp: Time.now, call_counts: dump_call_counts
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
    def register_call_routed
      @calls_routed += 1
    end

    # @private
    def register_call_rejected
      @calls_rejected += 1
    end

    private

    def dump_call_counts
      {dialed: @calls_dialed, offered: @calls_offered, routed: @calls_routed, rejected: @calls_rejected, active: Adhearsion.active_calls.count}
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

      def initialize(opts = {})
        @timestamp = opts[:timestamp]
        @call_counts = opts[:call_counts]
      end

      def <=>(other)
        timestamp <=> other.timestamp
      end
    end
  end
end
